/// Mây Family Finance — Router (go_router scaffold)
///
/// Route IDs mapped to UI-XXX from specs/02_UI_UX.md.
/// Only the navigation topology and route names are defined in Phase 0.
/// Screen implementations come in their respective feature phases.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// -- Route constants (from UI-XXX inventory) --

abstract final class Routes {
  // Auth / Onboarding
  static const welcome = '/welcome';
  static const auth = '/auth';
  static const onboardingHousehold = '/onboarding/household';
  static const onboardingAccounts = '/onboarding/accounts';

  // Home
  static const home = '/home';
  static const homeEdit = '/home/edit';
  static const homeWidgetGallery = '/home/widget-gallery';
  static const homeOsWidgets = '/home/os-widgets';

  // Transactions
  static const transactions = '/transactions';
  static const transactionsAdd = '/transactions/add';
  static const transactionsManual = '/transactions/manual';
  static const transactionsTransfer = '/transactions/transfer';
  static const transactionDetail = (String id) => '/transactions/$id';
  static const transactionCorrect = (String id) => '/transactions/$id/correct';

  // Receipts
  static const receiptsCamera = '/receipts/camera';
  static const receiptsCrop = '/receipts/crop';
  static const receiptsProcessing = '/receipts/processing';
  static const receiptsReview = '/receipts/review';
  static const receiptsError = '/receipts/error';

  // Analytics / Reports
  static const analytics = '/analytics';
  static const analyticsCategories = '/analytics/categories';
  static const analyticsCategory = (String id) => '/analytics/category/$id';

  // Budgets
  static const budgets = '/budgets';
  static const budgetsNew = '/budgets/new';
  static const budgetDetail = (String id) => '/budgets/$id';

  // Accounts / Wealth
  static const accounts = '/accounts';
  static const accountDetail = (String id) => '/accounts/$id';
  static const accountEdit = '/accounts/edit';
  static const wealth = '/wealth';
  static const assetEdit = '/assets/edit';
  static const investments = '/investments';
  static const investmentDetail = (String id) => '/investments/$id';
  static const goals = '/goals';
  static const goalEdit = '/goals/edit';

  // Notifications
  static const notifications = '/notifications';
  static const notificationSettings = '/notifications/settings';
  static const notificationPreview = '/notifications/preview';

  // Household / Settings
  static const household = '/household';
  static const householdInvite = '/household/invite';
  static const settings = '/settings';

  // Subscription (Mây Plus)
  static const plus = '/plus';
  static const plusProcessing = '/plus/processing';
  static const plusActive = '/plus/active';
  static const plusManage = '/plus/manage';

  // Data management
  static const dataExport = '/data/export';
  static const dataDelete = '/data/delete';

  // Bills
  static const bills = '/bills';
  static const billDetail = (String id) => '/bills/$id';
}

/// Auth state for route guards.
enum AuthState { unauthenticated, authenticated, pending }

/// The go_router configuration for Mây.
///
/// Phase 0: Router structure and shell navigation only.
/// Screen builders are stubbed — implemented during their feature phase.
class MayRouter {
  final GoRouter router;

  MayRouter({required AuthState initialAuthState})
    : router = GoRouter(
        initialLocation: Routes.welcome,
        debugLogDiagnostics: true,
        redirect: _redirect,
        routes: _routes(initialAuthState),
      );

  // -- Redirect logic (scaffold) --

  static FutureOr<String?> _redirect(
    BuildContext context,
    GoRouterState state,
  ) {
    // MVP: check auth; full household+deep-link logic in Phase 1.
    return null; // no redirect in Phase 0 — screens implemented later
  }

  // -- Routes (scaffold) --

  static List<RouteBase> _routes(AuthState initialAuthState) {
    final routes = <RouteBase>[];

    // Auth flow
    routes.add(
      GoRoute(
        name: 'welcome',
        path: Routes.welcome,
        builder: (ctx, state) => const _StubScreen(routeName: 'Welcome (UI-01)'),
      ),
    );

    // Main shell with 5-tab navigation (scaffold)
    routes.add(
      ShellRoute(
        navigatorKey: GoNavigatorKey('main'),
        builder: (ctx, _, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            name: 'home',
            path: Routes.home,
            builder: (ctx, state) => const _StubScreen(routeName: 'Home (UI-05)'),
          ),
          GoRoute(
            name: 'transactions',
            path: Routes.transactions,
            builder: (ctx, state) =>
                const _StubScreen(routeName: 'Transactions (UI-09)'),
          ),
          GoRoute(
            name: 'analytics',
            path: Routes.analytics,
            builder: (ctx, state) =>
                const _StubScreen(routeName: 'Analytics (UI-20)'),
          ),
          GoRoute(
            name: 'wealth',
            path: Routes.wealth,
            builder: (ctx, state) =>
                const _StubScreen(routeName: 'Wealth (UI-29)'),
          ),
          GoRoute(
            name: 'settings',
            path: Routes.settings,
            builder: (ctx, state) =>
                const _StubScreen(routeName: 'Settings (UI-40)'),
          ),
        ],
      ),
    );

    // Feature-specific routes are added during their respective feature phases.
    return routes;
  }
}

/// Navigation keys for shell routing.
class GoNavigatorKey {
  final String name;
  GlobalKey<NavigatorState>? key;
  GoNavigatorKey(this.name);
}

/// Placeholder bottom navigation shell (scaffold).
/// Actual nav bar implemented with shared components during Phase 1.
class _MainShell extends StatelessWidget {
  final Widget child;
  const _MainShell({required this.child});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual tab navigation using MayTabBar (Phase 1).
    return Scaffold(body: child);
  }
}

/// Stub screen for Phase 0 router scaffolding.
class _StubScreen extends StatelessWidget {
  final String routeName;
  const _StubScreen({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(routeName)),
      body: Center(child: Text('Route: $routeName\n[Phase 1+]')),
    );
  }
}
