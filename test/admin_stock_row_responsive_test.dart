import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsam09/admin/admin_widgets.dart';

void main() {
  testWidgets('admin stock row keeps size and controls usable on mobile', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in <double>[320, 375, 430]) {
      await tester.binding.setSurfaceSize(Size(width, 300));
      var value = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: AdminVariantStockRow(
                  sizeLabel: 'XL',
                  sizeLabelKey: const ValueKey('tested-size-label'),
                  value: value,
                  statusLabel: 'مخزون منخفض',
                  statusTone: AdminStatusTone.warning,
                  onChanged: (next) => value = next,
                  onRemove: () {},
                ),
              ),
            ),
          ),
        ),
      );

      final sizeLabel = find.byKey(const ValueKey('tested-size-label'));
      expect(sizeLabel, findsOneWidget, reason: 'missing at $width px');
      expect(tester.getSize(sizeLabel).width, greaterThan(0));
      expect(find.text('مخزون منخفض'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'overflow at $width px');

      for (final tooltip in ['إنقاص المخزون', 'زيادة المخزون']) {
        final button = find.byTooltip(tooltip);
        expect(button, findsOneWidget);
        final buttonSize = tester.getSize(button);
        expect(buttonSize.width, greaterThanOrEqualTo(44));
        expect(buttonSize.height, greaterThanOrEqualTo(44));
      }
    }
  });
}
