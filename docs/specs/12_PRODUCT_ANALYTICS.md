# 12 — Product Analytics, Observability & KPIs

## Privacy principle
Financial app telemetry must be **event-based without amounts/notes/merchant/category/member identities**. Only use aggregate outcomes/technical states; no raw transaction IDs as third-party analytics custom dimensions. Limit data retention and require appropriate user privacy consent.

## Event taxonomy
| Event name | Safe parameters | Not allowed |
|---|---|---|
| `onboarding_started` | entry=direct/invite, platform | phone/email |
| `onboarding_completed` | householdMode=personal/family | household name |
| `transaction_entry_opened` | entryMethod=manual/receipt | amount/category |
| `transaction_submit_result` | kind, result, latencyBucket | value/merchant/account |
| `transaction_reversed` | result, uiRoute | original amount |
| `receipt_capture_started` | source=camera/gallery | photo data |
| `receipt_ocr_completed` | providerClass, durationBucket, success, correctedFieldsCount | raw text/image/merchant |
| `budget_created` | periodType | budget limit, category |
| `budget_alert_opened` | severityBucket, navigationOutcome | actual spend |
| `report_period_changed` | period=WEEK/MONTH/YEAR | financial values |
| `widget_edit_saved` | count, countAdded, countRemoved | widget financial content |
| `notification_preference_changed` | notificationType, enabled | notification full text |
| `plus_paywall_viewed` | entryPoint, variant | store receipt |
| `plus_purchase_result` | provider, status, productTerm | token/order ID |
| `plus_restored` | status | purchase token |
| `data_export_requested` | scope, result | contents |
| `account_delete_requested` | scope, result | reason free text |

## Production telemetry (internal-only)
- HTTP/callable: `function, statusCode, latencyBucket, retryCount, correlationId` (internal only, limited retention).
- Ledger: `eventAccepted, projectorLagMs, reconciliationMismatchCount`, alert on nonzero mismatches; aggregate tenant metrics without finance payload.
- OCR: requests/day, per-provider failure %, max pages, p95 time, cost, percent sent to manual fallback.
- Push: eligible/delivered/failed, invalid tokens pruned, per-category opt-out.
- Purchase: pending/verified/refunded/restored, webhook signature reject count, entitlement latency, orphan purchase reconciliation.
- Ads: consent completion, no-ad entitlement match and impression/revenue telemetry only as allowed by policy; don't use finance categories for targeting.

## Basic dashboards
1. Reliability: crash-free, callable p95, error rate, RTDB throughput, projection lag.
2. Finance integrity: invalid postings rejected, duplicate retry count, reconciliation mismatches, stale projections.
3. OCR: job funnel, latency, cost, corrections, unreadable images.
4. Retention: first successful transaction, WAU households, weekly transaction recording rate.
5. Monetization: Plus conversion funnel, restore success, refund rate, ad failures.
6. Privacy: denied access attempts, rule failures by type, export/deletion completion.

## Release alerts
Create operational alarms for mismatched finance projection >0, excessive auth denial spikes, elevated OCR provider cost, unverified billing event storm, repeated failed export/delete jobs, and p95 latency above agreed target for sustained interval. Dashboard alone is not alerting.
