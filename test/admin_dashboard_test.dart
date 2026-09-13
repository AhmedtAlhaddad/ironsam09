import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsam09/admin/admin_panel.dart';
import 'package:ironsam09/admin/admin_service.dart';

void main() {
  final orders = [
    _order('1', 'IRON-0001', 'pending', customer: 'أحمد'),
    _order('2', 'IRON-0002', 'confirmed', customer: 'سالم'),
    _order('3', 'IRON-0003', 'preparing', customer: 'مريم'),
    _order('4', 'IRON-0004', 'delivered', customer: 'علي'),
    _order('5', 'IRON-0005', 'cancelled', customer: 'هدى'),
  ];

  test('active dashboard keeps active orders and excludes closed orders', () {
    final active = dashboardActiveOrdersFromRows(orders);

    expect(active.map((row) => row['status']), [
      'pending',
      'confirmed',
      'preparing',
    ]);
    expect(active.any((row) => row['status'] == 'delivered'), isFalse);
    expect(active.any((row) => row['status'] == 'cancelled'), isFalse);
  });

  test('delivered and cancelled orders remain available in history', () {
    final delivered = filterAdminOrders(
      orders,
      query: '',
      scope: AdminOrderScope.delivered,
      dateRange: AdminOrderDateRange.all,
    );
    final cancelled = filterAdminOrders(
      orders,
      query: '',
      scope: AdminOrderScope.cancelled,
      dateRange: AdminOrderDateRange.all,
    );
    final all = filterAdminOrders(
      orders,
      query: '',
      scope: AdminOrderScope.all,
      dateRange: AdminOrderDateRange.all,
    );

    expect(delivered.single['order_number'], 'IRON-0004');
    expect(cancelled.single['order_number'], 'IRON-0005');
    expect(all, hasLength(5));
  });

  test('order filters return a view without modifying source data', () {
    final before = orders.map((row) => Map<String, dynamic>.from(row)).toList();
    final result = filterAdminOrders(
      orders,
      query: 'أحمد',
      scope: AdminOrderScope.active,
      dateRange: AdminOrderDateRange.today,
      now: DateTime(2026, 9, 13, 18),
    );

    expect(result.single['order_number'], 'IRON-0001');
    expect(orders, before);
    expect(orders, hasLength(5));
  });

  testWidgets(
    'dashboard removes large commission cards and shows payable alert',
    (tester) async {
      final service = _FakeOperationsService(
        dashboardData: _dashboardData(orders, approved: 7),
        ordersData: orders,
      );
      var openedSportsCodes = false;

      await _pumpDashboard(
        tester,
        service,
        onOpenSportsCodes: () => openedSportsCodes = true,
      );

      expect(find.text('قيد الانتظار - غير مستحق حاليًا'), findsNothing);
      expect(find.text('تم دفعه سابقًا'), findsNothing);
      expect(find.text('عمولات مستحقة للدفع: 7 د.ل'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('admin-dashboard-open-sports-codes')),
      );
      await tester.pump();
      expect(openedSportsCodes, isTrue);
    },
  );

  testWidgets('dashboard hides payable alert when approved amount is zero', (
    tester,
  ) async {
    final service = _FakeOperationsService(
      dashboardData: _dashboardData(orders, approved: 0),
      ordersData: orders,
    );

    await _pumpDashboard(tester, service);

    expect(
      find.byKey(const ValueKey('admin-dashboard-payable-alert')),
      findsNothing,
    );
  });

  testWidgets('view all orders action requests the complete history', (
    tester,
  ) async {
    final service = _FakeOperationsService(
      dashboardData: _dashboardData(orders, approved: 0),
      ordersData: orders,
    );
    AdminOrderScope? requestedScope;

    await _pumpDashboard(
      tester,
      service,
      onOpenOrders: (scope, _) => requestedScope = scope,
    );
    await tester.tap(
      find.byKey(const ValueKey('admin-dashboard-view-all-orders')),
    );
    await tester.pump();

    expect(requestedScope, AdminOrderScope.all);
  });

  testWidgets('dashboard has focused loading and active-empty states', (
    tester,
  ) async {
    final pending = Completer<Map<String, dynamic>>();
    final service = _FakeOperationsService(
      dashboardData: _dashboardData(const [], approved: 0),
      ordersData: const [],
      dashboardFuture: pending.future,
    );

    await _pumpDashboard(tester, service, settle: false);
    expect(
      find.byKey(const ValueKey('admin-dashboard-loading')),
      findsOneWidget,
    );

    pending.complete(_dashboardData(const [], approved: 0));
    await tester.pumpAndSettle();
    expect(
      find.text('لا توجد طلبات تحتاج متابعة حاليًا. كل العمليات مكتملة.'),
      findsOneWidget,
    );
  });

  testWidgets('dashboard error is human-readable and offers retry', (
    tester,
  ) async {
    final service = _FakeOperationsService(
      dashboardData: const {},
      ordersData: const [],
      dashboardError: true,
    );

    await _pumpDashboard(tester, service);

    expect(find.textContaining('تعذر تحميل لوحة التحكم'), findsOneWidget);
    expect(find.textContaining('raw_postgrest_error'), findsNothing);
    expect(
      find.widgetWithText(OutlinedButton, 'إعادة المحاولة'),
      findsOneWidget,
    );
  });

  testWidgets('complete history has a neutral empty state', (tester) async {
    final service = _FakeOperationsService(
      dashboardData: _dashboardData(const [], approved: 0),
      ordersData: const [],
    );

    await _pumpOrders(tester, service, initialScope: AdminOrderScope.all);

    expect(find.text('لا توجد طلبات مطابقة للفلاتر الحالية.'), findsOneWidget);
  });

  testWidgets('reset filters changes UI filters only', (tester) async {
    final service = _FakeOperationsService(
      dashboardData: _dashboardData(orders, approved: 0),
      ordersData: orders,
    );
    await _pumpOrders(tester, service, initialScope: AdminOrderScope.all);

    await tester.enterText(
      find.byKey(const ValueKey('admin-orders-search')),
      'IRON-0005',
    );
    await tester.tap(find.byKey(const ValueKey('admin-order-scope-cancelled')));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('admin-order-row-5')),
        matching: find.textContaining('IRON-0005'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('IRON-0001'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('admin-orders-reset-filters')));
    await tester.pump();

    expect(find.textContaining('IRON-0001'), findsOneWidget);
    expect(find.textContaining('IRON-0002'), findsOneWidget);
    expect(find.textContaining('IRON-0003'), findsOneWidget);
    expect(find.textContaining('IRON-0004'), findsNothing);
    expect(find.textContaining('IRON-0005'), findsNothing);
    expect(service.statusUpdates, isEmpty);
    expect(service.ordersData, hasLength(5));
  });

  testWidgets('dashboard and orders remain RTL without narrow-width overflow', (
    tester,
  ) async {
    final service = _FakeOperationsService(
      dashboardData: _dashboardData(orders, approved: 7),
      ordersData: orders,
    );

    await _setSurface(tester, const Size(375, 900));
    await _pumpDashboard(tester, service, configureSurface: false);
    expect(tester.takeException(), isNull);

    await _pumpOrders(
      tester,
      service,
      configureSurface: false,
      initialScope: AdminOrderScope.active,
    );
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('admin-orders-search')),
    );
    expect(field.textDirection, TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });
}

Map<String, dynamic> _order(
  String id,
  String number,
  String status, {
  required String customer,
}) => {
  'id': id,
  'order_number': number,
  'customer_name': customer,
  'phone': '0912345678',
  'city': 'طرابلس',
  'address': 'عنوان تجريبي',
  'notes': '',
  'subtotal_lyd': 100,
  'discount_amount_lyd': 0,
  'total_lyd': 100,
  'customer_discount_percent': 0,
  'athlete_commission_percent': 0,
  'athlete_commission_amount_lyd': 0,
  'commission_status': 'void',
  'status': status,
  'created_at': '2026-09-13T10:00:00.000Z',
  'order_items': <Map<String, dynamic>>[],
};

Map<String, dynamic> _dashboardData(
  List<Map<String, dynamic>> source, {
  required double approved,
}) {
  final active = dashboardActiveOrdersFromRows(source);
  return {
    'orders_today': source.length,
    'active_orders_count': active.length,
    'active_orders': active,
    'pending': source.where((row) => row['status'] == 'pending').length,
    'low_stock': 1,
    'out_of_stock': 1,
    'approved_commissions': approved,
  };
}

Future<void> _pumpDashboard(
  WidgetTester tester,
  _FakeOperationsService service, {
  VoidCallback? onOpenSportsCodes,
  void Function(AdminOrderScope, String)? onOpenOrders,
  bool settle = true,
  bool configureSurface = true,
}) async {
  if (configureSurface) await _setSurface(tester, const Size(1100, 900));
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: AdminDashboardView(
            service: service,
            onOpenOrders: onOpenOrders ?? (_, _) {},
            onOpenSportsCodes: onOpenSportsCodes ?? () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  if (settle) await tester.pumpAndSettle();
}

Future<void> _pumpOrders(
  WidgetTester tester,
  _FakeOperationsService service, {
  AdminOrderScope initialScope = AdminOrderScope.active,
  bool configureSurface = true,
}) async {
  if (configureSurface) await _setSurface(tester, const Size(1100, 900));
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: AdminOrdersView(
            service: service,
            onChanged: () {},
            initialScope: initialScope,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

class _FakeOperationsService implements AdminOperationsService {
  _FakeOperationsService({
    required this.dashboardData,
    required this.ordersData,
    this.dashboardFuture,
    this.dashboardError = false,
  });

  final Map<String, dynamic> dashboardData;
  final List<Map<String, dynamic>> ordersData;
  final Future<Map<String, dynamic>>? dashboardFuture;
  final bool dashboardError;
  final List<(String, String)> statusUpdates = [];

  @override
  Future<Map<String, dynamic>> dashboard() {
    if (dashboardError) return Future.error(StateError('raw_postgrest_error'));
    return dashboardFuture ??
        Future.value(Map<String, dynamic>.from(dashboardData));
  }

  @override
  Future<List<Map<String, dynamic>>> orders() => Future.value(
    ordersData.map((row) => Map<String, dynamic>.from(row)).toList(),
  );

  @override
  Future<void> updateCommissionStatus(String orderId, String status) async {}

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    statusUpdates.add((orderId, status));
    final row = ordersData.firstWhere((item) => item['id'] == orderId);
    row['status'] = status;
  }
}
