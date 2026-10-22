# Flutter Architecture & Component Library — Mây

## Clean feature-first layers
```
apps/mobile/lib/
  main.dart
  app/{app.dart,router.dart,theme.dart,localization.dart}
  core/
    design_system/{tokens,typography,colors,spacing,motion}.dart
    ui/{atoms,molecules,organisms,patterns}/
    networking/{firebase_client,errors}.dart
    domain/{money,ids,clock}.dart
    state/{auth_provider,household_provider}.dart
    storage/{secure_storage,offline_commands}.dart
  features/
    onboarding/{presentation,application,domain,data}/
    household/{presentation,application,domain,data}/
    home/{presentation,application,domain,data}/
    transactions/{presentation,application,domain,data}/
    receipts/{presentation,application,domain,data}/
    budgets/{presentation,application,domain,data}/
    analytics/{presentation,application,domain,data}/
    accounts/{presentation,application,domain,data}/
    assets/{presentation,application,domain,data}/
    savings/{presentation,application,domain,data}/
    investments/{presentation,application,domain,data}/
    widgets/{presentation,application,domain,data}/
    notifications/{presentation,application,domain,data}/
    subscription/{presentation,application,domain,data}/
    settings/{presentation,application,domain,data}/
  integrations/{ios_widget_bridge,android_widget_bridge}/
```

Prefer Riverpod for feature state, typed repositories, `go_router` deep-link navigation, `freezed`/`json_serializable` DTOs, and `intl` for formats. The important boundary is **pure money calculation domain logic** distinct from Firebase SDK and Flutter widgets.

## Tokens / appearance
- `MayColors`: `canvas`, `surface`, `separator`, `textPrimary`, `textSecondary`, `accent`, `positive`, `warning`, `danger` with light/dark variants.
- `MaySpacing`: 4/8/12/16/20/24/32; default 16–20 screen horizontal padding.
- `MayRadius`: 8/12/16/24; cards usually 16–20.
- `MayTypography`: `display`, `title`, `headline`, `body`, `caption`, number tabular alignment.
- `MayMotion`: `quick=140ms`, `regular=240ms`, `modal=320ms`, `easeOutCubic`, reducedMotion switch. These are design targets, not OS-enforced timings.
- Cupertino behavior on iOS, Material adaptations on Android, but common brand presentation; support Dynamic Type/textScale.

## Shared atoms and molecules (24)
| Component | Essential input/props | Concern |
|---|---|---|
| `MayText` | style, maxLines, semanticLabel | typography, accessibility |
| `MayIcon` | semantic icon, size, color | consistent assets |
| `MayButton` | label, variant, loading, onPressed | debounce, disabled, hit area |
| `MayIconButton` | icon, tooltip, onPressed | 44pt hit target |
| `MayCard` | child, density, background | containers |
| `MaySectionHeader` | title, action | Home sections |
| `MayDivider` | indent | grouped list |
| `MayListTile` | title, subtitle, prefix, suffix, onTap | settings & accounts |
| `MayBottomSheet` | title, child, dismissible | primary action sheet |
| `MayConfirmDialog` | title, detail, isDestructive | delete/reversal |
| `MayTextField` | label, required, keyboard, validator | * for mandatory fields |
| `MayMoneyField` | currency, amountMinor, allowNegative=false | no float |
| `MayDateField` | value, timezone, onChange | timestamp correctness |
| `MaySearchField` | query, onChange | list filtering |
| `MaySegmentedControl` | items, selected | period switching |
| `MayFilterChip` | selected, onTap | categories |
| `MayBadge` | severity, label | statuses |
| `MayProgressBar` | value, limit, severity | budget |
| `MaySkeleton` | dimensions | loading |
| `MayEmptyState` | icon, text, action | no data |
| `MayErrorState` | message, retry | recoverability |
| `MayToast` | message, severity | transient result |
| `MayPrivacyAmount` | amount, currency, hideAmounts | screen privacy |
| `MaySwipeAction` | action, confirm | accessible alternatives |

## Composed domain components (23)
| Component | Where used | Contract |
|---|---|---|
| `BalanceHeroCard` | Home/Account | `amountMinor`, `currency`, trend, privacy |
| `IncomeExpenseOverview` | Home/Reports | period totals, delta |
| `TransactionRow` | Home/History | event, category, date, icon |
| `TransactionForm` | add/edit (correction) | typed form state, async submit |
| `AccountPicker` | transaction/transfer | only authorized active accounts |
| `CategoryPicker` | transaction/budget | searchable icons |
| `DateRangePickerSheet` | reports | week/month/year/custom |
| `PeriodSelector` | charts | selected period |
| `ExpenseDonutChart` | reports | top categories, exact legend |
| `CashflowBarChart` | reports | income vs expense by date |
| `NetWorthTrendChart` | assets | valuation freshness |
| `BudgetStatusCard` | Home/budget | threshold and remaining |
| `BudgetThresholdEditor` | budgets/settings | 80/100 etc. |
| `ReceiptCameraOverlay` | scanner | crop, permission, retry |
| `ReceiptReviewForm` | OCR | confidence, editable fields |
| `OCRConfidenceBadge` | receipt fields | low confidence warning |
| `AssetCard` | assets | type, valuation, estimate flag |
| `SavingsGoalCard` | goals | target vs contribution progress |
| `InvestmentGrowthCard` | portfolio | gain adjusted for cashflows |
| `AlertCard` | Notifications | severity, target deep link |
| `SubscriptionPlanCard` | Mây Plus | store price and duration |
| `AdPlacement` | Free screens only | entitlement check, no finance targeting |
| `MemberAvatarStack` | household | roles, count |

## Widget system (7)
- `WidgetRegistry` — centralized type/size/permissions config and data-source contract.
- `MayHomeWidgetShell` — consistent title, drag handle, edit affordance, rounded corners.
- `MayWidgetGrid` — home responsive layout, accessibility reordering.
- `MayWidgetGallery` — preview before adding.
- `MayWidgetDragOverlay` — drag placeholder, haptic, snap animation.
- `MayWidgetEditor` — add/remove/reorder/save/cancel/restore.
- `MayWidgetSnapshotBridge` — native OS transfer with redacted fields and refresh.
- `MayWidgetPrivacyOverlay` — require unlock/open app for sensitive detail when enabled.

### Widget types v1
`NET_WORTH`, `INCOME`, `EXPENSE`, `BUDGET`, `TOP_CATEGORIES`, `SAVINGS`, `INVESTMENTS`, `GOALS`, `RECENT_TRANSACTIONS`.

`WidgetDefinition { id, title, supportedSizes, dataSource, refreshPolicy, privacyLevel }`.

`WidgetPlacement { instanceId, widgetType, size, order, visible, settings }`.

## Reuse strategy
- Atoms no Firebase dependencies; domain components accept view-models, never RTDB snapshots directly.
- Register each widget with immutable ID and stable serialization. Avoid hardcoded colors/animation throughout screens.
- Native system widgets are SwiftUI / WidgetKit and Kotlin / Glance, **not Flutter widgets drawn outside the app**.
- Design for high contrast, Dynamic Type, VoiceOver/TalkBack, reduced motion, safe areas, dark mode and screen-reader labels.
- Screens should call application-level use-cases/providers, not Firebase directly; repository implementations isolated for mock data and emulator tests.

## Example Dart primitives
```dart
class Money {
  final int minor;
  final String currency;
  const Money(this.minor, this.currency);

  Money operator +(Money other) {
    if (currency != other.currency) throw ArgumentError('Currency mismatch');
    return Money(minor + other.minor, currency);
  }
}

enum WidgetType {
  netWorth, income, expense, budget, topCategories,
  savings, investments, goals, recentTransactions,
}

class WidgetPlacement {
  final String instanceId;
  final WidgetType type;
  final int order;
  final bool isVisible;
  final String size;
  const WidgetPlacement({required this.instanceId, required this.type,
    required this.order, required this.isVisible, required this.size});
}
```
