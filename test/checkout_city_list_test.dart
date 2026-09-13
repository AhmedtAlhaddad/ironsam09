import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ironsam09/data/local/libya_cities.dart';
import 'package:ironsam09/data/models/category.dart';
import 'package:ironsam09/data/models/order.dart';
import 'package:ironsam09/data/models/product.dart';
import 'package:ironsam09/data/repositories/store_repository.dart';
import 'package:ironsam09/features/cart/cart_state.dart';
import 'package:ironsam09/pages/checkout/checkout_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');
  late List<MethodCall> launcherCalls;

  setUp(() {
    launcherCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, (call) async {
          launcherCalls.add(call);
          return true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, null);
  });

  test(
    'city data is expanded, Arabic-only, unique, and preserves old values',
    () {
      const previouslySupported = <String>[
        'طرابلس',
        'بنغازي',
        'مصراتة',
        'الزاوية',
        'سبها',
        'البيضاء',
        'زليتن',
      ];

      expect(libyaCitiesAndAreas.length, 165);
      expect(
        libyaCitiesAndAreas.take(previouslySupported.length),
        previouslySupported,
      );
      expect(libyaCitiesAndAreas.toSet().length, libyaCitiesAndAreas.length);
      expect(
        libyaCitiesAndAreas.every(
          (city) => RegExp(r'^[\u0600-\u06FF\s]+$').hasMatch(city),
        ),
        isTrue,
      );
      expect(
        libyaCitiesAndAreas,
        containsAll(<String>['غدامس', 'الكفرة', 'درنة', 'طبرق', 'أوباري']),
      );
    },
  );

  testWidgets(
    'existing Checkout city selector opens and scrolls at 320px RTL',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = StoreState(repository: _CapturingRepository())
        ..add(_testProduct, size: 'M');
      addTearDown(store.dispose);

      await tester.pumpWidget(MaterialApp(home: CheckoutPage(store: store)));
      await tester.pumpAndSettle();

      final cityField = find.byType(DropdownButtonFormField<String>);
      expect(cityField, findsOneWidget);
      expect(Directionality.of(tester.element(cityField)), TextDirection.rtl);
      final dropdown = tester.widget<DropdownButton<String>>(
        find.descendant(
          of: cityField,
          matching: find.byType(DropdownButton<String>),
        ),
      );
      final values = dropdown.items!.map((item) => item.value).toList();
      expect(
        values,
        containsAll(<String>['طرابلس', 'بنغازي', 'غدامس', 'الكفرة']),
      );

      await tester.ensureVisible(cityField);
      await tester.tap(cityField);
      await tester.pumpAndSettle();

      expect(find.text('طرابلس'), findsOneWidget);
      expect(find.byType(Scrollable), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('غدامس'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('غدامس'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selected city remains the same String through order and WhatsApp',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _CapturingRepository();
      final store = StoreState(repository: repository)
        ..add(_testProduct, size: 'M');
      addTearDown(store.dispose);

      await tester.pumpWidget(MaterialApp(home: CheckoutPage(store: store)));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'محمد علي');
      await tester.enterText(textFields.at(1), '0912345678');
      await tester.enterText(textFields.at(2), 'حي الأندلس، شارع النخيل');

      final cityField = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(cityField);
      await tester.tap(cityField);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('غدامس'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('غدامس'));
      await tester.pumpAndSettle();

      final cityState = tester.state<FormFieldState<String>>(cityField);
      expect(cityState.value, 'غدامس');

      final confirm = find.byKey(const ValueKey('checkout-confirm-cta'));
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(repository.createdDraft, isNotNull);
      expect(repository.createdDraft!.city, isA<String>());
      expect(repository.createdDraft!.city, 'غدامس');
      expect(launcherCalls, hasLength(1));
      final launchArguments = Map<String, Object?>.from(
        launcherCalls.single.arguments as Map,
      );
      final whatsappUri = Uri.parse(launchArguments['url']! as String);
      expect(whatsappUri.host, 'wa.me');
      expect(whatsappUri.path, '/218928077643');
      expect(whatsappUri.queryParameters['text'], contains('المدينة: غدامس'));
      expect(tester.takeException(), isNull);
    },
  );
}

const _testProduct = Product(
  id: 'checkout-city-test-product',
  name: 'قميص تجريبي',
  category: 'قمصان',
  gender: 'للجنسين',
  price: 100,
  sizes: 'M',
  status: 'متوفر',
  imageUrl: '',
);

class _CapturingRepository implements StoreRepository {
  OrderDraft? createdDraft;

  @override
  Future<List<Product>> fetchProducts() async => const <Product>[];

  @override
  Future<List<Category>> fetchCategories() async => const <Category>[];

  @override
  Future<DiscountValidation> validateDiscount(String code) async =>
      const DiscountValidation(valid: false);

  @override
  Future<OrderReceipt?> createOrder(
    OrderDraft draft,
    List<Map<String, dynamic>> items, {
    String? requestId,
  }) async {
    createdDraft = draft;
    return OrderReceipt(
      orderNumber: 'CITY-TEST-001',
      subtotal: draft.subtotal,
      discount: draft.discountAmount,
      total: draft.total,
    );
  }
}
