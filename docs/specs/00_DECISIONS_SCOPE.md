# 00 — Decisions, Scope, Glossary & Risks

## Product positioning
**Mây** giúp người dùng Việt Nam biết tiền đang ở đâu, tiêu vào việc gì và mục tiêu tài chính tiến triển ra sao. Có chế độ cá nhân và gia đình, tiếng Việt mặc định. Đề cao **đúng số liệu + riêng tư + thao tác ít bước**, không cố trở thành ứng dụng ngân hàng.

## Chốt v1
| Decision | Chốt | Lý do / trade-off |
|---|---|---|
| Target | iOS + Android | Flutter single UI codebase, plugin native cho widgets |
| Data entry | Manual hoặc OCR rồi xác nhận | An toàn hơn auto-booking receipt |
| Backend | Firebase Functions v2, TS | nhanh ship, có scheduler/task; cost theo usage |
| DB | Realtime Database | live sync nhanh; cần denormalization/index; tránh query phức tạp |
| Authoritative ledger | Immutable event + balanced postings | khả năng audit/replay; phức tạp hơn CRUD |
| Sync UX | read model eventual consistency | tách write khỏi projection; hiển thị pending/syncing |
| Pricing | Free ads; personal Plus ad-free | không hạn chế ghi chép/đọc báo cáo core |
| Target prices | 19k VND monthly, 190k VND annually | actual store-localized price authoritative |
| Billing | Apple IAP, Google Play Billing | digital subscription in mobile apps |
| OCR | Vietnam OCR benchmark before selection | Document AI Expense Parser không công bố `vi` support |
| Investments | manual holdings and cashflow | tránh market API phí/cấp phép ở MVP |
| Auth | Google/Apple/phone | Phone has SMS costs/fraud risk; email optional |
| Data residency | chọn region sau đánh giá pháp lý/latency | Firebase products khác nhau hỗ trợ region khác nhau |

## P0 (MVP launch)
Onboarding; Auth; personal household default; invite/member role; account/category; thu/chi/chuyển khoản/reversal; budgets; weekly/monthly/yearly summaries; asset/net worth; basic investment/savings data; receipt OCR + manual review; in-app alerts; FCM basic; home edit widgets; subscription monthly/yearly verified; Free ad placements; privacy/security; export/delete workflows; tracking ops.

## P1 sau launch
OS Home Screen WidgetKit/Glance; automated growth diagnostics based on sufficient data; family detailed visibility permissions; dynamic categorization; advanced receipt items; goals, recurring entries, bill reminders, cross-currency report with explicit FX; push summary customization.

## P2 / not in MVP
Bank account aggregation; real money transfer; card issuance; securities trading; tax filing, financial advice; auto price feed without license; real-time brokerage API; automatic AI purchasing; shared subscription Family plan; business accounting; complex multi-currency settlement. Build interfaces to extend later; do not implement fake adapters.

## Glossary
- **Household:** logical tenant, independent privacy/roles.
- **Personal household:** automatically created default private tenant for solo user.
- **LedgerEvent:** immutable canonical accepted action with balanced postings.
- **Projection:** derived read model; rebuildable.
- **Available balance:** account opening amount + accepted posted movements (not stale visual cache).
- **Net worth:** assets – liabilities with valuations and double-count prevention.
- **Growth:** user goal vs measured return; deposits are not investment earnings.
- **Plus entitlement:** verified personal right `noAds=true`, never household permission.
- **Receipt draft:** OCR extracted, untrusted until user confirms.

## Defaults, cần xác nhận trước release
- App name / bundle IDs / trademark and domain (working name Mây; verify availability).
- Regions: Vietnam first, VND first, Asia/Ho_Chi_Minh default; choose geographic hosting based on privacy law, service availability, disaster recovery and latency.
- Household roles: OWNER, ADMIN, EDITOR, VIEWER; choose whether a member may hide personal account. v1 default *shared household visible to active members*; private accounts must be modeled separately, not cosmetically hidden.
- Device minimum OS, accessibility target and launch regions decided during implementation after SDK compatibility study.
- Consent/legal text, paid price and offer IDs decided when store catalog configured.
- Receipts retention: default original images delete after 90 days unless user opts to keep; transparent data controls; align legal review.
- Financial values are user-entered estimates; market tracking only with source freshness shown.

## Risks & controls
1. **RTDB concurrency**: append at a single event node using transaction/CAS; do not rely on cross-node conditional writes. Projectors idempotent and reconciliation required.
2. **Large tenant download**: never listen `/households/{id}` for all data; month-shard and pagination.
3. **OCR privacy/quality**: only chosen processor region; no training use unless contract allows; feature flags & manual fallback.
4. **Store drift**: webhooks may delay; re-fetch status server-side; dedupe event IDs.
5. **Ad tracking**: UMP/ATT appropriate disclosures; sensitive finance data never forwarded into ad request/custom targeting.
6. **Investment returns**: TWR/XIRR with sufficient cashflows, otherwise `insufficient_data` rather than red alert.
7. **Offline retry**: local command outbox and server idempotency; never show unconfirmed as posted.
8. **Cost spikes**: Firebase budget alerts, quotas, Cloud Tasks rate limit, OCR uploads size caps, CI load tests.
