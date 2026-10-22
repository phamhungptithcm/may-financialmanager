# 01 — Product Requirements Document (PRD)

## Vision & success
Mây giúp cá nhân/gia đình ghi thu chi trong ~5–15 giây, biết ngân sách nào sắp vượt, nhìn tài sản ròng minh bạch, và không bị làm phiền vì thông báo/quảng cáo thiếu liên quan. Không được đưa lời khuyên đầu tư hay tuyên bố tỷ suất lợi nhuận khi thiếu dữ liệu.

## Personas
- **Cá nhân bận rộn**: nhập chi tiêu nhanh, ảnh hóa đơn, ẩn số tiền nơi công cộng.
- **Người quản lý chi tiêu gia đình**: invite người thân, phân quyền, quản lý ngân sách, thấy ai ghi gì.
- **Người tích lũy**: thấy tài sản, tiết kiệm, mục tiêu, đóng góp và thay đổi giá trị quý/năm.
- **Người coi trọng sự riêng tư**: quyền dữ liệu, notification privacy, export/delete và không quảng cáo nếu Plus.

## Functional requirements (testable)
| ID | Priority | Requirement | Acceptance summary |
|---|---|---|---|
| FR-001 | P0 | Login Google/Apple/Phone, sign-out, session recovery | Restart still works; auth revoked properly |
| FR-002 | P0 | Create personal household on first login | idempotent creation |
| FR-003 | P0 | Create/edit household & member invite | invite expiry + single-use handling |
| FR-004 | P0 | Member roles & remove member | immediately lose read/write after removal |
| FR-005 | P0 | Create/edit/archive financial account | no deletion if referenced by events |
| FR-006 | P0 | Categories income/expense | stable IDs; archived remain reportable |
| FR-007 | P0 | Manual income/expense form | required `*`, valid amount/time, save once |
| FR-008 | P0 | Transfer between accounts | never counted income/expense |
| FR-009 | P0 | Edit/undo by reversal/correction | history preserved; once-only projection |
| FR-010 | P0 | Transaction timeline, search filters, pagination | shard month, no all-data fetch |
| FR-011 | P0 | Receipt capture/gallery and upload | mime/size/security checks |
| FR-012 | P0 | OCR merchant/date/total/items/categories | parse draft + confidence + missing state |
| FR-013 | P0 | User verifies receipt before posting | zero auto-post; edit possible |
| FR-014 | P0 | Budget create and progress | percent, used/remaining, period/timezone |
| FR-015 | P0 | Threshold alerts (80/100 default configurable) | dedupe per crossing & period |
| FR-016 | P0 | Home summary & insight widgets | no financial leakage on shared lock screen |
| FR-017 | P0 | Drag-add-hide-reorder widgets | persisted per UID + household |
| FR-018 | P0 | Income/spending reports week/month/year | compare correct local time periods |
| FR-019 | P0 | Category composition and top spend groups | no double-count reversed/transfers |
| FR-020 | P0 | Asset + liability register | value date/source/currency shown |
| FR-021 | P0 | Net worth history and valuation tracking | prevent cash/bank/holding duplicate tally |
| FR-022 | P0 | Savings goals / progress | contributions separated from returns |
| FR-023 | P0 | Investment holdings / contributions / valuation | user entered; no invented current price |
| FR-024 | P1 | Growth/flatline insights Q/Y | stale/missing data => no false warning |
| FR-025 | P0 | In-app notification inbox + unread/filter | deep-link authorized route |
| FR-026 | P0 | FCM push + notification settings | consent; quiet hours; dedupe |
| FR-027 | P1 | Native iOS/Android OS widgets | small/medium/large variants & privacy |
| FR-028 | P0 | Free ads in safe placements | no ads over financial forms or camera |
| FR-029 | P0 | Plus subscription 19k/month target & 190k/year target | store localized price authoritative |
| FR-030 | P0 | Restore, manage, expiry and refunds | backend verified noAds only |
| FR-031 | P0 | Currency/timezone settings | default VND/Vietnam; existing events preserved |
| FR-032 | P0 | Error/offline/loading/empty states | no silent data loss or false success |
| FR-033 | P0 | Export household data with owner authorization | async secure download + expiration |
| FR-034 | P0 | Delete account/data with protective confirmation | documented lifecycle and retention |
| FR-035 | P0 | Accessibility/dark mode/reduced motion | labels, contrast, scalable font, screen reader |
| FR-036 | P1 | Scheduled reminders & weekly digest | timezone + opt-in, digest not spam |
| FR-037 | P0 | Manually entered upcoming bill and payment status | recordBillSettlement links expense once |
| FR-038 | P0 | Editable profile and private inbox read states | self-only writes |
| FR-039 | P1 | Transfer household ownership with recipient acceptance | cannot orphan household |

## Core business rules
- BR-01: 1 authenticated user can join N households; every operation supplies active household and server authorizes membership.
- BR-02: Owner-only: delete household, transfer ownership, billing privacy administration. ADMIN cannot remove the last OWNER.
- BR-03: For `EXPENSE`/`INCOME`, amountMinor > 0 within safe integer; currency is ISO 4217; server validates account currency or asks explicit FX flow.
- BR-04: `TRANSFER` between distinct accounts in same household and currency; 0 net income/expense.
- BR-05: `reversal` must point to a posted event and must not be reversed twice; correction writes compensating event plus new accepted event.
- BR-06: Period keys derive from household timezone at posting, not device local clock. Week starts Monday by default, change only for future reports or rebuild.
- BR-07: Budget scoped to selected category(ies), monthly/weekly; alert thresholds sorted unique, minimum 1, up to 100; overrun can exceed 100%.
- BR-08: For a receipt, user can edit every detected field; no ledger event without explicit confirmation; same receiptJobId cannot post twice.
- BR-09: Asset values have `valuationAt`, `source=MANUAL|MARKET_API`, freshness. If held in tracked account/holding, mark `includedInNetWorth=false` for duplicate representations.
- BR-10: Growth alerts only evaluate when minimum start/end valuations and external flow history exist; compare actual *cashflow-adjusted return* with user-configured target; do not label deposits as gains.
- BR-11: Plus personal entitlement affects ads only. Free keeps core financial functions. Store proof required for `noAds=true`.
- BR-12: Notification push content default generic; sensitive numbers optional and only after explicit user opt-in. Deep-links must re-check access.
- BR-13: Member removal invalidates access immediately; mobile unsubscribes listeners and clears household local cache on logout/removal.
- BR-15: Bill reminders operate only on user-entered due dates; recording a bill paid must link an existing expense or record an explicit external settlement, never duplicate it.
- BR-16: Owner transfer requires a recipient acceptance and a recoverable server operation, not a single client edit to the owner UID.
- BR-14: Each command has `clientRequestId`; retry same payload returns same result, conflicting payload returns ALREADY_EXISTS/CONFLICT.

## UX journeys
1. Sign in → create personal household → add bank/cash → Home.
2. Home → `+` → Thu/Chi → nhập số tiền → tài khoản, danh mục, ngày → Lưu → pending → posted → Home updated.
3. Home `+` → Quét hóa đơn → permission → crop → processing → kiểm tra → Lưu → ledger.
4. Báo cáo → period tuần/tháng/năm → category drilldown → list transactions.
5. Ngân sách → chọn danh mục → đặt limit → đặt threshold → lưu → alert inbox/push khi vượt.
6. Tài sản → thêm nhà/xe/vàng/tiền gửi/đầu tư → valuation → net worth → tăng trưởng.
7. Home → Sửa → gallery → thêm/ẩn/kéo/sắp xếp → Lưu.
8. Chuông → Inbox → chi tiết → màn đích; Settings → giảm notify/ẩn amounts.
9. Profile → Mây Plus → chọn kỳ → store purchase → verifying → active; restore/manage/cancel in store.
10. Family → member invite → open invite link → authenticated acceptance → role-controlled view.

## Non-functional requirements & SLO targets (engineering goals, confirm by measurement)
- NFR-01: warm screen change <= 350ms for cached content on representative midrange phones; never block main thread on OCR.
- NFR-02: core transaction command API p95 <= 900ms (excludes cellular latency); background projection p95 <= 3s; monitor per region.
- NFR-03: crash-free sessions >= 99.5% after launch; no major data-loss incidents; crash reports exclude financial payloads.
- NFR-04: duplicate posting rate **zero under defined retry/concurrency tests**; money sum invariants every test.
- NFR-05: 100% unauthorized cross-household read/write attempts rejected in automated rules/API tests.
- NFR-06: offline UX queues manual drafts/commands and shows pending; no false posting success.
- NFR-07: acceptance supports screen reader, larger fonts, focus labels, touch target >=44pt on iOS.
- NFR-08: restore and data export correctness, auditability, backup restore drill before release.
- NFR-09: app startup/CPU/memory budgets derived from actual baseline and regression-tested.
- NFR-10: no personally identifiable finance details in analytics, crash logs, ad requests or FCM payloads by default.

## Outcome metrics (privacy-preserving)
- Onboarding complete / login start; first transaction within D1.
- Transaction success rate, OCR draft→confirmed rate, OCR correction rate.
- 7d/30d retention, weekly active households (aggregate only).
- Budget threshold seen → budget viewed; widget edit/save.
- Purchase verification success, subscription restore success; ad load failure.
- Pipeline reconciliation lag, zero-balance invariant failures, cross-tenant authorization denials, OCR p95.

## Out of scope as customer promises
Mây không đảm bảo investment performance, không phải tư vấn tài chính/công cụ thanh toán; number shown for manual assets not market-appraised. Privacy policy must explicitly disclose every third-party processor used.
