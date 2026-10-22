# Common Component Inventory — Mây Family Finance

Generated: 2026-10-22 (Phase 0)

Every component is classified as GLOBAL, SHARED DOMAIN, or FEATURE SPECIFIC.
No feature-specific component is promoted without proven cross-feature reuse.

---

## GLOBAL COMPONENTS

### MayColors
- **Layer:** Flutter / core / design_system
- **Scope:** Cross-application colour tokens for light and dark themes.
- **Responsibility:** Centralise every colour used across Mây UI; derive semantic tokens from a small palette of CSS variables.
- **Source Design:** `docs/FamilyClanMockupFullFlow.html` CSS `:root` variables and media-query overrides.
- **Public API:** `MayColors.primary`, `.accent`, `.success`, `.warning`, `.danger`, `.canvas`, `.surface`, `.textPrimary`, `.textSecondary`, etc. Each exposes a `MaterialStateProperty<Color?>` so consumers adapt to pressed/selected/disabled states automatically.
- **Dependencies:** None.
- **Consumers:** All features and shared widgets.

### MayTypography
- **Layer:** Flutter / core / design_system
- **Scope:** Cross-application text style tokens matching SF Pro (iOS) / platform system font (Android).
- **Responsibility:** Provide semantic `TextStyle` constants: `headlineLarge`, `headlineMedium`, `titleLarge`, `bodyLarge`, `bodyMedium`, `labelSmall`, etc. Respect Vietnamese diacritics and dynamic type scaling up to 200%.
- **Source Design:** Section "Typography" in `docs/specs/02_UI_UX.md`: display 30–34, title 24–28, section 18–20, body 15–17, caption 12–13 logical px.
- **Public API:** `MayTypography.headlineLarge(context)`, `.titleMedium(context)`, etc. All honour `MediaQuery.textScalerOf(context)`.
- **Dependencies:** `MayColors` for colour integration.

### MaySpacing
- **Layer:** Flutter / core / design_system
- **Scope:** Cross-application spacing multiples based on a 4dp grid.
- **Responsibility:** Provide `s.p2` through `s.p80` (2–80 dp). Content horizontal pad ~20 dp.
- **Source Design:** `docs/specs/02_UI_UX.md` spacing: `4, 8, 12, 16, 20, 24, 32`.
- **Public API:** `MaySpacing.p`, accessed as `MaySpacing.p.s4`, `s8`, `s12`, … `s80`.

### MayRadius
- **Layer:** Flutter / core / design_system
- **Scope:** Cross-application border radius values.
- **Responsibility:** Standardise card/button/radius tokens: 8, 12, 16, 20.
- **Source Design:** `docs/specs/02_UI_UX.md`: cards radius `16–20`.
- **Public API:** `MayRadius.s8`, `.s12`, `.s16`, `.s20`.

### MayElevation
- **Layer:** Flutter / core / design_system
- **Scope:** Cross-application elevation (shadow) tokens.
- **Responsibility:** Provide 4 distinct elevation levels consistent with Material/Apple depth semantics without copying Apple assets.
- **Public API:** `MayElevation.level1` … `.level4` returning appropriate `BoxShadow` or `shadowColor`.

### MayMotion
- **Layer:** Flutter / core / design_system
- **Scope:** Cross-application animation duration/easing tokens.
- **Responsibility:** Provide tap (120–160 ms), sheet (280–320 ms), page transition (~220–260 ms), reorder spring (~240 ms) durations and `Curves`. Honour `MediaQuery.reduceMotionEnabled`.
- **Source Design:** Section "Motion" in `docs/specs/02_UI_UX.md`.
- **Public API:** `MayMotion.tapCurve`, `.sheetDuration`, etc.

### MayTheme
- **Layer:** Flutter / core / design_system
- **Scope:** App-wide theme entry point.
- **Responsibility:** Merge light and dark themes; provide `mayTheme(context)` extension; supply default font family, text theme, visual density, and platform-adaptive Cupertino/Material defaults.
- **Public API:** `MayTheme.light()`, `.dark()`, `mayThemeOf(context)`.

### MayIconography
- **Layer:** Flutter / core / design_system
- **Scope:** Icon naming and sizing convention.
- **Responsibility:** Consistent icon size (24 dp default, 20 for small labels, 32 for hero CTAs), weight, and semantic label discipline. No icon-only action without a tooltip/semantics label.

---

### MayText
- **Layer:** Flutter / core / ui (atom)
- **Scope:** GLOBAL — reusable text widget with Vietnamese diacritics support, dynamic type, overflow handling, and semantics.
- **Responsibility:** A thin wrapper around `Text` that applies `MayTypography`, handles overflow (`ellipsis`, `fade`, `clip`), and carries accessibility labels.
- **Public API:** `MayText(string, style: …, overflow: …, semanticsLabel: …)`

### MayIcon
- **Layer:** Flutter / core / ui (atom)
- **Scope:** GLOBAL
- **Responsibility:** Consistent icon widget ensuring minimum hit size (44 dp) and semantic label.
- **Public API:** `MayIcon(IconData, size: 24, semanticLabel: '…')`

### MayButton
- **Layer:** Flutter / core / ui (atom/molecule)
- **Scope:** GLOBAL
- **Responsibility:** Primary/Secondary/Tertiary/Text variants with loading state, disabled state, double-submission guard. All states visible and accessible.
- **Public API:** `MayButton.primary(label: 'Lưu', onPressed: …, isLoading: false, isEnabled: true)`

### MayIconButton
- **Layer:** Flutter / core / ui (atom)
- **Scope:** GLOBAL
- **Responsibility:** Icon button with guaranteed 44×44 dp hit area and tooltip.
- **Public API:** `MayIconButton(icon: …, tooltip: '…', onPressed: …)`

### MayCard
- **Layer:** Flutter / core / ui (molecule)
- **Scope:** GLOBAL
- **Responsibility:** Grouping card with consistent radius (16–20), elevation, and optional tap behaviour.
- **Public API:** `MayCard(variant: .elevated, onTap: …, child: …)`

### MaySectionHeader
- **Layer:** Flutter / core / ui (molecule)
- **Scope:** GLOBAL
- **Responsibility:** Short section title with optional action label.
- **Public API:** `MaySectionHeader(title: 'Tài khoản', actionLabel: 'Thêm', onAction: …)`

### MayDivider
- **Layer:** Flutter / core / ui (atom)
- **Scope:** GLOBAL
- **Responsibility:** Token-consistent horizontal separator respecting spacing tokens.
- **Public API:** `MayDivider(indent: 20, endIndent: 20, thickness: 1)`

### MayListTile
- **Layer:** Flutter / core / ui (molecule)
- **Scope:** GLOBAL
- **Responsibility:** Consistent list item with title, subtitle, leading/trailing widgets, and tap target.
- **Public API:** `MayListTile(title: '…', subtitle: '…', onTap: …)`

### MayBottomSheet
- **Layer:** Flutter / core / ui (molecule)
- **Scope:** GLOBAL
- **Responsibility:** Modal bottom sheet with keyboard/safe-area awareness, title/body, and primary action.
- **Public API:** `MayBottomSheet(title: '…', body: …, primaryAction: …)`

### MayConfirmDialog
- **Layer:** Flutter / core / ui (molecule)
- **Scope:** GLOBAL
- **Responsibility:** Confirmation dialog with explicit destructive label and semantic safety.
- **Public API:** `MayConfirmDialog(title: '…', description: '…', confirmType: .destructive, onConfirm: …)`

### MayTextField
- **Layer:** Flutter / core / ui (atom)
- **Scope:** GLOBAL
- **Responsibility:** Text input with label, required indicator (`*`), validator, loading and disabled states. Accessible labels for screen readers.
- **Public API:** `MayTextField(label: 'Tên', required: true, validator: …)`

### MayMoneyField
- **Layer:** Flutter / core / ui (atom)
- **Scope:** GLOBAL
- **Responsibility:** Numeric input for integer minor units (no float). Displays formatted currency string; collects raw minor unit on submit.
- **Public API:** `MayMoneyField(value: Money?, currency: 'VND', onChanged: (Money?) => …)`

### MayDateField
- **Layer:** Flutter / core / ui (atom)
- **Scope:** GLOBAL
- **Responsibility:** Date picker field with timezone awareness and period picker consistency.
- **Public API:** `MayDateField(date: DateTime, timezone: 'Asia/Ho_Chi_Minh', onChanged: …)`

### MaySearchField
- **Layer:** Flutter / core / ui (atom)
- **Scope:** GLOBAL
- **Responsibility:** Search input with optional debouncing and clear button.
- **Public API:** `MaySearchField(query: '…', onChanged: (q) => …)`

### MaySegmentedControl
- **Layer:** Flutter / core / ui (molecule)
- **Scope:** GLOBAL
- **Responsibility:** Platform-adaptive segmented picker (WEEK/MONTH/YEAR, etc.) with VoiceOver/TalkBack labels.
- **Public API:** `MaySegmentedControl(options: {'Tuần': 0, 'Tháng': 1}, selected: 1, onChanged: …)`

### MayFilterChip
- **Layer:** Flutter / core / ui (atom)
- **Scope:** GLOBAL
- **Responsibility:** Multi-select chip with selected/normal states and accessible toggle.
- **Public API:** `MayFilterChip(label: 'Tiền mặt', selected: true, onToggle: …)`

### MayBadge
- **Layer:** Flutter / core / ui (atom)
- **Scope:** GLOBAL
- **Responsibility:** Numeric or status badge with colour and text state.
- **Public API:** `MayBadge(label: '3', kind: .alert)`

### MayProgressBar
- **Layer:** Flutter / core / ui (molecule)
- **Scope:** GLOBAL
- **Responsibility:** Linear progress indicator for budgets with overrun visual when used > limit.
- **Public API:** `MayProgressBar(used: 3_600_000, target: 4_500_000, allowOverLimit: true)`

### MaySkeleton
- **Layer:** Flutter / core / ui (atom)
- **Scope:** GLOBAL
- **Responsibility:** Loading placeholder without continuous animation when reduced motion is enabled.
- **Public API:** `MaySkeleton(shape: .rect, size: Size(200, 16))`

### MayEmptyState
- **Layer:** Flutter / core / ui (molecule)
- **Scope:** GLOBAL
- **Responsibility:** Actionable empty state with title, description, and optional action button.
- **Public API:** `MayEmptyState(title: 'Chưa có giao dịch', description: 'Nhấn + để bắt đầu', action: MayButton.primary(…))`

### MayErrorState
- **Layer:** Flutter / core / ui (molecule)
- **Scope:** GLOBAL
- **Responsibility:** Error state with title, message, retry button, and optional correlation ID.
- **Public API:** `MayErrorState(title: 'Lỗi đồng bộ', message: '…', onRetry: …)`

### MayToast / MaySnackbar
- **Layer:** Flutter / core / ui (molecule)
- **Scope:** GLOBAL
- **Responsibility:** Lightweight toast/snackbar with severity levels (info, success, warning, error). Accessible announcement.
- **Public API:** `MayToast.show(context, message: 'Đã lưu', severity: .success)`

### MayPrivacyAmount
- **Layer:** Flutter / core / ui (atom)
- **Scope:** GLOBAL
- **Responsibility:** Toggle-able amount redaction for public-facing display and lock-screen privacy. Shows placeholder instead of financial value. Supports screenshots/OS widgets.
- **Public API:** `MayPrivacyAmount(amount: Money, hidden: bool, placeholder: '•••', onToggle: …)`

### MaySwipeAction
- **Layer:** Flutter / core / ui (molecule)
- **Scope:** GLOBAL
- **Responsibility:** Swipeable list item with primary/secondary actions and confirm-before-destructive pattern. Provides non-gesture alternate action for accessibility.
- **Public API:** `MaySwipeAction(item: transactionRow, primary: .delete, secondary: .archive)`

---

## SHARED DOMAIN COMPONENTS

### BalanceHeroCard
- **Domain:** Finance display
- **Responsibility:** Hero balance display with currency formatting, trend method, and redaction support.
- **Inputs:** `balance: Money`, `currency: String`, `trendMethod: TrendMethod`, `isRedacted: bool`, `stale: bool`

### IncomeExpenseOverview
- **Domain:** Finance display
- **Responsibility:** Period income/expense comparison with delta vs previous period.
- **Inputs:** `income: Money`, `expense: Money`, `period: Period`, `deltaVsPrevious: double`

### TransactionRow
- **Domain:** Finance display
- **Responsibility:** Single transaction list item with amount, date, account, category, and reversal badge.
- **Inputs:** `eventVM: TransactionEventVM`, `amount: Money`, `date: DateTime`, `accountName: String`, `reversal: bool`

### ExpenseDonutChart
- **Domain:** Finance display / charts
- **Responsibility:** Category composition donut chart with accessible legend and tabular fallback.
- **Inputs:** `byCategoryMinor: Map<String, int>`, `currency: String`, `total: Money`

### CashflowBarChart
- **Domain:** Finance display / charts
- **Responsibility:** Income vs expense bar chart over time with accessible data table alternate view.
- **Inputs:** `points: List<CashflowPoint>`, `period: Period`

### NetWorthTrendChart
- **Domain:** Finance display / charts
- **Responsibility:** Net worth history line chart with source/freshness markers and NO_DATA fallback.
- **Inputs:** `snapshots: List<NetWorthSnapshotVM>`, `currency: String`

### BudgetStatusCard
- **Domain:** Finance display
- **Responsibility:** Budget progress card showing percent, used/remaining, threshold triggers, and next action hint.
- **Inputs:** `limitMinor: int`, `usedMinor: int`, `percent: double`, `thresholds: List<int>`, `nextTriggerAt?: double`

### MemberAvatarStack
- **Domain:** Household display
- **Responsibility:** Overlapping avatar list showing members with role/count. No unnecessary contact data displayed.
- **Inputs:** `members: List<MemberAvatarVM>`

---

## FEATURE-SPECIFIC COMPONENTS (examples; not implemented in Phase 0)

| Component | Feature | Description |
|-----------|---------|-------------|
| TransactionForm | transactions | Typed draft + validation map + submit state |
| AccountPicker | accounts | Eligible active accounts with currency predicate |
| CategoryPicker | accounts | Kind-filtered category list with archive toggle |
| ReceiptCameraOverlay | receipts | Camera permission, crop frame, retake/gallery fallback |
| ReceiptReviewForm | receipts | OCR-extracted fields with confidence and manual edit |
| SubscriptionPlanCard | subscription | Store-localized price, terms, auto-renew disclosure |
| AdPlacement | subscription | Consent-gated ad container with safe placement IDs |
| WidgetEditor | widgets | Draft layout reorder/remove/reset with revision CAS |

> **Note:** Feature-specific components are documented here as placeholders. They are NOT implemented in Phase 0. Implement only during their respective feature phase.

---

## REUSE RULES (enforced by static analysis and architecture review)

1. Before creating any new component, search `apps/mobile/lib/shared/` and `docs/architecture/COMMON_COMPONENT_INVENTORY.md`.
2. If an existing component covers the responsibility, extend it rather than create a duplicate.
3. Feature-specific components must not import from sibling features.
4. Shared components must not import feature modules.
5. Design tokens in `shared/design_system/tokens/` are the single source of truth for colours, typography, spacing, radii, and motion.
6. Public APIs of shared components require tests covering states (enabled, disabled, loading, error).
7. Components consuming `MayMoneyField` must never accept floating-point amounts from user input — raw minor units only.

---

## TESTING REQUIREMENTS BY CLASS

### GLOBAL components
- Widget golden tests for light and dark themes at 3 device widths + 200% text scale.
- Unit tests for every validator, formatter, and state transition in public API.
- Accessibility: TalkBack/VoiceOver label verification where applicable.
- Reduced motion: animation disabled path tested.

### SHARED DOMAIN components
- Widget tests for each input combination (empty, loading, ready, error).
- Property-based tests for domain calculations (trend, percentage, currency formatting).
- Golden tests at narrow/wide light/dark.

### FEATURE-SPECIFIC components
- Widget + integration tests covering feature acceptance criteria.
- Mock repository/stream for testability without live Firebase.
- Integration with shared components verified but not duplicated in golden tests.
