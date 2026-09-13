import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsam09/admin/admin_panel.dart';
import 'package:ironsam09/admin/admin_service.dart';

void main() {
  test('the exact 7 LYD payable is one delivered approved athlete order', () {
    final rows = _commissionRows();

    final payable = payableCommissionGroupsFromRows(rows);
    final dashboardTotals = adminCommissionTotalsFromRows(rows);

    expect(payable, hasLength(1));
    expect(payable.single.influencerId, 'athlete-7');
    expect(payable.single.orders.single.orderNumber, 'IRON-0007');
    expect(payable.single.amount, 7);
    expect(dashboardTotals.approved, 7);
  });

  test(
    'pending, paid, undelivered, and ownerless commissions are excluded',
    () {
      final rows = _commissionRows();

      expect(payableCommissionTotalFromRows(rows), 7);
      expect(rows.where(isAdminPayableCommissionRow).map((row) => row['id']), [
        'order-7',
      ]);
    },
  );

  test('dashboard and Sports Codes use the same payable total', () {
    final rows = _commissionRows();
    final sportsCodesTotal = payableCommissionGroupsFromRows(
      rows,
    ).fold<double>(0, (sum, group) => sum + group.amount);

    expect(adminCommissionTotalsFromRows(rows).approved, sportsCodesTotal);
    expect(sportsCodesTotal, 7);
  });

  test('missing deleted-code snapshot stays attributable to its athlete', () {
    final group = payableCommissionGroupsFromRows(
      _commissionRows(discountCode: null),
    ).single;

    expect(group.influencerName, 'أحمد الرياضي');
    expect(group.codes, isEmpty);
    expect(group.orders.single.discountCode, isNull);
    expect(group.orders.single.orderNumber, 'IRON-0007');
  });

  test(
    'payout moves approved value into paid history without changing total',
    () {
      const before = DiscountPerformance(
        uses: 3,
        sales: 300,
        commission: CommissionTotals(pending: 3, approved: 7, paid: 11),
        influencerId: 'athlete-7',
      );

      final after = before.withApprovedMarkedPaid();

      expect(after.commission.pending, 3);
      expect(after.commission.approved, 0);
      expect(after.commission.paid, 18);
      expect(after.commission.total, before.commission.total);
    },
  );

  testWidgets('Sports Codes exposes a 7 LYD payable with no current code row', (
    tester,
  ) async {
    final service = _PayablesService(
      codeRows: const [],
      commissionRows: _commissionRows(discountCode: null),
    );

    await _pumpSportsCodes(tester, service);

    expect(
      find.byKey(const ValueKey('sports-codes-payable-section')),
      findsOneWidget,
    );
    expect(find.text('أحمد الرياضي'), findsOneWidget);
    expect(find.text('7 د.ل'), findsOneWidget);
    expect(find.textContaining('الرمز الأصلي غير متاح'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('payable-inspect-athlete-7')));
    await tester.pumpAndSettle();
    expect(find.text('IRON-0007'), findsOneWidget);
    expect(find.text('الرمز الأصلي غير متاح'), findsWidgets);
  });

  testWidgets('payable stays visible when its normal code is inactive', (
    tester,
  ) async {
    final service = _PayablesService(
      codeRows: [_discountRow(active: false)],
      commissionRows: _commissionRows(discountCode: 'OLD7'),
    );

    await _pumpSportsCodes(tester, service);

    expect(
      find.byKey(const ValueKey('sports-codes-payable-section')),
      findsOneWidget,
    );
    expect(find.textContaining('الرموز: OLD7'), findsOneWidget);
    expect(find.text('متوقف'), findsOneWidget);
  });

  testWidgets('successful payout clears payable and retains paid history', (
    tester,
  ) async {
    final service = _PayablesService(
      codeRows: [_discountRow(active: true)],
      commissionRows: _commissionRows(discountCode: 'OLD7'),
    );
    await _pumpSportsCodes(tester, service);

    await tester.tap(find.byKey(const ValueKey('payable-pay-athlete-7')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'تأكيد الدفع'),
      ),
    );
    await tester.pumpAndSettle();

    expect(service.payoutCalls, 1);
    expect(
      find.byKey(const ValueKey('sports-codes-payable-section')),
      findsNothing,
    );
    expect(payableCommissionTotalFromRows(service.commissionRows), 0);

    await tester.tap(
      find
          .descendant(
            of: find.byKey(const ValueKey('discount-code-row-code-old7')),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pumpAndSettle();

    final performance = await service.discountPerformance('OLD7');
    expect(performance.commission.approved, 0);
    expect(performance.commission.paid, 17);
    expect(find.text('تم دفعه سابقًا'), findsOneWidget);
    expect(find.text('17 د.ل'), findsOneWidget);
  });

  testWidgets('payout refresh failure is not reported as a write failure', (
    tester,
  ) async {
    final service = _PayablesService(
      codeRows: [_discountRow(active: true)],
      commissionRows: _commissionRows(discountCode: 'OLD7'),
      failRefreshAfterPayout: true,
    );
    await _pumpSportsCodes(tester, service);

    await tester.tap(find.byKey(const ValueKey('payable-pay-athlete-7')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'تأكيد الدفع'),
      ),
    );
    await tester.pumpAndSettle();

    expect(service.payoutCalls, 1);
    expect(find.text(adminDiscountRefreshFailureMessage), findsOneWidget);
    expect(find.text('تعذر تسجيل الدفع.'), findsNothing);
    expect(
      find.byKey(const ValueKey('sports-codes-payable-section')),
      findsNothing,
    );
  });
}

List<Map<String, dynamic>> _commissionRows({
  String? discountCode = 'STAGE10',
}) => [
  {
    'id': 'order-7',
    'order_number': 'IRON-0007',
    'discount_code': discountCode,
    'influencer_id': 'athlete-7',
    'influencers': {'name': 'أحمد الرياضي'},
    'status': 'delivered',
    'total_lyd': 100,
    'athlete_commission_amount_lyd': 7,
    'commission_status': 'approved',
  },
  {
    'id': 'order-pending',
    'order_number': 'IRON-0008',
    'discount_code': discountCode,
    'influencer_id': 'athlete-7',
    'influencers': {'name': 'أحمد الرياضي'},
    'status': 'confirmed',
    'total_lyd': 200,
    'athlete_commission_amount_lyd': 14,
    'commission_status': 'pending',
  },
  {
    'id': 'order-paid',
    'order_number': 'IRON-0009',
    'discount_code': discountCode,
    'influencer_id': 'athlete-7',
    'influencers': {'name': 'أحمد الرياضي'},
    'status': 'delivered',
    'total_lyd': 150,
    'athlete_commission_amount_lyd': 10,
    'commission_status': 'paid',
  },
  {
    'id': 'order-undelivered-approved',
    'order_number': 'IRON-0010',
    'discount_code': discountCode,
    'influencer_id': 'athlete-7',
    'influencers': {'name': 'أحمد الرياضي'},
    'status': 'confirmed',
    'total_lyd': 300,
    'athlete_commission_amount_lyd': 21,
    'commission_status': 'approved',
  },
  {
    'id': 'order-ownerless',
    'order_number': 'IRON-0011',
    'discount_code': discountCode,
    'influencer_id': null,
    'status': 'delivered',
    'total_lyd': 400,
    'athlete_commission_amount_lyd': 28,
    'commission_status': 'approved',
  },
];

Map<String, dynamic> _discountRow({required bool active}) => {
  'id': 'code-old7',
  'code': 'OLD7',
  'active': active,
  'expires_at': null,
  'customer_discount_percent': 5.0,
  'athlete_commission_percent': 7.0,
  'influencers': {'name': 'أحمد الرياضي'},
};

Future<void> _pumpSportsCodes(
  WidgetTester tester,
  _PayablesService service,
) async {
  await tester.binding.setSurfaceSize(const Size(1100, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: AdminDiscountsView(service: service)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _PayablesService implements AdminDiscountCodesService {
  _PayablesService({
    required List<Map<String, dynamic>> codeRows,
    required List<Map<String, dynamic>> commissionRows,
    this.failRefreshAfterPayout = false,
  }) : codeRows = codeRows.map(_copy).toList(),
       commissionRows = commissionRows.map(_copy).toList();

  final List<Map<String, dynamic>> codeRows;
  final List<Map<String, dynamic>> commissionRows;
  final bool failRefreshAfterPayout;
  bool _failNextDiscounts = false;
  int payoutCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> discounts() async {
    if (_failNextDiscounts) {
      _failNextDiscounts = false;
      throw StateError('refresh failed');
    }
    return codeRows.map(_copy).toList();
  }

  @override
  Future<List<PayableCommissionGroup>> payableCommissions() async =>
      payableCommissionGroupsFromRows(commissionRows);

  @override
  Future<DiscountPerformance> discountPerformance(String code) async =>
      discountPerformanceFromRows(commissionRows, code);

  @override
  Future<Map<String, dynamic>> markInfluencerCommissionsPaid(
    String influencerId,
  ) async {
    payoutCalls++;
    var ordersPaid = 0;
    var totalPaid = 0.0;
    for (final row in commissionRows) {
      if (row['influencer_id'] == influencerId &&
          isAdminPayableCommissionRow(row)) {
        row['commission_status'] = 'paid';
        ordersPaid++;
        totalPaid +=
            (row['athlete_commission_amount_lyd'] as num?)?.toDouble() ?? 0;
      }
    }
    if (failRefreshAfterPayout) _failNextDiscounts = true;
    return {'orders_paid': ordersPaid, 'total_paid': totalPaid};
  }

  @override
  Future<void> saveDiscount({
    String? id,
    required String code,
    required bool active,
    String? influencerName,
    DateTime? expiresAt,
    required double customerDiscountPercent,
    required double athleteCommissionPercent,
  }) async {}

  @override
  Future<void> setDiscountActive(String discountId, bool active) async {}

  @override
  Future<void> deleteDiscount(String discountId) async {}
}

Map<String, dynamic> _copy(Map<String, dynamic> source) => {
  ...source,
  if (source['influencers'] is Map)
    'influencers': Map<String, dynamic>.from(source['influencers'] as Map),
};
