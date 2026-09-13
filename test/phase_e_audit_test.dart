import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsam09/main.dart';
import 'package:ironsam09/widgets/catalog_widgets.dart';

void main() {
  testWidgets('Phase E customer flow survives the launch viewport matrix', (
    tester,
  ) async {
    const viewports = <Size>[
      Size(320, 568),
      Size(360, 640),
      Size(375, 667),
      Size(390, 844),
      Size(393, 873),
      Size(412, 915),
      Size(430, 932),
      Size(768, 900),
      Size(1024, 800),
      Size(1280, 900),
      Size(1440, 900),
      Size(1920, 1080),
    ];
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.view.resetPadding();
    });

    for (final viewport in viewports) {
      tester.view.padding = viewport.width < 768
          ? const FakeViewPadding(top: 24, bottom: 16)
          : FakeViewPadding.zero;
      await tester.binding.setSurfaceSize(viewport);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Catalog overflow at $viewport',
      );

      final detailsStore = StoreState();
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailsPage(
            product: products.first,
            store: detailsStore,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Product details overflow at $viewport',
      );

      final orderStore = StoreState()..add(products.first, size: 'M');
      await tester.pumpWidget(MaterialApp(home: CartPage(store: orderStore)));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Cart overflow at $viewport',
      );

      await tester.pumpWidget(
        MaterialApp(home: CheckoutPage(store: orderStore)),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Checkout overflow at $viewport',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      detailsStore.dispose();
      orderStore.dispose();
    }
  });

  testWidgets('customer flow tolerates enlarged text on a narrow phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = StoreState()..add(products.first, size: 'M');
    addTearDown(store.dispose);

    Widget withLargeText(Widget child) => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.3)),
        child: child!,
      ),
      home: child,
    );

    for (final page in <Widget>[
      CollectionsPage(store: store),
      ProductDetailsPage(product: products.first, store: store),
      CartPage(store: store),
      CheckoutPage(store: store),
    ]) {
      await tester.pumpWidget(withLargeText(page));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${page.runtimeType} overflowed with enlarged text',
      );
    }
  });

  testWidgets('rotating Hero pauses while its ticker subtree is disabled', (
    tester,
  ) async {
    const firstUrl = 'https://images.example.com/phase-e-one.jpg';
    const secondUrl = 'https://images.example.com/phase-e-two.jpg';
    const heroProducts = [
      Product(
        name: 'الأول',
        category: 'اختبار',
        gender: 'للجنسين',
        price: 100,
        sizes: 'M',
        status: 'متوفر',
        imageUrl: firstUrl,
      ),
      Product(
        name: 'الثاني',
        category: 'اختبار',
        gender: 'للجنسين',
        price: 100,
        sizes: 'M',
        status: 'متوفر',
        imageUrl: secondUrl,
      ),
    ];

    Widget hero({required bool tickerEnabled}) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: TickerMode(
            enabled: tickerEnabled,
            child: SizedBox(
              width: 390,
              child: PageIntro(
                title: 'الكل',
                heroProducts: heroProducts,
                onShopPressed: _noop,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(hero(tickerEnabled: true));
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey(secondUrl)), findsOneWidget);

    await tester.pumpWidget(hero(tickerEnabled: false));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const ValueKey(secondUrl)), findsOneWidget);
    expect(find.byKey(const ValueKey(firstUrl)), findsNothing);

    await tester.pumpWidget(hero(tickerEnabled: true));
    await tester.pump(const Duration(milliseconds: 2499));
    expect(find.byKey(const ValueKey(secondUrl)), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const ValueKey(firstUrl)), findsOneWidget);
  });
}

void _noop() {}
