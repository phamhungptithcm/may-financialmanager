# 13 — External Accounts, Secrets & Firebase Setup Runbook

**Never paste production keys into ChatGPT prompts or commit them.** The coding agent can write setup instructions and local-safe templates, but credentials/console connections require project owner action. Do not claim provider setup done before test event is received.

## Prerequisites / owners
- Apple Developer account / App Store Connect app (real developer team with bundle ID, signing, StoreKit products, App Store Server API keys).
- Google Play Console application + signing + Google Play Developer API access and Pub/Sub RTDN project.
- Google Cloud/Firebase billing-enabled projects for `may-dev`, `may-staging`, `may-prod` if Cloud Functions/Storage/OCR requirements demand it.
- Google Cloud Vision or Document AI project/processor, data processing region and IAM.
- Google AdMob accounts and application/ad unit IDs; UMP consent form configurations.
- Domain, Privacy Policy, Terms of Service, support contact, account deletion URL according to store policy.

## Dev/staging/prod Firebase project setup
1. Create 3 **separate** projects, choose RTDB + Storage region once considering latency/availability/residency.
2. Enable Firebase Auth providers and register iOS/Android apps with correct bundle/application IDs. Configure APNs key for FCM, proper iOS entitlements, Android SHA fingerprints where required.
3. Set up Functions v2 with regions (verify provider support), Cloud Tasks, Cloud Scheduler, service accounts with *least privilege*, and `firebase.json` emulator config.
4. Deploy deny-by-default RTDB/Storage Rules to dev first and run Emulator suite before allowing client reads. Add `.indexOn` for each query.
5. Configure App Check providers and staged enforcement (monitor first then enforce). Debug providers only dev.
6. Register Secret Manager secret names and IAM grants; use `defineSecret`/Functions v2 supported secret binding; never put Apple keys/private service JSON in Flutter or `.env` committed.
7. Enable Cloud Monitoring/Logging/Crashlytics/Performance with financial data redaction, budgets and quotas.
8. Configure backup export storage protected with separate restricted role; test restore regularly.

## Safe configuration inventory (names only)
| Config | Where | Notes |
|---|---|---|
| `FIREBASE_PROJECT_ID` | CI/env | per-environment ID, not secret |
| `FIREBASE_DATABASE_URL` | Flutter/backend env | per-env, validate expected project |
| `FUNCTIONS_REGION` | shared config | match selected Firebase region |
| `STORAGE_BUCKET` | server config | per-env private bucket |
| `GOOGLE_CLOUD_PROJECT` | Cloud backend | IAM scope |
| `OCR_PROVIDER` | Remote Config/backend | feature flag; never client-controlled for billing |
| `DOCUMENT_AI_PROCESSOR_ID` | backend config | if processor chosen |
| `DOCUMENT_AI_LOCATION` | backend config | regional data routing |
| `APPLE_BUNDLE_ID` | backend env | verify JWS binding |
| `APPLE_APP_ISSUER_ID` | server secret | app store API signing |
| `APPLE_APP_KEY_ID` | server secret | server-only |
| `APPLE_APP_PRIVATE_KEY` | Secret Manager | server-only PEM |
| `GOOGLE_PLAY_PACKAGE_NAME` | backend env | expected package identifier |
| `GOOGLE_PLAY_API_CREDENTIALS` | workload identity/secret | server only, prefer workload identity |
| `APPLE_WEBHOOK_URL` | App Store Connect | public HTTPS endpoint, verify signature |
| `GOOGLE_RTDN_SUBSCRIPTION` | Pub/Sub | authenticated push / event trigger |
| `APNS_KEY_ID`, `APNS_TEAM_ID` | Firebase console / secret | app push signing |
| `ADMOB_IOS_APP_ID`, `ADMOB_ANDROID_APP_ID` | app build env | not passwords; no secrets |
| `ADMOB_BANNER_IOS`, `ADMOB_BANNER_ANDROID` | app build env | test IDs outside prod |
| `MAY_PLUS_MONTHLY_PRODUCT_ID` | store catalog config | verify platform-specific IDs |
| `MAY_PLUS_YEARLY_PRODUCT_ID` | store catalog config | verify platform-specific IDs |
| `EXPORT_BUCKET`, `BACKUP_BUCKET` | backend env | IAM and retention |

## Native app setup
- Flutter: `flutterfire configure` per environment, generated `firebase_options.dart`; Android build variants and iOS schemes with unique application IDs and signing teams.
- iOS Push: APNs Auth Key uploaded to Firebase, Push Notifications & Background Modes capability configured as required; test physical device notifications.
- Android Push: proper Android 13+ permission, notification channels and icon assets; test background/terminated behavior.
- iOS Widgets: App Group entitlement shared with extension; WidgetKit target bundled and signed.
- Android Widgets: Glance dependency and manifest/widget provider; Android permission & schedule/battery policies.
- Purchases: sandbox product IDs and `StoreKit Configuration` for local tests; Play internal test users + test subscriptions. Both server environments must point to sandbox/testing correctly.

## Platform billing checklist
1. Create Plus auto-renew products. Set target VN pricing but display storefront resolved price.
2. Server-side verification: Apple signed JWS cert chain/environment/bundleId; Google purchase `subscriptionsv2.get` package/product/account binding and acknowledgment.
3. Configure and verify App Store Server Notifications **V2**; Google Play RTDN via Pub/Sub with verified identity.
4. Test purchase lifecycle: new, pending, renewal, cancelled, grace, billing retry, refund/revoke, restore, device reinstall, cross-device login, unknown UID.
5. Reconciliation scheduled service enabled and alarm for stale entitlements.
6. Ads integration activated only after consent config/legal text. No ad SDK receives category/amount/wealth data.

## OCR / privacy approval checklist
- Region/vendor/terms/data retention reviewed; OCR provider tested on anonymized Vietnamese receipts and real camera capture scenarios.
- Reserve/upload signed URL with short expiry; delete expired objects; inspect file magic/size after upload and before paid OCR.
- OCR raw text not persisted beyond need/retention; no raw receipts in third-party analytics, logs or feedback.
- Manual review enforced, confidence explained, cost per scan measured, abnormal usage rate limited.

## Deploy order
- Dev: emulator tests → rules staging deployment → Functions staging → Cloud Tasks/schedules/webhooks sandbox → Flutter staging build → E2E.
- Prod: explicit owner approval → matching rules/indexes → Functions v2 with feature flags disabled → smoke → staged native releases → progressively enable OCR/Ads/IAP with monitoring.
- Rollback changes never overwrite/delete immutable canonical events; turn off noncritical feature flags and restore prior read projection version, then reconcile.

## Exit evidence
For every integration record `Account connected?`, `Sandbox credential configured?`, `Signature verified?`, `Manual permission required?`, `Last test at`, `Result/log correlationId`, `Remaining blockers`. Without evidence label as **NOT CONFIGURED**, not Production-Ready.
