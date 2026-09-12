import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsam09/main.dart';
import 'package:ironsam09/core/config/app_config.dart';
import 'package:ironsam09/core/utils/image_url_policy.dart';
import 'package:ironsam09/core/utils/hex_color.dart';
import 'package:ironsam09/data/models/order.dart';
import 'package:ironsam09/data/repositories/store_repository.dart';
import 'package:ironsam09/admin/admin_service.dart';
import 'package:ironsam09/admin/admin_widgets.dart';
import 'package:ironsam09/widgets/catalog_widgets.dart';

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
      category: 'Test',
      gender: 'Test',
      price: 100,
      sizes: 'S - XL',
      status: 'Available',
      imageUrl: '',
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

  testWidgets('collections page renders the approved storefront flow', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('الكل'), findsNWidgets(2));
    expect(find.text('توصيل إلى جميع أنحاء ليبيا'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pump();
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
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('تمت الإضافة إلى السلة'), findsNothing);
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

    expect(find.text('يرجى اختيار المقاس أولاً'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('يرجى اختيار المقاس أولاً'), findsNothing);
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
}
