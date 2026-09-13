import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ironsam09/admin/admin_panel.dart';
import 'package:ironsam09/admin/admin_service.dart';
import 'package:ironsam09/data/repositories/store_repository.dart';
import 'package:ironsam09/features/cart/cart_state.dart';

void main() {
  const childSections = <int, String>{
    5: 'Sports Codes',
    4: 'Orders',
    1: 'Products',
    2: 'Categories',
  };

  for (final section in childSections.entries) {
    testWidgets('${section.value} back returns directly to Dashboard', (
      tester,
    ) async {
      await _pumpAdminRoute(tester);

      await tester.tap(find.byKey(ValueKey('admin-nav-${section.key}')));
      await tester.pump();
      expect(
        tester
            .widget<ListTile>(find.byKey(ValueKey('admin-nav-${section.key}')))
            .selected,
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey('admin-back-button')));
      await _finishTransition(tester);

      expect(find.byType(AdminDashboardView), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('admin-nav-0')))
            .selected,
        isTrue,
      );
      expect(find.byKey(const ValueKey('public-storefront')), findsNothing);
    });
  }

  testWidgets('Dashboard back returns to the public storefront route', (
    tester,
  ) async {
    await _pumpAdminRoute(tester);

    await tester.tap(find.byKey(const ValueKey('admin-back-button')));
    await _finishTransition(tester);

    expect(find.byKey(const ValueKey('public-storefront')), findsOneWidget);
    expect(find.byType(AdminPanel), findsNothing);
  });

  testWidgets('system back follows child to Dashboard to storefront', (
    tester,
  ) async {
    await _pumpAdminRoute(tester);
    await tester.tap(find.byKey(const ValueKey('admin-nav-4')));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await _finishTransition(tester);
    expect(find.byType(AdminDashboardView), findsOneWidget);
    expect(find.byKey(const ValueKey('public-storefront')), findsNothing);

    await tester.binding.handlePopRoute();
    await _finishTransition(tester);
    expect(find.byKey(const ValueKey('public-storefront')), findsOneWidget);
  });

  testWidgets('sidebar switches do not create duplicate history entries', (
    tester,
  ) async {
    await _pumpAdminRoute(tester);

    for (final index in [1, 2, 5, 4]) {
      await tester.tap(find.byKey(ValueKey('admin-nav-$index')));
      await tester.pump();
    }

    await tester.tap(find.byKey(const ValueKey('admin-back-button')));
    await _finishTransition(tester);
    expect(find.byType(AdminDashboardView), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('admin-back-button')));
    await _finishTransition(tester);
    expect(find.byKey(const ValueKey('public-storefront')), findsOneWidget);
  });

  testWidgets('RTL back control is top-right, labeled, and touch-sized', (
    tester,
  ) async {
    await _pumpAdminRoute(tester, size: const Size(375, 900));

    final finder = find.byKey(const ValueKey('admin-back-button'));
    final button = tester.widget<IconButton>(finder);
    final rect = tester.getRect(finder);

    expect(Directionality.of(tester.element(finder)), TextDirection.rtl);
    expect(button.tooltip, 'رجوع');
    expect(rect.center.dx, greaterThan(375 / 2));
    expect(rect.width, greaterThanOrEqualTo(48));
    expect(rect.height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpAdminRoute(
  WidgetTester tester, {
  Size size = const Size(1100, 900),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final store = StoreState(repository: const LocalStoreRepository());
  addTearDown(store.dispose);
  final service = _NavigationAdminService();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        key: const ValueKey('public-storefront'),
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              key: const ValueKey('open-admin'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AdminPanel(store: store, service: service),
                ),
              ),
              child: const Text('Open admin'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-admin')));
  await _finishTransition(tester);
}

Future<void> _finishTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

class _NavigationAdminService extends AdminService {
  _NavigationAdminService()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'test-anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  @override
  Future<Map<String, dynamic>> dashboard() async => {
    'orders_today': 0,
    'active_orders_count': 0,
    'active_orders': <Map<String, dynamic>>[],
    'pending': 0,
    'confirmed': 0,
    'sales': 0,
    'low_stock': 0,
    'out_of_stock': 0,
    'top_code': '—',
    'top_code_uses': 0,
    'top_code_revenue': 0,
    'pending_commissions': 0,
    'approved_commissions': 0,
    'paid_commissions': 0,
    'athletes': <Map<String, dynamic>>[],
  };

  @override
  Future<List<Map<String, dynamic>>> products() async => const [];

  @override
  Future<List<Map<String, dynamic>>> categories() async => const [];

  @override
  Future<List<Map<String, dynamic>>> inventory() async => const [];

  @override
  Future<List<Map<String, dynamic>>> orders() async => const [];

  @override
  Future<List<Map<String, dynamic>>> discounts() async => const [];

  @override
  Future<List<PayableCommissionGroup>> payableCommissions() async => const [];
}
