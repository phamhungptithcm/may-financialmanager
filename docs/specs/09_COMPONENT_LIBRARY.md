# 09 — Flutter Design System & 54 Reusable Components

## Architecture & coding contracts
- Use `core/ui` atoms/molecules, `features/*/presentation/widgets` business components, shared `theme` tokens. UI components take **view-models** only, not Firebase snapshots/providers; injection via feature controller.
- Responsive/adaptive iOS/Android with Cupertino affordances on iOS; no brittle pixel-perfect hardcoded device coordinates. Native OS widgets are separate SwiftUI/Glance code.
- All inputs have states `enabled`, `disabled`, `loading`, `error`; financial inputs validated server-side and client-side. Every component accessible to screen reader and RTL-safe where practical.
- Tokens: `MayColors`, `MayTypography`, `MaySpacing`, `MayRadius`, `MayElevation`, `MayMotion`; light/dark scheme; High contrast and reduced motion; decimal/money rendered with `intl` and platform locale.

## 24 foundation components
| # | Component | Public contract and behavior |
|---|---|---|
| A01 | `MayText` | `value,style,semantics,overflow`, Vietnamese diacritics / large fonts |
| A02 | `MayIcon` | `name,size,color,semanticLabel`, no icon-only unlabeled action |
| A03 | `MayButton` | `label,variant,onPressed,loading,enabled`, no double submission |
| A04 | `MayIconButton` | `icon,tooltip,onPressed`, min hit size |
| A05 | `MayCard` | `child,variant,margin,onTap`, semantic grouping |
| A06 | `MaySectionHeader` | `title,actionLabel,onAction`, short section title |
| A07 | `MayDivider` | `indent,thickness`, token consistent |
| A08 | `MayListTile` | `title,subtitle,leading,trailing,onTap`, content-size handling |
| A09 | `MayBottomSheet` | `title,body,primaryAction,dismissible`, keyboard/safe-area |
| A10 | `MayConfirmDialog` | `title,description,confirmType,onConfirm`, explicit destructive label |
| A11 | `MayTextField` | `label,required,validator,onChanged`, required `*` |
| A12 | `MayMoneyField` | `Money? value,onChanged,currency`, integer minor + formatting, no float |
| A13 | `MayDateField` | `localDate,timezone,onChanged`, consistent period picker |
| A14 | `MaySearchField` | `query,onChanged,clear`, debounced optional |
| A15 | `MaySegmentedControl` | `options,selected,onChanged`, VoiceOver labels |
| A16 | `MayFilterChip` | `label,selected,onToggle`, multiple selection |
| A17 | `MayBadge` | `label,kind`, color + text state |
| A18 | `MayProgressBar` | `used,target,allowOverLimit`, overrun clearly labeled |
| A19 | `MaySkeleton` | `shape,size`, not continuously animated under reduced motion |
| A20 | `MayEmptyState` | `title,description,action`, actionable no-data |
| A21 | `MayErrorState` | `title,message,retry`, support correlation ID optional |
| A22 | `MayToast` | `message,severity`, lightweight, accessible announcement |
| A23 | `MayPrivacyAmount` | `Money,hidden,placeholder,onToggle`, redaction across screenshots/OS widgets |
| A24 | `MaySwipeAction` | `primary,secondary,confirm`, gesture + non-gesture alternate |

## 23 domain components
| # | Component | Public inputs and functional contract |
|---|---|---|
| D01 | `BalanceHeroCard` | balance, currency, trendMethod, isRedacted, stale |
| D02 | `IncomeExpenseOverview` | income, expense, period, delta vs previous period |
| D03 | `TransactionRow` | eventVM, amount, date, account, reversal badge |
| D04 | `TransactionForm` | typed draftVM, submit state, validation map |
| D05 | `AccountPicker` | eligibleActiveAccounts, selected, currency predicate |
| D06 | `CategoryPicker` | kind, categories, selected, archive filter |
| D07 | `DateRangePickerSheet` | timezone-aware start/end and compare selection |
| D08 | `PeriodSelector` | WEEK/MONTH/YEAR, selected, onChanged |
| D09 | `ExpenseDonutChart` | byCategoryMinor, currency, total, alternative list |
| D10 | `CashflowBarChart` | points with income/expense, accessible data table |
| D11 | `NetWorthTrendChart` | snapshots with source/freshness markers |
| D12 | `BudgetStatusCard` | limit, used, percent, threshold, next action |
| D13 | `BudgetThresholdEditor` | thresholds BPS list, previews, validation |
| D14 | `ReceiptCameraOverlay` | camera permission, frame crop, retake & gallery fallback |
| D15 | `ReceiptReviewForm` | extracted fields, confidence, manual edit, explicit submit |
| D16 | `OCRConfidenceBadge` | field confidence, missing flag, tooltip |
| D17 | `AssetCard` | assetVM, source, age, includedInNetWorth |
| D18 | `SavingsGoalCard` | target, contributions, due date, progress |
| D19 | `InvestmentGrowthCard` | method XIRR/TWR/NO_DATA, return, period, confidence |
| D20 | `AlertCard` | title, summary-safe, severity, authorized deep link |
| D21 | `SubscriptionPlanCard` | store localized price, term, selected, auto-renew disclosure |
| D22 | `AdPlacement` | ad consent, entitlement, safe screen/placement ID, load states |
| D23 | `MemberAvatarStack` | member view models, role/count; no unneeded contact data |

## 7 widget framework components (54 total)
| # | Component | Public inputs and contract |
|---|---|---|
| W01 | `WidgetRegistry` | known widget definitions, permissions and sizes |
| W02 | `MayHomeWidgetShell` | title, value, privacy overlay, edit controls, accessible move |
| W03 | `MayWidgetGrid` | placements, columns, padding, reflow, scroll behavior |
| W04 | `MayWidgetGallery` | variants/sizes, preview, add action |
| W05 | `MayWidgetDragOverlay` | placeholder/lift/haptic/accessibility actions |
| W06 | `MayWidgetEditor` | draft layout state, reorder/remove/reset, save/cancel/revision |
| W07 | `MayWidgetSnapshotBridge` | privacy-filtered serialized DTO to SwiftUI/Glance |

Widgets available in gallery: `NET_WORTH`, `INCOME`, `EXPENSE`, `BUDGET`, `TOP_CATEGORIES`, `SAVINGS`, `INVESTMENTS`, `GOALS`, `RECENT_TRANSACTIONS`. Sizes: SMALL / WIDE in-app, OS SMALL/MEDIUM/LARGE. Multiple instances supported only where data config varies, e.g. per-account widget; stable `instanceId` separate from type.

## App routing & state architecture
```text
apps/mobile/lib/
  app/{may_app.dart,router.dart,environment.dart}
  core/
    domain/{money.dart,period.dart,percentage_bps.dart}
    design_system/{colors.dart,typography.dart,spacing.dart,radius.dart,motion.dart,theme.dart}
    ui/{atoms,molecules}/
    auth/{session.dart,permission_guard.dart}
    networking/{callable_client.dart,command_outbox.dart,error_mapper.dart}
    l10n/{app_vi.arb,app_en.arb}
  features/
    household/{domain,application,data,presentation}
    home/{domain,application,data,presentation}
    transactions/{domain,application,data,presentation}
    receipts/{domain,application,data,presentation}
    reports/{domain,application,data,presentation}
    budgets/{domain,application,data,presentation}
    wealth/{domain,application,data,presentation}
    notifications/{domain,application,data,presentation}
    widgets/{domain,application,data,presentation}
    subscription/{domain,application,data,presentation}
    settings/{domain,application,data,presentation}
  platform/{widget_bridge.dart,purchase_bridge.dart}
```
Controllers use Riverpod; repositories abstract Cloud Functions reads and RTDB listen; pure calculators have no Flutter/Firebase import. UI listens to `AsyncValue` from controller and handles all states; do not silently swallow exceptions.

## Example interfaces (reference)
```dart
@immutable
class Money {
  final int minor;
  final String currency;
  const Money({required this.minor, required this.currency});
  Money plus(Money b) {
    if (currency != b.currency) throw ArgumentError('Currency mismatch');
    return Money(minor: minor + b.minor, currency: currency);
  }
}

abstract interface class FinanceCommandRepository {
  Future<AcceptedCommand> createExpense(ExpenseDraft command);
  Future<AcceptedCommand> createTransfer(TransferDraft command);
  Future<AcceptedCommand> reverseEvent(String householdId, String eventId);
}

abstract interface class WidgetsRepository {
  Stream<WidgetLayout> watchLayout(String householdId);
  Future<WidgetLayout> saveLayout(WidgetLayout draft, int expectedRevision);
}
```

## Accessibility/component-level test requirements
- Every button/slider/chip/drag affordance focusable with label; reorder possible without drag, test TalkBack/VoiceOver.
- Money amounts use semantic localized label including sign/currency; prefer tabular digits. Charts have alternate exact list view.
- Large text 200% on common devices without overlap/clipping; color contrast measured not assumed from mockups.
- Reduced motion disables nonessential animations; UI affordances/confirmation remain visible.
- RTL is future-ready but vi-VN initial, test date/local currency with both `vi_VN` and `en_US` locales.
- Snapshot/widget data never reused across households on switch or logout.
