import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../data/models/product.dart';
import '../../data/catalog/product_catalog.dart' as catalog;
import '../../data/models/category.dart' as store_models;
import '../../data/models/order.dart';
import '../../data/repositories/store_repository.dart';

class CartItem {
  const CartItem({
    required this.product,
    required this.size,
    required this.quantity,
    this.colorId,
    this.colorName,
    this.variantId,
  });

  final Product product;
  final String size;
  final int quantity;
  final String? colorId;
  final String? colorName;
  final String? variantId;

  // Keep map-entry style access for existing presentation code.
  Product get key => product;
  int get value => quantity;
}

class StoreState extends ChangeNotifier {
  StoreState({StoreRepository? repository})
    : repository = repository ?? createStoreRepository();

  final StoreRepository repository;
  final Map<Product, Map<String, int>> _cart = {};
  final Map<Product, String> _selectedSizes = {};
  final Map<Product, String?> _selectedColors = {};
  final Map<Product, ValueNotifier<String?>> _selectedSizeSignals = {};
  final Map<Product, ValueNotifier<String?>> _selectedColorSignals = {};
  final ValueNotifier<int> _catalogRevision = ValueNotifier(0);
  Future<void>? _catalogLoad;
  List<Product> _products = AppConfig.isSupabaseConfigured
      ? const []
      : catalog.products;
  List<store_models.Category> _categories = const [];
  String? _discountCode;
  double _discountPercent = 0;
  bool isLoading = false;
  String? loadError;

  List<Product> get products => _products;
  List<store_models.Category> get categories => _categories;
  ValueListenable<int> get catalogChanges => _catalogRevision;
  String? selectedSizeFor(Product product) => _selectedSizes[product];
  bool hasSelectedSize(Product product) => _selectedSizes.containsKey(product);
  String? selectedColorFor(Product product) => colorFor(product);
  bool hasSelectedColor(Product product) =>
      product.activeColors.length > 1 && _selectedColors.containsKey(product);
  ValueListenable<String?> selectedSizeChangesFor(Product product) =>
      _selectedSizeSignals.putIfAbsent(
        product,
        () => ValueNotifier<String?>(_selectedSizes[product]),
      );
  ValueListenable<String?> selectedColorChangesFor(Product product) =>
      _selectedColorSignals.putIfAbsent(
        product,
        () => ValueNotifier<String?>(colorFor(product)),
      );
  String? colorFor(Product product) {
    final selected = _selectedColors[product];
    if (selected != null &&
        product.activeColors.any((color) => color.id == selected)) {
      return selected;
    }
    final active = product.activeColors;
    return active.length == 1 ? active.single.id : null;
  }

  String sizeFor(Product product) =>
      _selectedSizes[product] ?? product.defaultSizeFor(colorFor(product));
  int stockFor(Product product) =>
      product.stockFor(sizeFor(product), colorId: colorFor(product));
  String? get discountCode => _discountCode;
  double get discountPercent => _discountPercent;
  bool get hasDiscount => _discountCode != null;
  double get discountAmount => subtotal * _discountPercent / 100;
  double get total => subtotal - discountAmount;

  List<CartItem> get items => [
    for (final entry in _cart.entries)
      for (final line in entry.value.entries)
        _cartItem(entry.key, line.key, line.value),
  ];

  CartItem _cartItem(Product product, String key, int quantity) {
    ProductVariant? variant;
    for (final candidate in product.variants) {
      if (candidate.id == key) {
        variant = candidate;
        break;
      }
    }
    if (variant != null) {
      return CartItem(
        product: product,
        size: variant.size,
        quantity: quantity,
        colorId: variant.colorId,
        colorName:
            variant.colorNameAr ?? product.colorById(variant.colorId)?.nameAr,
        variantId: variant.id,
      );
    }
    final separator = key.indexOf('::');
    final colorId = separator < 0
        ? null
        : (key.substring(0, separator).isEmpty
              ? null
              : key.substring(0, separator));
    final size = separator < 0 ? key : key.substring(separator + 2);
    return CartItem(
      product: product,
      size: size,
      quantity: quantity,
      colorId: colorId,
      colorName: product.colorById(colorId)?.nameAr,
    );
  }

  int get itemCount => _cart.values.fold(
    0,
    (sum, lines) =>
        sum + lines.values.fold(0, (total, quantity) => total + quantity),
  );

  double get subtotal =>
      items.fold(0, (sum, item) => sum + item.product.price * item.quantity);

  void selectSize(Product product, String size) {
    final colorId = colorFor(product);
    if (!product.sizeOptionsForColor(colorId).contains(size) ||
        product.stockFor(size, colorId: colorId) <= 0) {
      return;
    }
    if (_selectedSizes[product] == size) return;
    _selectedSizes[product] = size;
    _selectedSizeSignals[product]?.value = size;
    notifyListeners();
  }

  void selectColor(Product product, String colorId) {
    if (!product.activeColors.any((color) => color.id == colorId)) return;
    _selectedColors[product] = colorId;
    _selectedColorSignals[product]?.value = colorId;
    final currentSize = _selectedSizes[product];
    if (currentSize != null &&
        product.stockFor(currentSize, colorId: colorId) <= 0) {
      _selectedSizes.remove(product);
      _selectedSizeSignals[product]?.value = null;
    }
    notifyListeners();
  }

  Future<void> loadCatalog() => _catalogLoad ??= _loadCatalog();

  Future<void> _loadCatalog() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      final productsFuture = repository.fetchProducts();
      final categoriesFuture = repository.fetchCategories();
      final fetchedProducts = await productsFuture;
      final fetchedCategories = await categoriesFuture;
      _products = fetchedProducts;
      _categories = fetchedCategories;
      _catalogRevision.value++;
    } catch (_) {
      if (AppConfig.isSupabaseConfigured) {
        _products = const [];
        _categories = const [];
        _catalogRevision.value++;
      }
      loadError = 'تعذر تحميل المنتجات. سنعرض البيانات المحلية مؤقتًا.';
    } finally {
      isLoading = false;
      notifyListeners();
      _catalogLoad = null;
    }
  }

  @override
  void dispose() {
    for (final signal in _selectedSizeSignals.values) {
      signal.dispose();
    }
    for (final signal in _selectedColorSignals.values) {
      signal.dispose();
    }
    _catalogRevision.dispose();
    super.dispose();
  }

  void add(Product product, {String? size, String? colorId}) {
    final selectedColor = colorId ?? colorFor(product);
    final selectedSize = size ?? sizeFor(product);
    final variant = product.variantFor(
      size: selectedSize,
      colorId: selectedColor,
    );
    if (!product.sizeOptionsForColor(selectedColor).contains(selectedSize) ||
        product.stockFor(selectedSize, colorId: selectedColor) <= 0 ||
        (product.variants.isNotEmpty && variant == null)) {
      return;
    }
    final lines = _cart.putIfAbsent(product, () => <String, int>{});
    final key = variant?.id ?? '${selectedColor ?? ''}::$selectedSize';
    final current = lines[key] ?? 0;
    if (current >= product.stockFor(selectedSize, colorId: selectedColor)) {
      return;
    }
    if (selectedColor != null) {
      _selectedColors[product] = selectedColor;
      _selectedColorSignals[product]?.value = selectedColor;
    }
    _selectedSizes[product] = selectedSize;
    _selectedSizeSignals[product]?.value = selectedSize;
    lines[key] = current + 1;
    notifyListeners();
  }

  void remove(
    Product product, {
    String? size,
    String? colorId,
    String? variantId,
  }) {
    final lines = _cart[product];
    final selectedColor = colorId ?? colorFor(product);
    final selectedSize = size ?? sizeFor(product);
    final variant = variantId == null
        ? product.variantFor(size: selectedSize, colorId: selectedColor)
        : null;
    final key =
        variantId ?? variant?.id ?? '${selectedColor ?? ''}::$selectedSize';
    final quantity = lines?[key];
    if (lines == null || quantity == null) return;
    if (quantity <= 1) {
      lines.remove(key);
      if (lines.isEmpty) {
        _cart.remove(product);
        _selectedSizes.remove(product);
        _selectedColors.remove(product);
        _selectedSizeSignals[product]?.value = null;
        _selectedColorSignals[product]?.value = null;
        if (_cart.isEmpty) {
          _discountCode = null;
          _discountPercent = 0;
        }
      } else if (_selectedSizes[product] == selectedSize &&
          selectedColor == colorFor(product)) {
        final next = _cartItem(product, lines.keys.first, 1);
        _selectedSizes[product] = next.size;
        _selectedColors[product] = next.colorId;
        _selectedSizeSignals[product]?.value = next.size;
        _selectedColorSignals[product]?.value = next.colorId;
      }
    } else {
      lines[key] = quantity - 1;
    }
    notifyListeners();
  }

  void clear() {
    if (_cart.isEmpty && _discountCode == null) return;
    for (final product in _selectedSizes.keys.toList()) {
      _selectedSizeSignals[product]?.value = null;
      _selectedColorSignals[product]?.value = null;
    }
    _cart.clear();
    _selectedSizes.clear();
    _selectedColors.clear();
    _discountCode = null;
    _discountPercent = 0;
    notifyListeners();
  }

  Future<DiscountValidation> validateDiscount(String code) {
    return repository.validateDiscount(code);
  }

  Future<DiscountValidation> applyDiscount(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      clearDiscount();
      return const DiscountValidation(valid: false);
    }

    final validation = await validateDiscount(normalized);
    if (validation.valid) {
      _discountCode = validation.code ?? normalized;
      _discountPercent = validation.customerDiscountPercent;
    } else {
      _discountCode = null;
      _discountPercent = 0;
    }
    notifyListeners();
    return validation;
  }

  void clearDiscount() {
    if (_discountCode == null && _discountPercent == 0) return;
    _discountCode = null;
    _discountPercent = 0;
    notifyListeners();
  }

  Future<OrderReceipt?> submitOrder({
    required String customerName,
    required String phone,
    required String city,
    required String address,
    required String notes,
    String? requestId,
  }) {
    final effectiveDiscountCode = _discountCode;
    final effectiveDiscountPercent = _discountPercent;
    final discount = effectiveDiscountCode == null
        ? 0.0
        : subtotal * effectiveDiscountPercent / 100;
    final orderItems = items
        .map(
          (entry) => <String, dynamic>{
            'product_id': entry.product.id,
            'variant_id': entry.variantId,
            'size': entry.size,
            if (entry.colorId != null) 'color_id': entry.colorId,
            'quantity': entry.quantity,
          },
        )
        .toList();
    return repository.createOrder(
      OrderDraft(
        customerName: customerName,
        phone: phone,
        city: city,
        address: address,
        notes: notes,
        discountCode: effectiveDiscountCode,
        subtotal: subtotal,
        discountAmount: discount,
        total: subtotal - discount,
        discountPercent: effectiveDiscountPercent,
      ),
      orderItems,
      requestId: requestId,
    );
  }
}
