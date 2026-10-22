# 07 — External API / SDK Integration Specifications

**All integrations must be abstracted** so the mobile app and backend do not hard-code provider-specific types into domain modules. External data is untrusted; validate schema, tenant boundaries, cost, language support, permissions and provider status. Secrets kept only in Google Secret Manager / CI secret store.

## Integration dependency matrix
| Service | Purpose | Production SDK/API | Auth/config | Failure fallback | Priority |
|---|---|---|---|---|---|
| Firebase Auth | Google, Apple, phone identity | FlutterFire Auth & identity providers | Firebase app config; Apple capabilities; OAuth | phone/email optional; clear error | P0 |
| Firebase App Check | attest app/client | Play Integrity, Apple DeviceCheck/App Attest where available | provider config + enforce server | debug token only emulator/dev | P0 |
| Firebase Realtime DB | financial live read models | FlutterFire RTDB + Admin SDK | rules/indexes/region | local read cache, offline outbox | P0 |
| Cloud Functions v2 | write APIs/tasks/webhooks | Firebase SDK TypeScript | service account/IAM/secrets | task retry + accepted/pending | P0 |
| Cloud Storage | receipt photos/export ZIP | Firebase Storage | private paths, rules, encryption | local draft image | P0 |
| OCR primary | Vietnamese bill extraction | Cloud Vision DOCUMENT_TEXT_DETECTION or Document AI OCR | IAM, quota, region | manual entry + secondary adapter | P0 |
| OCR secondary | optional parser + structured extraction | Document AI OCR/Form Parser / model extraction adapter | region/benchmark/policy | do not guess fields | P1 |
| FCM / APNs | device push | firebase_messaging, Firebase Admin | APNs Auth Key, FCM service | in-app inbox | P0 |
| Google Play Billing | Android Plus subscription | in_app_purchase plugin/BillingClient + Google Play Developer API | product/base-plan/Play service | Free until verified; restore | P0 |
| Apple StoreKit | iOS Plus subscription | in_app_purchase/storekit + App Store Server API | products + server key/JWS verification | pending until verified | P0 |
| Apple Server Notifications v2 | sub lifecycle/refund | signedPayload JWS | verified Apple signing cert chain + bundle/env | periodic reconciliation | P0 |
| Google RTDN / PubSub | sub lifecycle/refund | Pub/Sub + Play Developer API | verified OIDC/IAM/package + service | periodic reconciliation | P0 |
| AdMob | Free plan ads | google_mobile_ads (Flutter) | Android/iOS app IDs, test units | hide ad slot if fails | P0 |
| UMP / ATT | consent/ads privacy | User Messaging Platform + platform ATT if applicable | consent forms/policy strings | non-personalized/disabled ads per policy | P0 |
| Crashlytics & Performance | crash and performance monitoring | FlutterFire | opt-in/regional policy/redaction | local log for development | P0 |
| Remote Config | feature flags, OCR provider kill switch | FlutterFire Remote Config | signed/default configs | local defaults | P0 |
| Google Analytics Firebase | aggregate usage analytics | FlutterFire analytics | privacy-sanitized events | core functions not dependent | P1 |
| WidgetKit | iOS OS widget | SwiftUI WidgetKit + App Group storage | entitlements/app group | in-app widget still works | P1 |
| Android Glance | Android OS widget | Kotlin Glance + DataStore | manifest/widget providers | in-app widget still works | P1 |
| FX provider | currency conversion | optional future | legal licensed provider, stale TTL | disable cross-currency total | P2 |
| Security price feed | investments valuations | optional future authorized vendor | symbol mapping/contract/licensing | manual valuation & stale badge | P2 |
| Open banking/bank aggregator | bank import | optional future region-specific provider | legal/consent/security review | manual/CSV import | P2 |

## 1. Firebase Auth / login
**Flows**: Google One Tap/native Google sign-in, Sign in with Apple on iOS where required, phone OTP as optional. Auth provider user ID maps to `/users/{uid}`; first login calls idempotent `createHousehold`, not unrestricted client write.

**Implementation**: `FirebaseAuthService` encapsulates provider login, link/unlink, token refresh, user deletion/reauth. Use OAuth state and platform SDKs, not embedded web password scraping. Support Apple private relay email. Phone sign-in requires abuse limits, SMS billing controls and risk review. Auth identity != authorization; membership checked against `/members/{hid}/{uid}`.

**Tests**: cancelled login, OTP invalid/expired/rate-limited, account linking, removal, sign-out cache clear, token expiration, lost device. No secrets in analytics.

Docs: https://firebase.google.com/docs/auth/flutter/start ; https://firebase.google.com/docs/auth/flutter/federated-auth ; https://developer.apple.com/sign-in-with-apple/

## 2. App Check / client assurance
- Enable on Flutter Android with Play Integrity, Apple with DeviceCheck/App Attest where supported. Do not assume App Check prevents all abuse or replaces Auth.
- Configure callable `enforceAppCheck` and enforcement for supported Firebase products after staging rollout; debug provider only local/emulator, not prod build.
- Quota/cost test and rollout monitoring: deny malformed/absent App Check tokens, check device compatibility.
- Docs: https://firebase.google.com/docs/app-check/flutter/default-providers ; https://firebase.google.com/docs/functions/callable

## 3. OCR Vietnamese receipts — provider selection
**Do not use Document AI Expense Parser as guaranteed Vietnamese extractor.** Current official supported language list for pre-trained Expense Parser (de, en, es, fr, ja, nl) does not include vi. **Cloud Vision OCR and Document AI OCR/Form Parser list Vietnamese**; choose OCR base for Vietnamese bills and use structured extraction normalization in our backend. Avoid calling a generative model unless privacy, cost and benchmark justify it.

**Input** JPG/PNG/PDF optional; max image size/configurable; checksum, MIME sniffing, page count cap, crop/rotate; object stored `receipts/{hid}/{uid}/{jobId}/original` private.

**Server flow**: `initReceiptUpload` reserves job -> short-lived, scoped GCS signed upload URL generated by authorized `initReceiptUpload` -> finalize/enqueue `parseReceipt` once -> OCR adapter -> normalizer/field-level confidence -> `/receiptDrafts/...` -> `REVIEW_REQUIRED`. Never send original bill to client ad/analytics vendors. If no confident amount/date, mark `MISSING` and ask review.

**Normalize candidate fields**: `merchant`, `issueDate`, `currency`, `totalMinor`, `subtotal`, `tax`, `lineItems[{name,qty,unitPrice,total}]`, `paymentMethod`, `confidence`, `bbox`, `rawTextReference` (access restricted), `provider`, `modelVersion`. Parsing Vietnamese separators (`1.234.567`, `1,234,567`) and ambiguity handled with locale/total cross-check, not naive string stripping.

**Benchmark before deploy**: at least 100–300 consented/anonymized real Vietnamese receipts across supermarkets, markets, restaurants, faded/thermal, handwritten, multiple totals. Evaluate per-field precision/recall, percent requiring correction, p50/p95 latency, cost/image, failure/low-confidence. Proposed launch target >= 95% *amount correct after user review* (not raw OCR accuracy), zero automatic posting. Compare OCR-first / alternative only against actual samples.

**Failure/retry**: timeout, unsupported format, invalid image, quota, low OCR -> manual path; bounded tasks and quota alarms. Encrypt/store region appropriately; sensitive text removed per retention policy.

Docs: https://docs.cloud.google.com/vision/docs/languages ; https://docs.cloud.google.com/vision/docs/ocr ; https://docs.cloud.google.com/document-ai/docs/processors-list

## 4. Storage
- Use short-lived GCS V4 signed PUT upload URL scoped to a reserved `{hid}/{uid}/{jobId}` object after server verifies membership. Backend checks size (10 MB initial target), file magic and MIME after upload before OCR; Storage SDK direct reads/writes remain denied by `firebase/storage.rules`. Signed URLs are bearer credentials: short TTL, restricted path and never logged. A server-side completion event verifies reservation + checksum and enqueues OCR.
- Only confirmed legitimate jobs may be processed; file path derived server-side; owner and active household membership verified at review/download.
- For report export, write to private `exports/{uid}/{jobId}/...`, use one-time/short-lived access controlled access, clean after TTL. Never store permanent public receipt links in RTDB.
- Docs: https://firebase.google.com/docs/storage/flutter/upload-files ; https://firebase.google.com/docs/storage/security ; https://docs.cloud.google.com/storage/docs/access-control/signed-urls ; https://docs.cloud.google.com/storage/docs/access-control/signing-urls-with-helpers

## 5. FCM push + in-app inbox
- `firebase_messaging` requests permission contextually, not at first app launch; iOS must configure APNs capabilities/key. Android 13+ runtime notification permission. Monitor foreground/background/terminated behavior.
- Devices register token via authenticated callable, rotation and invalid token cleanup. Store server-private, no token logging.
- Domain event -> deterministic safe Inbox Notification -> opt-in/settings + quiet hours decision -> Cloud Tasks FCM send -> delivery audit. FCM payload default generic title/body, data contains only opaque notificationId/type/deepLink ID, not balances, amounts, card details or OCR text.
- `onMessage`, `onMessageOpenedApp`, `getInitialMessage` all route through permission-aware deep-link coordinator. Foreground presents in-app banner, respects category setting.
- For user quiet hours: inbox creation not blocked; delayed push only for non-critical, with expires/relevance check at dispatch.
- Docs: https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages ; https://firebase.google.com/docs/cloud-messaging/send/admin-sdk

## 6. Apple StoreKit + App Store Server API + Notifications V2
- Create auto-renewable subscription group with SKUs *suggested* `may.plus.monthly` and `may.plus.yearly` in App Store Connect. Configure price points by storefront; target Vietnam ~19k/month and ~190k/year, storefront product.price is source of truth. Offer terms and renewals visible in app; restore and manage subscription accessible.
- Flutter initiates **native** purchase sheet via `in_app_purchase` or platform supported equivalent; payment result contains evidence (signed transaction/transaction ID), not trusted entitlement.
- Backend `verifyStorePurchase` verifies JWS and status (Apple server API) and binds purchase to authenticated UID via appAccountToken where applicable. Do not rely only on client-side success flag.
- Apple V2 HTTPS webhook receives `signedPayload`; validate JWS signature/certificate chain, bundleId/environment, notificationUUID, transaction lifecycle. Persist delivery as dedupe inbox, fetch authoritative status, update `entitlements/{uid}`. Events include renewal, grace, expiry, refund, revoke; do not guess mapping without latest Apple docs.
- Periodic reconciliation protects against delayed webhook. Never grant VIP from a manually edited RTDB field or mock test receipt in prod.
- Expected states: `FREE`, `PENDING`, `ACTIVE`, `BILLING_RETRY`, `GRACE`, `EXPIRED`, `REVOKED`. `noAds` based on verified policy/state; define grace rules clearly, preserve Free finance access.
- Test Sandbox, TestFlight and notification test endpoint; subscription change/cancel/refund and device reinstall/restore.
- Docs: https://developer.apple.com/documentation/appstoreserverapi ; https://developer.apple.com/documentation/appstoreservernotifications ; https://developer.apple.com/design/human-interface-guidelines/apple-in-app-purchase

## 7. Google Play Billing + Play Developer API + RTDN
- Google Play Console SKUs/products suggested `may_plus_monthly`, `may_plus_yearly` (subscriptions/base plans). Native system billing only; currency/period retrieved from Play product details.
- Client purchase token sent over callable, backend calls Play Developer API `purchases.subscriptionsv2.get` as applicable; validate packageName, product, expiry, state, account binding, acknowledgment and fraud constraints.
- Acknowledge initial purchases within provider required window, preferably backend; renewals do not require acknowledgment. Do not grant Plus for PENDING purchase.
- RTDN via Pub/Sub: verify Pub/Sub push authentication or use authenticated event trigger; treat RTDN as change notification, **fetch state from Play**, dedupe by Pub/Sub messageId and purchase lifecycle identity. Reconcile missed updates on schedule.
- Refund/revoke/cancel/hold/grace handling tested. Product link/store management intent for self-service cancellation. Avoid indefinite Plus on server outage; last verified entitled state may have bounded grace according to documented policy.
- Docs: https://developer.android.com/google/play/billing/backend ; https://developer.android.com/google/play/billing/subscriptions ; https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptionsv2/get

## 8. AdMob + UMP + ATT
- Free: allow **only** quiet banner/native ad zones below summaries or in list separation; do not block data or overlay camera/amount form, confirmation, paywall, privacy settings or notification inbox. Plus: `noAds` verified from entitlement + locally cached TTL; immediately unload ad requests & remove reserved ad layout when entitlement active.
- `google_mobile_ads` with test ad unit IDs for debug; production AdMob IDs loaded by build environment. SDK initialization only after privacy/consent setup per vendor guidance.
- Use Google UMP consent for relevant regions, and iOS App Tracking Transparency only when tracking requires it. Never force personalized ads or target by transaction/asset balance/household behavior.
- Handle consent revocation, GDPR consent, US privacy requirements and region-specific disclosure; consult privacy/legal team and ad platform policies before launch. Fail closed: if no valid consent under policy, do not request non-compliant ads.
- Ad failure or lack of fill must not create large blank spacers or impair core usability. No incentivized ads to unlock core finance features.
- Docs: https://developers.google.com/admob/flutter/quick-start ; https://developers.google.com/admob/flutter/privacy/gdpr ; https://developers.google.com/admob/flutter/privacy/consent-mode

## 9. Native system widgets
- **iOS** WidgetKit + SwiftUI extension + App Group storage shared between Flutter and extension. Flutter writes sanitized snapshot into app-group storage via native bridge, triggers refresh using allowed WidgetCenter APIs while respecting budgets. Use timeline provider, do not assume seconds-granularity refresh.
- **Android** Jetpack Glance + AppWidget, DataStore/SharedPreferences & native bridge. Battery/network restrictions respected; no arbitrary always-running background service.
- Widgets Small/Medium/Large with privacy toggle; default show generic state or redacted amount when account locked; tapping widget opens authenticated deep link. Household switching refreshes snapshot; logout clears.
- Docs: https://developer.apple.com/documentation/widgetkit ; https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date ; https://developer.android.com/develop/ui/compose/glance

## 10. Crashlytics, observability, feature flags
- Crashlytics + Performance Monitoring may collect device/diagnostic metadata; privacy policy, consent and configuration reviewed. Apply field allowlist and scrubbing for custom keys/breadcrumbs.
- Remote Config controls OCR provider, disabled features, minimum app version, ad placements, plus paywall copy; **never** authorize finance writes, roles or subscription by Remote Config.
- Custom Analytics events only high-level action/result IDs (no amount, account name, receipt strings). See `12_PRODUCT_ANALYTICS.md`.
- Metrics/Cloud Monitoring alarms for OCR costs, DB reads/write egress, function error, callback webhook error, projection lag.

## 11. External future APIs — adapters only (do not implement real calls in v1)
- **Banks/open banking**: integration is region and partner dependent, needs explicit authorization, data retention constraints, bank security and user consent. Plaid-style aggregators may apply to US but not assume Vietnam availability; review Vietnam providers separately. No scraping bank passwords or SMS.
- **Price market data**: use licensed vendor with coverage/freshness, symbol ID, currency, timezone and corporate actions; user-entered valuation available when provider missing.
- **FX**: record quoted rate, timestamp, provider, target/base currency, spread/rounding policy and preserve original transaction currency. Do not generate blended totals without valid rates.
- **AI LLM enrichment**: optional category suggestions only after privacy & accuracy review; prompt injection from OCR text treated as untrusted, never execute instructions inside bills. PII minimization and opt-in policy.

## 12. Provider readiness checklist
For each provider: account/project setup, IAM least privilege, sandbox credentials, quotas/budget, SDK version pinned, webhook URLs + auth verified, retry/backoff strategy, observability dashboard, outage fallback, legal/privacy review, signed release capabilities, staging E2E, production smoke.
