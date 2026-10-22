# 08 — Security, Permissions, Data Privacy, Threat Model

## Security objectives
Financial history, receipt photos, household membership, device notification tokens and payment metadata are sensitive. Requirements: cross-tenant isolation, integrity, minimal exposure, explicit retention/deletion, safe offline handling, never create false financial events.

## RBAC matrix
| Resource/action | OWNER | ADMIN | EDITOR | VIEWER | Not member |
|---|---:|---:|---:|---:|---:|
| Read household financial projections | ✓ | ✓ | ✓ | ✓ | ✗ |
| Create/edit accounts/categories | ✓ | ✓ | ✓ | ✗ | ✗ |
| Create/correct transactions | ✓ | ✓ | ✓ | ✗ | ✗ |
| Set budgets/assets/goals | ✓ | ✓ | ✓ | ✗ | ✗ |
| Invite/edit member role | ✓ | ✓ limited | ✗ | ✗ | ✗ |
| Transfer ownership / delete household | ✓ | ✗ | ✗ | ✗ | ✗ |
| Save own widget layout | ✓ | ✓ | ✓ | ✓ | ✗ |
| Read/update own notifications | ✓ | ✓ | ✓ | ✓ | ✗ |
| Read own Plus entitlement | own | own | own | own | own |
| Write Plus entitlement | server only | server only | server only | server only | server only |
| Export shared financial data | ✓ | ✓ with policy | ✗ | ✗ | ✗ |

**Privacy variant:** v1 member financial reads are household-shared by default, not per-account private. If adding private accounts later, data model must include ACL and projection scope; hiding a card in UI is not access control. Avoid member name/email in shared analytics.

## Trust boundaries
1. Mobile client untrusted: Auth + App Check token attached, but request fields still fully validated.
2. Admin SDK privileged: Rules do not apply, Functions must perform authorization and validators on every call.
3. OCR content untrusted: no executable actions/instructions, no raw content in logs or notifications.
4. Store webhook untrusted until signed payload/service verified and authoritative provider check succeeds.
5. Task/scheduler payload untrusted unless IAM/service identity plus internal validation.
6. User-owned RTDB paths can become a privilege escalation channel if backend treats them as verified; maintain explicit whitelist.

## Network/identity
- HTTPS/TLS only. App secrets must not be embedded on client; Firebase client API key not a secret but rules/auth required.
- OAuth redirect and Apple sign-in capabilities configured correctly; sign out revokes session locally and unregisters device.
- Auth UID comes from `context.auth.uid`, not client body. App Check validated when supported/enforced.
- Device binding for push; revoke invalid tokens and clear local cache on logout/member removal.
- Public links/invites random cryptographic tokens; store **hash** of token, expiry, maximum acceptance count and role.

## Database rules
- Root `.read=false`, `.write=false`. Explicit member access for each *specific* projected subtree; never read root `/households/{hid}` to infer child perms.
- Canonical `ledgerEvents`, `members`, `entitlements`, `purchaseEvents`, `auditLogs`, `idempotency`, `deviceTokens`: client write always false.
- Sensitive server-private paths client read false.
- User-owned `notificationRead`/`widgetLayouts` direct writes may be allowed only with strict schema; **v2 recommends callable** to reduce rules complexity and future abuse surface. Rules skeleton only includes authenticated read allowlists.
- Indexed query limitations on `transactionList`, `accountMovements`, `notificationInbox` backed by Emulator tests; rules aren't server-side filters.
- Evaluate ancestor grants carefully; `.read=true` on parent can make descendants readable. Deny tests must target nested paths as well.

## Storage rules
- Paths use tenant and UID. Server-only signed upload URL is minted after authorization, bound to reserved job path; Storage client rules deny direct access and backend enforces actual size/type/checksum on completion.
- Storage Rules cannot directly rely on RTDB tenant membership lookups. Signed GCS URLs bypass Firebase client rules by design, so backend must check membership and restrict method/path/expiry, and verify uploaded object before processing. Reads require fresh authorized signed GET or proxy; never expose persistent public download links.
- Export files private to owner and deleted on expiration; no long-lived signed public links in notifications.

## Threat-model table
| Threat | Example | Controls & tests |
|---|---|---|
| Cross-tenant IDOR | `hh_A` user reads `hh_B` | read membership at exact path + rules tests |
| Client forges VIP | edit local bool/RTDB entitlement | deny rules writes + store verification on server |
| Duplicate transaction | network retry/cloud trigger twice | deterministic request ID, immutable event, reconcile |
| Balance corruption | parallel upserts/replay | zero-sum postings, projector partition locks, nightly reconcile |
| Receipt exfiltration | public URL or logs | Storage private, short TTL and no OCR plaintext logs |
| Fake OCR text | text contains `ignore previous instructions` | strict JSON parse, untrusted data handling, no tool execution |
| Notification leak | lock-screen financial amounts | default redact, minimum push payload, user toggle |
| Store webhook forgery | HTTP post says renewed | JWS / OIDC validate + provider status fetch |
| Invite brute-force | short code enumeration | cryptographic nonce, TTL, rate limit + audit |
| Device token takeover | victim token registered by attacker | UID+device association and token rotation, no public read |
| Refund abuse | offline still Plus forever | entitlement expiry, webhook + scheduled reconciliation |
| Malicious files | huge file/pdf bomb/invalid MIME | upload max, content sniff, OCR quota and scan |
| Data inference from ads | financial category used for ad targeting | no sensitive fields/events passed to AdMob |

## Privacy by design
- Collect only fields needed for finance use. Do not collect national ID, bank login password, OTP from other services, raw card PAN or unnecessary precise location.
- Use consent notice for OCR third-party processing and ad privacy; provide export, delete and account accessibility flows.
- Notification body default generic. Analytics/ad events never contain amounts, notes, categories selected by user, member names or OCR.
- Encryption at rest/in transit provided by cloud platform is baseline; extra client-side encryption of receipt caches and native widget snapshots should be considered for threat model. Device lock screen redaction independent of server notification permissions.
- Data residency and legal controls require explicit Vietnam and launch-region legal review; do not claim blanket GDPR/Vietnam privacy law compliance from a checklist.

## Retention proposal (confirm legal requirements)
| Data | Default policy draft | Owner |
|---|---|---|
| Original unconfirmed receipt image | auto-delete 90d after processing if not saved | retention job |
| OCR unconfirmed extracted draft | 30d after last edit | retention job |
| Confirmed transaction ledger | retained while tenant active; deletion/anonymization policy | finance/privacy |
| Invitations | delete/revoke on expiry, 7-day backfill grace | security |
| Device tokens | until logout/invalid/30d stale | push service |
| Downloadable export | 24h after job completes | export service |
| Billing evidence | retention per finance/legal contract, least access | billing |
| Sanitized operational logs | 30–90d by sensitivity/incident policy | SRE |

## Incident response / control
- Alert on cross-tenant auth anomalies, unexpected elevated writes, high OCR upload rates, billing webhook signature rejection spikes, projection mismatch >0.
- Kill switches in Remote Config for **ad display** or OCR intake; backend controls for write operations remain separate and secure.
- Audit viewer access requires business justification; safe logs on unique `correlationId` and action, redact bodies/amounts.
- Test restore from backup; continuity plan for provider incidents, with read-only degradation and safe outbox retry.

## Pre-production gates
- Security rules Emulator tests covering all paths as different UIDs/roles; cross-tenant reads/writes 100% denied.
- Pen test auth/invite/receipt URL/payment callbacks; static & dependency scan; no credentials committed.
- Verify signed Store events, replay handling, APNs capability, App Check enforcement.
- Privacy policy, DPA and consent strings published; data export/delete actually works.
