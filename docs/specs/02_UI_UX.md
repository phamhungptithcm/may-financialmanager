# 02 — UI/UX Functional Specification

## Design direction
Apple-inspired **clarity, deference, depth** without copying Apple's assets/trademarks. Vietnamese first. White/off-white canvas, readable typography, few accent colors, cards only when grouping improves scanability. Strong information hierarchy and semantic motion; not a dense fintech dashboard. Default iOS Cupertino interactions when appropriate, adaptive Material on Android. Use existing Mây Clean v2 prototype as visual reference, **not** as production source code.

## Navigation information architecture
```
Welcome/Auth/Onboarding
└── Main Shell (5 tabs)
    ├── Trang chủ [Home]  → widgets, quick add, notifications
    ├── Giao dịch [Transactions] → list, search, detail, add manually, scan
    ├── Báo cáo [Insights] → week/month/year, breakdown, trends
    ├── Tài sản [Wealth] → accounts, liabilities, savings, investment, goals
    └── Cá nhân [Settings] → household, members, notifications, Mây Plus, privacy
```
Use a central prominent Add shortcut from Home and/or nav, without crowding tab bar. Deep-link destinations require membership after auth. Store pending deep link until session ready. Back navigation must not accidentally replay commands.

## Screen inventory — route, key UI, states
| UI ID | Route (illustrative) | Main UI | Loading/empty/error + acceptance |
|---|---|---|---|
| UI-01 | `/welcome` | logo, concise intro, Sign in | no fake onboarding permission |
| UI-02 | `/auth` | Google, Apple, phone login | OTP resend timer, auth cancelled/error |
| UI-03 | `/onboarding/household` | personal/family, name & currency | defaults from locale; required fields `*` |
| UI-04 | `/onboarding/accounts` | add first cash/bank account | skip with empty-state guidance |
| UI-05 | `/home` | net worth, income/expense, budget, editable widget grid | skeleton; empty CTA; reconcile/pending badge |
| UI-06 | `/home/edit` | drag handle, hide/remove, done/reset | drag, keyboard reorder, undo, persist |
| UI-07 | `/home/widget-gallery` | nine widget options, preview sizes | disabled when incompatible; selection confirmation |
| UI-08 | `/home/os-widgets` | small/medium/large preview + OS instructions | privacy default on; cannot silently install OS widget |
| UI-09 | `/transactions` | time filter, search, grouped list | paginated by month; zero state; offline |
| UI-10 | `/transactions/add` | entry choice + shortcut | source context retained on return |
| UI-11 | `/transactions/manual` | type, amount, account, category, date, note | validations; submit locked while sending |
| UI-12 | `/transactions/transfer` | from/to, amount, date | distinct accounts, same currency, zero income/expense |
| UI-13 | `/transactions/:id` | receipt, amount, postings, creator, edit/undo | role gated; reversed display; deep link guard |
| UI-14 | `/transactions/:id/correct` | previous values, new values, reason | explicit confirmation; undo via reversal |
| UI-15 | `/receipts/camera` | camera frame, gallery, capture help | denied permission/gallery alternative |
| UI-16 | `/receipts/crop` | crop/rotate/reshoot | high contrast and retake option |
| UI-17 | `/receipts/processing` | progress phases, cancel/back | resilient resumable job; no fake certainty |
| UI-18 | `/receipts/review` | merchant, date, total, items, category, account | highlight uncertain fields; save requires review |
| UI-19 | `/receipts/error` | unreadable/no data/failure retry/manual | manual always available |
| UI-20 | `/analytics` | week/month/year tabs, period selector, summary trend | no data labels not zeros; drilldown |
| UI-21 | `/analytics/categories` | category chart and ranking | accessible legend, total matches detail |
| UI-22 | `/analytics/category/:id` | expenses list for category/period | total counts only posted active entries |
| UI-23 | `/budgets` | progress by category, remaining | archived budgets separated |
| UI-24 | `/budgets/new` | category, amount, period, thresholds | threshold percentages sorted, <= budget policy |
| UI-25 | `/budgets/:id` | history, actual, alert state, edit | explain overrun without shaming user |
| UI-26 | `/accounts` | cards balances, liabilities | sensitive hide toggle; freshness state |
| UI-27 | `/accounts/:id` | balance, account movements | paginated + statement continuity |
| UI-28 | `/accounts/edit` | type/currency/opening balance | cannot change currency after transactions without migration |
| UI-29 | `/wealth` | net worth, growth, asset list | show estimated/stale values |
| UI-30 | `/assets/edit` | asset class, amount/source/date, liability flag | avoid cash double count prompt |
| UI-31 | `/investments` | holding/cost/value/cashflow, return basis | unavailable data => show `Chưa đủ dữ liệu` |
| UI-32 | `/investments/:id` | holding details, valuation/cashflow history | manual source labeling, calculations explained |
| UI-33 | `/goals` | savings goals and progress | no fake guaranteed return |
| UI-34 | `/goals/edit` | target, due, contributions | realistic progress; validation |
| UI-35 | `/notifications` | unread/all inbox & contextual deep links | zero state, badge, pagination |
| UI-36 | `/notifications/settings` | types, frequency, quiet hours, privacy | permission status; testing preview |
| UI-37 | `/notifications/preview` | lock-screen preview with redaction | fake preview labeled, no unsolicited push |
| UI-38 | `/household` | family switcher, member list, invite | revoked members cannot navigate |
| UI-39 | `/household/invite` | invite link/code, role, expiry | revoke/copy; no secret leak |
| UI-40 | `/settings` | profile, currency, security, help, Mây Plus | account deletion accessible |
| UI-41 | `/plus` | 19k target month /190k target year, no-ads | localized verified price, terms/restore |
| UI-42 | `/plus/processing` | system purchase verification status | retry safely, no false success |
| UI-43 | `/plus/active` | membership status & manage | ads immediately removed after entitlement update |
| UI-44 | `/plus/manage` | renewal, store manage, restore | cancel/restore link, expired/grace labels |
| UI-45 | `/data/export` | authorized export request/status | expiring download link, owner rights |
| UI-46 | `/data/delete` | warnings, confirmation, progress | safeguards, reauth where needed |
| UI-47 | `/bills` | upcoming due dates, add/edit | statuses overdue/paid; no guessed dates |
| UI-48 | `/bills/:id` | due details, linked expense, mark paid | avoid duplicate payment posting |

**48 screens/routes** are the scope target; individual transient UI states may use sheets instead of new routes. Count is a design inventory, not evidence that all screens currently exist in Figma.

## Outstanding platform screens and service states
- UI-47 & UI-48 are deliberately small: `Hóa đơn` list supports title, due date, optional amount, reminder schedule, status. `Đã trả` links to an existing posted expense where present, or marks manually paid externally without fabricating an expense.
- Household owner transfer remains in UI-38 as a confirm-sheet flow: current owner nominates an existing active member, recipient explicitly accepts before server updates ownership.

## Detailed UX interaction contracts
### Home & widget editor
1. Enter Home with household selector & 3 key metrics; other widgets down the scroll. Avoid more than two competing primary CTAs.
2. Tap `Sửa` → edit mode: drag handles visible, plus button `Thêm`, contextual remove icon, sticky `Xong`.
3. Long press (mobile)/keyboard move via accessible actions; animate card lift ~160ms and settle ~250ms; avoid scroll hijack.
4. `WidgetRegistry` whitelists known type/size schema; layout allows reorder, hide, reset defaults; allow 1–2 columns depending on width.
5. Save -> `saveWidgetLayout` with optimistic update + authoritative revert on error; layout per user/per household; no financial widget writes.
6. Native widget: explicit small/medium/large previews; per-user secure minimal snapshot; hide amounts by default when device locked or privacy toggle on.

### Receipt scanning
1. User clicks `Quét hóa đơn`. Show benefit before OS camera permission (contextual only).
2. Capture/gallery -> crop/rotate -> upload with progress/cancel. Background queue survives app minimize when possible.
3. Processing can take seconds; show progress stage, not invented %.
4. Result UI displays merchant/date/total/category/account and optional item rows. Highlight low-confidence fields with caption `Kiểm tra lại`.
5. `Lưu giao dịch` disabled until amount/account/date valid; visibly say user confirms before posting. Retry uses same `clientRequestId` and `receiptJobId`.
6. Error/unsupported language/low-quality image → `Nhập tay` in one tap, preserving detected fields as draft.

### Budget/notifications
- On entering threshold 80% and 100%, persist one alert per user/budget/period/threshold with deterministic ID; quiet hours queues non-critical push, inbox still created.
- Push opens target after auth and permission check; target removed/archived shows safe fallback.
- Notification settings describe `Ngân sách`, `Hóa đơn`, `Tiết kiệm`, `Đầu tư`, `Báo cáo tuần`; never show unsolicited return rates or private amounts.

### Mây Plus paywall
- Title `Mây Plus`, benefit `Không quảng cáo`. Select `Gói tháng` (default) 19.000₫ target, `Gói năm` 190.000₫ target. Store values override hardcoded mock.
- CTA `Tiếp tục` opens official in-app purchase sheet; no fabricated credit-card form; show actual renewal terms and product duration before purchase.
- `Khôi phục giao dịch mua`, `Quản lý gói`, `Điều khoản`, `Quyền riêng tư`, clear close; use generic `Đang xác minh` until backend verifies.
- Pending, failed, cancelled, grace, refunded/expired and active states must be explicit. Entitlement server truth, not local `isVip` toggle.

## Design tokens, adaptive behavior
- **Typography:** SF Pro via native system fallback on iOS, platform system font on Android; display 30–34, title 24–28, section 18–20, body 15–17, caption 12–13 logical px. Dynamic Type/scale and Vietnamese diacritics tested.
- **Spacing:** 4,8,12,16,20,24,32; content horizontal pad ~20; cards radius 16–20; limit horizontal separators.
- **Color:** canvas `#F7F8F6`, surface `#FFFFFF`, primary `#171A19`, secondary `#68726E`, accent `#187A60`, success `#218761`, warning `#BC7E2C`, danger `#C65050`; target contrast AA and dark-mode tokens, these are starter values.
- **Motion:** tap 120–160ms, sheet 280–320ms, page transitions ~220–260ms, reorder spring ~240ms, count animate only when meaningful; honor `reduceMotion` / accessibility flags. No animations blocking commit feedback.
- **Layout:** small iPhone, large iPhone, Android phones & tablets; safe areas, keyboard insets; avoid bottom-nav overlap with paywall/keyboard.

## Shared UI states (every screen)
`initial`, `loading`, `empty`, `ready`, `submitting`, `pendingSync`, `success`, `offline`, `recoverableError`, `unauthorized`, `deletedNotFound`, `accessibilityLargeText`. Include retry and leave-safe paths. Buttons not active twice while submitting. Form required labels use `*`, optional fields no star; server returns field-specific errors.

## Copywriting guide (Vietnamese)
Keep labels <= ~3 words where possible; prefer verbs: `Thêm giao dịch`, `Lưu`, `Sửa`, `Xong`, `Quét hóa đơn`, `Nhập tay`, `Chưa có dữ liệu`, `Kiểm tra lại`, `Không quảng cáo`. Distinguish `Thu nhập`, `Chi tiêu`, `Chuyển khoản`, `Tài sản ròng`, `Định giá`, `Đóng góp`, `Lợi nhuận`. Never claim `Lợi nhuận` if only contribution growth is known. Date/amount formatting `19.000 ₫`, `20/10/2026` locale vi-VN. Show timezone-sensitive period and currency on report.

## UI delivery acceptance
- Every route has screenshot test + back/deep-link behavior; no dead buttons.
- VoiceOver/TalkBack names and semantics, money amounts read naturally, all charts have tabular alternate view.
- Offline drafts saved securely and show pending; user knows if data is not server-posted.
- User can use entire core app without Plus. Only Free-safe, unobtrusive ads; never display ads in camera, amount form, confirmation, settings privacy, notifications.
- Existing prototype Clean v2 provides styling direction; native Flutter implementation must be semantic widgets, not WebView wrapping prototype.
