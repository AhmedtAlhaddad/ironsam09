import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsam09/main.dart';
import 'package:ironsam09/core/config/app_config.dart';
import 'package:ironsam09/core/theme/storefront_theme.dart';
import 'package:ironsam09/core/utils/image_url_policy.dart';
import 'package:ironsam09/core/utils/hex_color.dart';
import 'package:ironsam09/data/models/order.dart';
import 'package:ironsam09/data/repositories/store_repository.dart';
import 'package:ironsam09/admin/admin_service.dart';
import 'package:ironsam09/admin/admin_widgets.dart';
import 'package:ironsam09/widgets/catalog_widgets.dart';
import 'package:ironsam09/widgets/safe_product_image.dart';

void main() {
  test('release builds require a configured Supabase backend', () {
    expect(
      AppConfig.requiresSupabase(isReleaseBuild: true, configured: false),
      isTrue,
    );
    expect(
      AppConfig.requiresSupabase(isReleaseBuild: true, configured: true),
      isFalse,
    );
    expect(
      AppConfig.requiresSupabase(isReleaseBuild: false, configured: false),
      isFalse,
    );
  });

  test('admin theme keeps semantic colors centralized', () {
    final theme = adminTheme(ThemeData());

    expect(theme.scaffoldBackgroundColor, AdminColors.background);
    expect(theme.colorScheme.primary, AdminColors.primary);
    expect(theme.colorScheme.error, AdminColors.danger);
    expect(theme.dialogTheme.backgroundColor, AdminColors.surface);
    expect(theme.inputDecorationTheme.fillColor, AdminColors.surface);
  });

  test('product image policy only permits safe HTTPS URLs', () {
    expect(
      safeProductImageUrl('https://images.example.com/item.jpg'),
      isNotNull,
    );
    expect(safeProductImageUrl('http://images.example.com/item.jpg'), isNull);
    expect(safeProductImageUrl('javascript:alert(1)'), isNull);
    expect(safeProductImageUrl('data:image/png;base64,abc'), isNull);
    expect(safeProductImageUrl('file:///tmp/item.jpg'), isNull);
  });

  test('color hex metadata accepts only standard six-digit values', () {
    expect(colorFromHex('#000000'), const Color(0xFF000000));
    expect(colorFromHex('#C62828'), const Color(0xFFC62828));
    expect(colorFromHex('FFFFFF'), isNull);
    expect(colorFromHex('#FFF'), isNull);
    expect(colorFromHex('#GGGGGG'), isNull);
  });

  test('one active color is selected without requiring a color choice', () {
    const product = Product(
      name: 'Single color',
      category: 'Test',
      gender: 'Test',
      price: 100,
      sizes: 'M',
      status: 'Available',
      imageUrl: '',
      colors: [ProductColor(id: 'black', nameAr: 'Black', hexCode: '#000000')],
      variants: [ProductVariant(colorId: 'black', size: 'M', stockQuantity: 1)],
    );
    final store = StoreState();

    expect(store.colorFor(product), 'black');
    expect(store.stockFor(product), 1);
    store.dispose();
  });

  test(
    'color galleries prefer dedicated images and fall back to global ones',
    () {
      const product = Product(
        name: 'Gallery test',
        category: 'Test',
        gender: 'Test',
        price: 100,
        sizes: 'M',
        status: 'Available',
        imageUrl: 'https://example.com/fallback.jpg',
        images: [
          ProductImage(id: 'global-1', url: 'https://example.com/global-1.jpg'),
          ProductImage(
            id: 'black-1',
            colorId: 'black',
            url: 'https://example.com/black-1.jpg',
          ),
        ],
        colors: [
          ProductColor(id: 'black', nameAr: 'Black', hexCode: '#000000'),
          ProductColor(id: 'white', nameAr: 'White', hexCode: '#FFFFFF'),
        ],
      );

      expect(product.imagesForColor('black').single.id, 'black-1');
      expect(product.imagesForColor('white').single.id, 'global-1');
    },
  );

  testWidgets('catalog cards do not show size metadata', (tester) async {
    const product = Product(
      name: 'Catalog product',
      category: 'Category metadata',
      gender: 'Gender metadata',
      price: 100,
      sizes: 'S - XL',
      status: 'Available',
      imageUrl: '',
      colors: [ProductColor(id: 'black', nameAr: 'Black')],
    );
    final store = StoreState();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: ProductCard(product: product, store: store),
          ),
        ),
      ),
    );

    expect(find.text('Catalog product'), findsOneWidget);
    expect(find.text('S - XL'), findsNothing);
    expect(find.text('Category metadata'), findsNothing);
    expect(find.text('Gender metadata'), findsNothing);
    expect(find.text('Black'), findsNothing);
    expect(find.byIcon(Icons.favorite_outline), findsNothing);
    expect(find.byIcon(Icons.add_shopping_cart), findsNothing);
  });

  testWidgets('color swatches use real hex values and switch selection', (
    tester,
  ) async {
    const product = Product(
      name: 'Swatch test',
      category: 'Test',
      gender: 'Test',
      price: 100,
      sizes: 'M - L',
      status: 'Available',
      imageUrl: '',
      colors: [
        ProductColor(id: 'black', nameAr: 'Black', hexCode: '#000000'),
        ProductColor(id: 'white', nameAr: 'White', hexCode: '#FFFFFF'),
      ],
      variants: [
        ProductVariant(colorId: 'black', size: 'M', stockQuantity: 1),
        ProductVariant(colorId: 'white', size: 'L', stockQuantity: 1),
      ],
    );
    final store = StoreState();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailsPage(product: product, store: store),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('product-color-swatch-black')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('product-color-swatch-white')),
      findsOneWidget,
    );
    final whiteSwatch = find.byKey(
      const ValueKey('product-color-swatch-white'),
    );
    await tester.ensureVisible(whiteSwatch);
    await tester.tap(whiteSwatch);
    await tester.pumpAndSettle();

    expect(store.colorFor(product), 'white');
    expect(product.stockFor('M', colorId: 'white'), 0);
    expect(product.stockFor('L', colorId: 'white'), 1);
  });

  testWidgets('product details cart is physical top-right on mobile RTL', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = StoreState();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailsPage(product: products.first, store: store),
      ),
    );
    await tester.pumpAndSettle();

    final cart = find.byKey(const ValueKey('product-details-cart'));
    final cartRect = tester.getRect(cart);
    expect(cartRect.right, greaterThan(350));
    expect(cartRect.top, lessThan(80));

    await tester.tap(
      find.descendant(
        of: cart,
        matching: find.byIcon(Icons.shopping_bag_outlined),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CartPage), findsOneWidget);
  });

  testWidgets('product details cart is physical top-right on desktop RTL', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = StoreState();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailsPage(product: products.first, store: store),
      ),
    );
    await tester.pumpAndSettle();

    final cartRect = tester.getRect(
      find.byKey(const ValueKey('product-details-cart')),
    );
    expect(cartRect.center.dx, greaterThan(1100));
    expect(cartRect.top, lessThan(80));
  });

  testWidgets('product details uses intentional responsive compositions', (
    tester,
  ) async {
    final store = StoreState();
    addTearDown(store.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final width in <double>[320, 390, 768]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: width == 320
                  ? const TextScaler.linear(1.3)
                  : TextScaler.noScaling,
            ),
            child: child!,
          ),
          home: ProductDetailsPage(product: products.first, store: store),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('product-details-mobile-layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('product-details-desktop-layout')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    }

    for (final width in <double>[1024, 1440]) {
      await tester.binding.setSurfaceSize(Size(width, 1000));
      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailsPage(product: products.first, store: store),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('product-details-desktop-layout')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('product gallery controls and color fallback reset safely', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const product = Product(
      name: 'Gallery controls',
      category: 'Test',
      gender: 'Test',
      price: 100,
      sizes: 'M',
      status: 'Available',
      imageUrl: '',
      images: [
        ProductImage(id: 'global', url: 'https://example.com/global.jpg'),
        ProductImage(
          id: 'black-1',
          colorId: 'black',
          url: 'https://example.com/black-1.jpg',
        ),
        ProductImage(
          id: 'black-2',
          colorId: 'black',
          url: 'https://example.com/black-2.jpg',
        ),
      ],
      colors: [
        ProductColor(id: 'black', nameAr: 'أسود', hexCode: '#000000'),
        ProductColor(id: 'white', nameAr: 'أبيض', hexCode: '#FFFFFF'),
      ],
      variants: [
        ProductVariant(colorId: 'black', size: 'M', stockQuantity: 2),
        ProductVariant(colorId: 'white', size: 'M', stockQuantity: 2),
      ],
    );
    final store = StoreState();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailsPage(product: product, store: store),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('product-color-swatch-black')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('product-gallery-next')), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('product-gallery-dot-0')))
          .height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.byKey(const ValueKey('product-gallery-next')));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('product-color-swatch-white')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('product-gallery-next')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('size selector exposes unavailable variants as disabled', (
    tester,
  ) async {
    const product = Product(
      name: 'Size availability',
      category: 'Test',
      gender: 'Test',
      price: 100,
      sizes: 'M - L',
      status: 'Available',
      imageUrl: '',
      colors: [ProductColor(id: 'black', nameAr: 'أسود', hexCode: '#000000')],
      variants: [
        ProductVariant(colorId: 'black', size: 'M', stockQuantity: 0),
        ProductVariant(colorId: 'black', size: 'L', stockQuantity: 2),
      ],
    );
    final store = StoreState();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailsPage(product: product, store: store),
      ),
    );
    await tester.pumpAndSettle();

    final unavailable = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('product-size-M')),
    );
    final available = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('product-size-L')),
    );
    expect(unavailable.onSelected, isNull);
    expect(available.onSelected, isNotNull);
  });

  testWidgets('failed product images retain their accessible label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SafeProductImage(
            url: null,
            semanticLabel: 'صورة منتج الاختبار',
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('صورة منتج الاختبار'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('collections page renders the approved storefront flow', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('الكل'), findsNWidgets(2));
    expect(find.text('توصيل إلى جميع أنحاء ليبيا'), findsOneWidget);
    final catalogCta = find.widgetWithText(FilledButton, 'تسوق التشكيلة');
    await tester.ensureVisible(catalogCta);
    await tester.pumpAndSettle();
    await tester.tap(catalogCta);
    await tester.pumpAndSettle();
    expect(find.text('تيشيرت الأداء الأساسي'), findsOneWidget);
  });

  testWidgets('catalog never presents an empty state while loading or failed', (
    tester,
  ) async {
    final store = StoreState();
    addTearDown(store.dispose);

    Widget state({required bool loading, String? error}) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SingleChildScrollView(
            child: CatalogResults(
              isLoading: loading,
              error: error,
              products: const [],
              store: store,
              hasActiveFilter: false,
              onRetry: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(state(loading: true));
    expect(find.byKey(const ValueKey('catalog-loading-state')), findsOneWidget);
    expect(find.text('لا توجد منتجات حاليًا'), findsNothing);

    await tester.pumpWidget(state(loading: false, error: 'تعذر التحميل'));
    expect(find.byKey(const ValueKey('catalog-error-state')), findsOneWidget);
    expect(find.text('تعذّر تحميل المنتجات'), findsOneWidget);
    expect(find.text('لا توجد منتجات حاليًا'), findsNothing);
  });

  testWidgets('catalog uses distinct mobile and desktop hero compositions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('catalog-hero-mobile')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(1100, 800));
    await tester.pump();
    expect(find.byKey(const ValueKey('catalog-hero-desktop')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Hero image sources are safe, representative, and deduplicated', () {
    const primaryUrl = 'https://images.example.com/primary.jpg';
    const secondaryUrl = 'https://images.example.com/secondary.jpg';
    const products = [
      Product(
        name: 'الأول',
        category: 'اختبار',
        gender: 'للجنسين',
        price: 100,
        sizes: 'M',
        status: 'متوفر',
        imageUrl: primaryUrl,
        imageUrls: [secondaryUrl],
      ),
      Product(
        name: 'مكرر',
        category: 'اختبار',
        gender: 'للجنسين',
        price: 100,
        sizes: 'M',
        status: 'متوفر',
        imageUrl: '  https://images.example.com/primary.jpg  ',
      ),
      Product(
        name: 'بديل',
        category: 'اختبار',
        gender: 'للجنسين',
        price: 100,
        sizes: 'M',
        status: 'متوفر',
        imageUrl: '',
        imageUrls: ['http://unsafe.example.com/image.jpg', secondaryUrl],
      ),
      Product(
        name: 'بلا صورة',
        category: 'اختبار',
        gender: 'للجنسين',
        price: 100,
        sizes: 'M',
        status: 'متوفر',
        imageUrl: 'javascript:alert(1)',
      ),
    ];

    final sources = buildHeroImageSources(products);

    expect(sources.map((source) => source.url), [primaryUrl, secondaryUrl]);
    expect(sources.map((source) => source.productName), ['الأول', 'بديل']);
    expect(buildHeroImageSources([products.last]), isEmpty);
  });

  testWidgets('Hero image rotation handles zero, one, and multiple images', (
    tester,
  ) async {
    const firstUrl = 'https://images.example.com/hero-one.jpg';
    const secondUrl = 'https://images.example.com/hero-two.jpg';
    const first = Product(
      name: 'الأول',
      category: 'اختبار',
      gender: 'للجنسين',
      price: 100,
      sizes: 'M',
      status: 'متوفر',
      imageUrl: firstUrl,
    );
    const second = Product(
      name: 'الثاني',
      category: 'اختبار',
      gender: 'للجنسين',
      price: 100,
      sizes: 'M',
      status: 'متوفر',
      imageUrl: secondUrl,
    );

    Widget hero(List<Product> products, {bool reducedMotion = false}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 844),
            disableAnimations: reducedMotion,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 390,
                  child: PageIntro(
                    title: 'الكل',
                    heroProducts: products,
                    onShopPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(hero(const []));
    expect(find.byKey(const ValueKey('hero-image-fallback')), findsOneWidget);

    await tester.pumpWidget(hero(const [first]));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const ValueKey(firstUrl)), findsOneWidget);
    expect(find.byKey(const ValueKey(secondUrl)), findsNothing);

    await tester.pumpWidget(hero(const [first, second]));
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpWidget(hero(const [first, second]));
    await tester.pump(const Duration(milliseconds: 499));
    expect(find.byKey(const ValueKey(firstUrl)), findsOneWidget);
    expect(find.byKey(const ValueKey(secondUrl)), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const ValueKey(secondUrl)), findsOneWidget);
    expect(find.byKey(const ValueKey(firstUrl)), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey(firstUrl)), findsNothing);

    await tester.pumpWidget(hero(const [first, second], reducedMotion: true));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const ValueKey(firstUrl)), findsOneWidget);
    expect(find.byKey(const ValueKey(secondUrl)), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile hero CTA is visible above the fold on supported phones', (
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
    ];
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.view.resetPadding();
    });

    for (final viewport in viewports) {
      final safePadding = viewport == const Size(320, 568)
          ? const FakeViewPadding(top: 24, bottom: 16)
          : FakeViewPadding.zero;
      tester.view.padding = safePadding;
      await tester.binding.setSurfaceSize(viewport);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final cta = find.byKey(const ValueKey('catalog-hero-cta'));
      final image = find.byKey(const ValueKey('catalog-hero-mobile-image'));
      expect(cta, findsOneWidget, reason: 'CTA missing at $viewport');
      expect(
        image,
        findsOneWidget,
        reason: 'Mobile image missing at $viewport',
      );

      final ctaRect = tester.getRect(cta);
      final imageRect = tester.getRect(image);
      expect(
        ctaRect.top,
        greaterThanOrEqualTo(safePadding.top),
        reason: 'CTA overlaps the safe area at $viewport',
      );
      expect(
        ctaRect.bottom,
        lessThanOrEqualTo(viewport.height),
        reason: 'CTA falls below the initial viewport at $viewport: $ctaRect',
      );
      expect(
        ctaRect.bottom,
        lessThanOrEqualTo(imageRect.top),
        reason: 'Supporting image precedes the CTA at $viewport',
      );
      expect(tester.takeException(), isNull, reason: 'Overflow at $viewport');
    }
  });

  testWidgets('product grid keeps responsive column counts', (tester) async {
    final store = StoreState();
    addTearDown(store.dispose);
    final gridProducts = List<Product>.generate(
      5,
      (index) => Product(
        name: 'Product $index',
        category: 'Test',
        gender: 'Test',
        price: 100,
        sizes: 'M',
        status: '',
        imageUrl: '',
      ),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final expectation in <(double, int)>[
      (320, 2),
      (768, 3),
      (1024, 4),
      (1440, 5),
    ]) {
      await tester.binding.setSurfaceSize(Size(expectation.$1, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProductGrid(products: gridProducts, store: store),
            ),
          ),
        ),
      );
      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, expectation.$2);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('adding a product updates the cart badge', (tester) async {
    final store = StoreState();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailsPage(product: products.first, store: store),
      ),
    );
    await tester.pumpAndSettle();
    final sizeButton = find.widgetWithText(ChoiceChip, 'M');
    await tester.ensureVisible(sizeButton);
    await tester.tap(sizeButton);
    await tester.pump();
    final addButton = find.text('إضافة إلى السلة');
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pump();

    expect(find.byKey(const ValueKey('product-details-cart')), findsOneWidget);
    expect(store.itemCount, 1);
    expect(find.text('تمت الإضافة إلى السلة'), findsOneWidget);
    expect(find.text('تمت الإضافة'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('تمت الإضافة إلى السلة'), findsNothing);
    expect(find.text('إضافة إلى السلة'), findsOneWidget);
  });

  testWidgets('adding a sized product requires a selected size', (
    tester,
  ) async {
    final store = StoreState();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailsPage(product: products.first, store: store),
      ),
    );
    await tester.pumpAndSettle();
    final addButton = find.text('إضافة إلى السلة');
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pump();

    expect(find.text('يرجى اختيار المقاس أولًا'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('يرجى اختيار المقاس أولًا'), findsNothing);
  });

  test('size range expands and selected size is stored in the cart', () {
    final product = products.first;
    final store = StoreState();

    expect(product.sizeOptions, ['S', 'M', 'L', 'XL']);

    store.selectSize(product, 'M');
    store.add(product);

    expect(store.sizeFor(product), 'M');
    expect(store.items.single.key, product);
    store.dispose();
  });

  test('cart keeps separate lines for the same product in different sizes', () {
    final product = products.first;
    final store = StoreState();

    store.add(product, size: 'M');
    store.add(product, size: 'L');
    store.add(product, size: 'M');

    expect(store.items, hasLength(2));
    expect(store.items.firstWhere((item) => item.size == 'M').quantity, 2);
    expect(store.items.firstWhere((item) => item.size == 'L').quantity, 1);

    store.remove(product, size: 'M');
    expect(store.items.firstWhere((item) => item.size == 'M').quantity, 1);
    store.remove(product, size: 'L');
    expect(store.items, hasLength(1));
    store.dispose();
  });

  test('cart never exceeds the stock of a variant', () {
    const product = Product(
      name: 'Limited',
      category: 'Test',
      gender: 'Test',
      price: 100,
      sizes: 'M',
      status: 'Available',
      imageUrl: '',
      variants: [ProductVariant(size: 'M', stockQuantity: 1)],
    );
    final store = StoreState();

    store.add(product, size: 'M');
    store.add(product, size: 'M');

    expect(store.items.single.quantity, 1);
    store.dispose();
  });

  test('colored variants keep same-size inventory and cart lines separate', () {
    const product = Product(
      id: 'shirt',
      name: 'Compression Shirt',
      category: 'Test',
      gender: 'Test',
      price: 100,
      sizes: 'S - M',
      status: 'Available',
      imageUrl: '',
      colors: [
        ProductColor(id: 'black', nameAr: 'أسود'),
        ProductColor(id: 'white', nameAr: 'أبيض'),
      ],
      variants: [
        ProductVariant(
          id: 'black-m',
          colorId: 'black',
          colorNameAr: 'أسود',
          size: 'M',
          stockQuantity: 1,
        ),
        ProductVariant(
          id: 'white-m',
          colorId: 'white',
          colorNameAr: 'أبيض',
          size: 'M',
          stockQuantity: 10,
        ),
      ],
    );
    final store = StoreState();

    store.add(product, colorId: 'black', size: 'M');
    store.add(product, colorId: 'white', size: 'M');

    expect(store.items, hasLength(2));
    expect(
      store.items.map((item) => item.variantId),
      containsAll(['black-m', 'white-m']),
    );
    expect(
      store.items.map((item) => item.colorName),
      containsAll(['أسود', 'أبيض']),
    );
    store.dispose();
  });

  test('changing color disables and clears an invalid selected size', () {
    const product = Product(
      name: 'Color Test',
      category: 'Test',
      gender: 'Test',
      price: 100,
      sizes: 'S - M',
      status: 'Available',
      imageUrl: '',
      colors: [
        ProductColor(id: 'black', nameAr: 'أسود'),
        ProductColor(id: 'white', nameAr: 'أبيض'),
      ],
      variants: [
        ProductVariant(colorId: 'black', size: 'M', stockQuantity: 2),
        ProductVariant(colorId: 'white', size: 'M', stockQuantity: 0),
        ProductVariant(colorId: 'white', size: 'S', stockQuantity: 2),
      ],
    );
    final store = StoreState();
    store.selectColor(product, 'black');
    store.selectSize(product, 'M');
    store.selectColor(product, 'white');

    expect(store.selectedSizeFor(product), isNull);
    expect(product.stockFor('M', colorId: 'white'), 0);
    expect(product.stockFor('S', colorId: 'white'), 2);
    store.dispose();
  });

  test(
    'discount values remain dynamic and commission is independent',
    () async {
      const validation = DiscountValidation(
        valid: true,
        customerDiscountPercent: 10,
      );
      expect(validation.amount(1000), 100);

      final local = await const LocalStoreRepository().validateDiscount(
        ' iron5 ',
      );
      expect(local.valid, isFalse);
      expect(local.customerDiscountPercent, 0);
    },
  );

  test('discount is stored on the cart for checkout summary use', () async {
    final store = StoreState();
    store.add(products.first, size: 'M');

    final validation = await store.applyDiscount('iron5');

    expect(validation.valid, isFalse);
    expect(store.discountCode, isNull);
    expect(store.discountPercent, 0);
    expect(store.discountAmount, 0);
    expect(store.total, store.subtotal);
    store.dispose();
  });

  test('commission totals separate pending, approved, and paid amounts', () {
    final before = commissionTotalsFromRows([
      {'commission_status': 'pending', 'athlete_commission_amount_lyd': 30},
      {'commission_status': 'approved', 'athlete_commission_amount_lyd': 100},
      {'commission_status': 'paid', 'athlete_commission_amount_lyd': 70},
      {'commission_status': 'void', 'athlete_commission_amount_lyd': 999},
    ]);

    expect(before.pending, 30);
    expect(before.approved, 100);
    expect(before.paid, 70);

    final after = commissionTotalsFromRows([
      {'commission_status': 'pending', 'athlete_commission_amount_lyd': 30},
      {'commission_status': 'paid', 'athlete_commission_amount_lyd': 100},
      {'commission_status': 'paid', 'athlete_commission_amount_lyd': 70},
    ]);
    expect(after.pending, 30);
    expect(after.approved, 0);
    expect(after.paid, 170);
  });

  test(
    'sports code performance filters one code and keeps payout states separate',
    () {
      final performance = discountPerformanceFromRows([
        {
          'discount_code': 'stage10',
          'influencer_id': 'athlete-1',
          'total_lyd': 270,
          'athlete_commission_amount_lyd': 21,
          'commission_status': 'pending',
        },
        {
          'discount_code': 'STAGE10',
          'influencer_id': 'athlete-1',
          'status': 'delivered',
          'total_lyd': 100,
          'athlete_commission_amount_lyd': 7,
          'commission_status': 'approved',
        },
        {
          'discount_code': 'STAGE10',
          'influencer_id': 'athlete-1',
          'total_lyd': 80,
          'athlete_commission_amount_lyd': 5,
          'commission_status': 'paid',
        },
        {
          'discount_code': 'STAGE10',
          'influencer_id': 'athlete-1',
          'total_lyd': 999,
          'athlete_commission_amount_lyd': 999,
          'commission_status': 'void',
        },
        {
          'discount_code': 'OTHER',
          'influencer_id': 'athlete-2',
          'status': 'delivered',
          'total_lyd': 500,
          'athlete_commission_amount_lyd': 50,
          'commission_status': 'approved',
        },
      ], ' stage10 ');

      expect(performance.uses, 4);
      expect(performance.sales, 1449);
      expect(performance.influencerId, 'athlete-1');
      expect(performance.commission.pending, 21);
      expect(performance.commission.approved, 7);
      expect(performance.commission.paid, 5);
      expect(performance.commission.total, 33);
    },
  );

  test('migration 009 scopes payouts to approved commissions', () {
    final sql = File(
      'supabase/migrations/009_commission_payout_tracking.sql',
    ).readAsStringSync();
    final rpcStart = sql.indexOf(
      'create or replace function public.admin_mark_influencer_commissions_paid',
    );
    expect(rpcStart, greaterThanOrEqualTo(0));
    final rpc = sql.substring(rpcStart);

    expect(sql, contains('commission_paid_at timestamptz null'));
    expect(rpc, contains('if not public.is_admin()'));
    expect(rpc, contains('where influencer_id = p_influencer_id'));
    expect(rpc, contains("commission_status = 'approved'"));
    expect(rpc, contains("status = 'delivered'"));
    expect(rpc, contains("commission_status = 'paid'"));
    expect(rpc, contains('commission_paid_at = now()'));
    expect(rpc, contains("'orders_paid'"));
    expect(rpc, contains("'total_paid'"));
    expect(rpc, isNot(contains('athlete_commission_amount_lyd = 0')));
    expect(
      sql,
      contains(
        'revoke execute on function public.admin_mark_influencer_commissions_paid(uuid)',
      ),
    );
  });

  testWidgets('men and women pages show their matching products', (
    tester,
  ) async {
    final store = StoreState();

    await tester.pumpWidget(MaterialApp(home: MenPage(store: store)));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('الرجال'), findsWidgets);
    expect(
      find.text('تيشيرت الأداء الأساسي', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('سترة ستوديو خفيفة', skipOffstage: false), findsNothing);

    await tester.pumpWidget(MaterialApp(home: WomenPage(store: store)));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('النساء'), findsWidgets);
    expect(find.text('سترة ستوديو خفيفة', skipOffstage: false), findsOneWidget);
    expect(
      find.text('تيشيرت الأداء الأساسي', skipOffstage: false),
      findsNothing,
    );
  });

  testWidgets('cart continues to checkout', (tester) async {
    final store = StoreState()..add(products.first);

    await tester.pumpWidget(MaterialApp(home: CartPage(store: store)));
    final checkoutButton = find.text('إتمام الطلب');
    await tester.ensureVisible(checkoutButton);
    await tester.tap(checkoutButton);
    await tester.pumpAndSettle();

    expect(find.text('إتمام الطلب'), findsWidgets);
    expect(find.text('١. معلومات التوصيل'), findsOneWidget);
    expect(find.text('تأكيد الطلب عبر واتساب'), findsOneWidget);
  });

  testWidgets('customer cart and checkout fit a narrow mobile viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = StoreState()..add(products.first, size: 'M');
    addTearDown(store.dispose);

    await tester.pumpWidget(MaterialApp(home: CartPage(store: store)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(MaterialApp(home: CheckoutPage(store: store)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Phase D cart and checkout adapt across storefront breakpoints', (
    tester,
  ) async {
    const viewports = <Size>[
      Size(320, 700),
      Size(390, 844),
      Size(768, 900),
      Size(1024, 800),
      Size(1440, 900),
    ];
    final store = StoreState()..add(products.first, size: 'M');
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      store.dispose();
    });

    for (final viewport in viewports) {
      await tester.binding.setSurfaceSize(viewport);
      await tester.pumpWidget(MaterialApp(home: CartPage(store: store)));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Cart overflow at $viewport',
      );

      await tester.pumpWidget(MaterialApp(home: CheckoutPage(store: store)));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('checkout-confirm-cta')),
        findsOneWidget,
        reason: 'Checkout must expose one primary CTA at $viewport',
      );
      expect(
        find.byKey(const ValueKey('mobile-checkout-bar')),
        viewport.width < 768 ? findsOneWidget : findsNothing,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Checkout overflow at $viewport',
      );
    }
  });

  testWidgets('mobile checkout CTA respects safe area and keyboard', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    tester.view.padding = const FakeViewPadding(bottom: 16);
    final store = StoreState()..add(products.first, size: 'M');
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.view.resetPadding();
      tester.view.resetViewInsets();
      store.dispose();
    });

    await tester.pumpWidget(MaterialApp(home: CheckoutPage(store: store)));
    await tester.pumpAndSettle();

    final bar = find.byKey(const ValueKey('mobile-checkout-bar'));
    expect(bar, findsOneWidget);
    expect(
      tester.getRect(bar).bottom,
      lessThanOrEqualTo(700),
      reason: 'Sticky CTA must remain inside the safe viewport',
    );
    expect(tester.takeException(), isNull);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(bar, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discount empty state is inline and accessible', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = StoreState()..add(products.first, size: 'M');
    addTearDown(store.dispose);

    await tester.pumpWidget(MaterialApp(home: CartPage(store: store)));
    final applyButton = find.byKey(const ValueKey('cart-discount-apply'));
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(find.text('أدخل كود الخصم أولًا.'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile menu opens navigation options', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('القائمة'), findsOneWidget);
    expect(find.text('سلة التسوق'), findsOneWidget);

    await tester.tap(find.text('الرجال'));
    await tester.pumpAndSettle();
    expect(find.byType(MenPage), findsOneWidget);
  });

  testWidgets('Hero visibility and spacing adapt at storefront breakpoints', (
    tester,
  ) async {
    const widths = <double>[320, 375, 768, 1024, 1440];
    final store = StoreState();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      store.dispose();
    });

    for (final width in widths) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(MaterialApp(home: CollectionsPage(store: store)));
      await tester.pump();

      final hero = find.byType(PageIntro);
      final heading = find.byType(CatalogSectionHeading);
      expect(hero, findsOneWidget, reason: 'Hero missing at $width px');
      expect(heading, findsOneWidget);
      expect(
        tester.getTopLeft(heading).dy - tester.getBottomLeft(hero).dy,
        StorefrontSpacing.lg,
        reason: 'Unexpected post-Hero gap at $width px',
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(MaterialApp(home: MenPage(store: store)));
      await tester.pump();
      expect(hero, findsNothing, reason: 'Men Hero remained at $width px');
      expect(heading, findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(MaterialApp(home: WomenPage(store: store)));
      await tester.pump();
      expect(hero, findsNothing, reason: 'Women Hero remained at $width px');
      expect(heading, findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('catalog spacing scrolls instead of occupying the viewport', (
    tester,
  ) async {
    const viewports = <Size>[Size(375, 800), Size(1280, 800)];
    final store = StoreState();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      store.dispose();
    });

    for (final viewport in viewports) {
      await tester.binding.setSurfaceSize(viewport);
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(viewport.width),
          home: CollectionsPage(store: store),
        ),
      );
      await tester.pump();

      final scrollView = find.byKey(const ValueKey('catalog-scroll-view'));
      final header = find.byType(StoreHeader);
      final scrollRect = tester.getRect(scrollView);
      final heroTop = tester.getTopLeft(find.byType(PageIntro)).dy;

      expect(scrollRect.top, tester.getRect(header).bottom);
      expect(heroTop - scrollRect.top, 6);
      expect(
        scrollRect.bottom,
        viewport.height,
        reason: 'No off-white gutter should remain fixed below the catalog.',
      );

      await tester.drag(scrollView, const Offset(0, -160));
      await tester.pump();

      expect(tester.getTopLeft(find.byType(PageIntro)).dy, lessThan(heroTop));
      expect(tester.getRect(scrollView), scrollRect);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('mobile and desktop controls share the audience state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 800));
    final store = StoreState();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      store.dispose();
    });

    await tester.pumpWidget(MaterialApp(home: CollectionsPage(store: store)));
    await tester.pump();
    expect(find.byType(PageIntro), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('storefront-mobile-filter-men')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MenPage), findsOneWidget);
    expect(find.byType(PageIntro), findsNothing);
    expect(
      find.text('تيشيرت الأداء الأساسي', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('سترة ستوديو خفيفة', skipOffstage: false), findsNothing);

    await tester.binding.setSurfaceSize(const Size(1024, 800));
    await tester.pumpAndSettle();
    final menButton = tester.widget<TextButton>(
      find.descendant(
        of: find.byKey(const ValueKey('storefront-filter-men')),
        matching: find.byType(TextButton),
      ),
    );
    expect(
      menButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      StorefrontColors.accent,
    );

    await tester.tap(find.byKey(const ValueKey('storefront-filter-women')));
    await tester.pumpAndSettle();
    expect(find.byType(WomenPage), findsOneWidget);
    expect(find.byType(PageIntro), findsNothing);
    expect(find.text('سترة ستوديو خفيفة', skipOffstage: false), findsOneWidget);
    expect(
      find.text('تيشيرت الأداء الأساسي', skipOffstage: false),
      findsNothing,
    );

    await tester.binding.setSurfaceSize(const Size(375, 800));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    final mobileWomenLabel = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('storefront-mobile-filter-women')),
        matching: find.text('النساء'),
      ),
    );
    expect(mobileWomenLabel.style?.color, StorefrontColors.accent);

    await tester.tap(
      find.byKey(const ValueKey('storefront-mobile-filter-all')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CollectionsPage), findsOneWidget);
    expect(find.byType(PageIntro), findsOneWidget);
    expect(
      find.text('تيشيرت الأداء الأساسي', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('سترة ستوديو خفيفة', skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkout titles reuse the cart heading typography', (
    tester,
  ) async {
    final store = StoreState()..add(products.first, size: 'M');
    addTearDown(store.dispose);

    await tester.pumpWidget(MaterialApp(home: CartPage(store: store)));
    await tester.pump();
    final cartHeadingStyle = tester.widget<Text>(find.text('اختياراتك')).style;
    expect(cartHeadingStyle?.fontFamily, 'Cairo');

    await tester.pumpWidget(MaterialApp(home: CheckoutPage(store: store)));
    await tester.pump();
    final appBarTitle = tester.widget<Text>(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('إتمام الطلب'),
      ),
    );
    final pageTitle = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText() == 'إتمام الطلب.',
      ),
    );

    expect(appBarTitle.style, cartHeadingStyle);
    expect((pageTitle.text as TextSpan).style, cartHeadingStyle);
    expect(tester.takeException(), isNull);
  });
}
