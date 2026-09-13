import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsam09/admin/admin_panel.dart';
import 'package:ironsam09/admin/admin_service.dart';
import 'package:ironsam09/admin/admin_widgets.dart';

void main() {
  const codeId = 'code-1';

  testWidgets('edit write succeeds and protected refresh succeeds', (
    tester,
  ) async {
    final service = _FakeAdminService([_discountRow(id: codeId)]);
    await _pumpDiscountCodes(tester, service);

    await _editCode(tester, id: codeId, code: 'UPDATED');

    expect(service.events, ['list', 'edit:$codeId', 'list']);
    expect(find.text('UPDATED'), findsOneWidget);
    expect(find.text('STAGE10'), findsNothing);
    await _finishTest(tester);
  });

  testWidgets('edit write succeeds and refresh failure stays separate', (
    tester,
  ) async {
    final service = _FakeAdminService([_discountRow(id: codeId)]);
    await _pumpDiscountCodes(tester, service);
    service.failNextList = true;

    await _editCode(tester, id: codeId, code: 'UPDATED');

    expect(service.events, ['list', 'edit:$codeId', 'list']);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('UPDATED'), findsOneWidget);
    expect(find.text(adminDiscountRefreshFailureMessage), findsOneWidget);
    expect(find.text(adminDiscountWriteFailureMessage), findsNothing);
    await _finishTest(tester);
  });

  testWidgets('toggle succeeds, refreshes, and updates the status badge', (
    tester,
  ) async {
    final service = _FakeAdminService([_discountRow(id: codeId)]);
    await _pumpDiscountCodes(tester, service);

    await tester.tap(
      find.byKey(const ValueKey('discount-code-toggle-$codeId')),
    );
    await _pumpAction(tester);

    final badge = tester.widget<AdminStatusBadge>(
      find.byKey(const ValueKey('discount-code-status-$codeId')),
    );
    expect(service.events, ['list', 'toggle:$codeId:false', 'list']);
    expect(badge.label, 'متوقف');
    await _finishTest(tester);
  });

  testWidgets('delete succeeds, refreshes, and removes the visible row', (
    tester,
  ) async {
    final service = _FakeAdminService([_discountRow(id: codeId)]);
    await _pumpDiscountCodes(tester, service);

    await tester.tap(
      find.byKey(const ValueKey('discount-code-delete-$codeId')),
    );
    await _pumpAction(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'حذف'));
    await _pumpAction(tester);

    expect(service.events, ['list', 'delete:$codeId', 'list']);
    expect(
      find.byKey(const ValueKey('discount-code-row-$codeId')),
      findsNothing,
    );
    await _finishTest(tester);
  });

  testWidgets('successful toggle is not reported failed when refresh fails', (
    tester,
  ) async {
    final service = _FakeAdminService([_discountRow(id: codeId)]);
    await _pumpDiscountCodes(tester, service);
    service.failNextList = true;

    await tester.tap(
      find.byKey(const ValueKey('discount-code-toggle-$codeId')),
    );
    await _pumpAction(tester);

    final badge = tester.widget<AdminStatusBadge>(
      find.byKey(const ValueKey('discount-code-status-$codeId')),
    );
    expect(badge.label, 'متوقف');
    expect(find.text(adminDiscountRefreshFailureMessage), findsOneWidget);
    expect(find.text(adminDiscountWriteFailureMessage), findsNothing);
    await _finishTest(tester);
  });

  testWidgets('sports-code list updates without a browser reload', (
    tester,
  ) async {
    final service = _FakeAdminService([_discountRow(id: codeId)]);
    await _pumpDiscountCodes(tester, service);
    final originalView = tester.element(find.byType(AdminDiscountsView));

    await _editCode(tester, id: codeId, code: 'LIVE20');

    expect(tester.element(find.byType(AdminDiscountsView)), same(originalView));
    expect(find.text('LIVE20'), findsOneWidget);
    expect(service.listCalls, 2);
    await _finishTest(tester);
  });
}

Map<String, dynamic> _discountRow({required String id}) => {
  'id': id,
  'code': 'STAGE10',
  'active': true,
  'expires_at': '2030-01-01T00:00:00.000Z',
  'customer_discount_percent': 5.0,
  'athlete_commission_percent': 3.0,
  'influencers': {'name': 'ahmed7'},
};

Future<void> _pumpDiscountCodes(
  WidgetTester tester,
  _FakeAdminService service,
) async {
  await tester.binding.setSurfaceSize(const Size(1100, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: AdminDiscountsView(service: service)),
    ),
  );
  await _pumpAction(tester);
}

Future<void> _editCode(
  WidgetTester tester, {
  required String id,
  required String code,
}) async {
  await tester.tap(find.byKey(ValueKey('discount-code-edit-$id')));
  await _pumpAction(tester);
  await tester.enterText(
    find.byKey(const ValueKey('discount-code-code-field')),
    code,
  );
  await tester.tap(find.byKey(const ValueKey('discount-code-save')));
  await _pumpAction(tester);
}

Future<void> _pumpAction(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _finishTest(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 5));
}

class _FakeAdminService implements AdminDiscountCodesService {
  _FakeAdminService(List<Map<String, dynamic>> rows)
    : rows = rows.map(_copyRow).toList();

  final List<Map<String, dynamic>> rows;
  final List<String> events = [];
  bool failNextList = false;
  int listCalls = 0;

  @override
  Future<List<PayableCommissionGroup>> payableCommissions() async => const [];

  @override
  Future<List<Map<String, dynamic>>> discounts() async {
    events.add('list');
    listCalls++;
    if (failNextList) {
      failNextList = false;
      throw StateError('admin_list_discount_codes failed');
    }
    return rows.map(_copyRow).toList();
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
  }) async {
    events.add('${id == null ? 'create' : 'edit'}:${id ?? 'new'}');
    final row = id == null
        ? <String, dynamic>{'id': 'created-code'}
        : rows.singleWhere((candidate) => candidate['id'] == id);
    row.addAll({
      'code': code,
      'active': active,
      'expires_at': expiresAt?.toIso8601String(),
      'customer_discount_percent': customerDiscountPercent,
      'athlete_commission_percent': athleteCommissionPercent,
      'influencers': influencerName == null || influencerName.isEmpty
          ? null
          : {'name': influencerName},
    });
    if (id == null) rows.add(row);
  }

  @override
  Future<void> setDiscountActive(String discountId, bool active) async {
    events.add('toggle:$discountId:$active');
    rows.singleWhere((row) => row['id'] == discountId)['active'] = active;
  }

  @override
  Future<void> deleteDiscount(String discountId) async {
    events.add('delete:$discountId');
    rows.removeWhere((row) => row['id'] == discountId);
  }

  @override
  Future<DiscountPerformance> discountPerformance(String code) async =>
      const DiscountPerformance.empty();

  @override
  Future<Map<String, dynamic>> markInfluencerCommissionsPaid(
    String influencerId,
  ) async => <String, dynamic>{};
}

Map<String, dynamic> _copyRow(Map<String, dynamic> row) => {
  ...row,
  if (row['influencers'] is Map)
    'influencers': Map<String, dynamic>.from(row['influencers'] as Map),
};
