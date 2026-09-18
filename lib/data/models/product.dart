const productGenderMenValue = 'men';
const productGenderWomenValue = 'women';
const productGenderUnisexValue = 'unisex';

enum ProductGender {
  men(productGenderMenValue),
  women(productGenderWomenValue),
  unisex(productGenderUnisexValue);

  const ProductGender(this.value);

  final String value;

  static ProductGender? fromValue(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'men' || 'رجال' || 'الرجال' => ProductGender.men,
      'women' || 'نساء' || 'النساء' => ProductGender.women,
      'unisex' || 'للجنسين' => ProductGender.unisex,
      _ => null,
    };
  }
}

class Product {
  const Product({
    required this.name,
    required this.category,
    required this.gender,
    required this.price,
    required this.sizes,
    required this.status,
    required this.imageUrl,
    this.id,
    this.categoryId,
    this.description = '',
    this.imageUrls = const [],
    this.images = const [],
    this.colors = const [],
    this.variants = const [],
  });

  final String? id;
  final String name;
  final String category;
  final String? categoryId;
  final String gender;

  ProductGender? get normalizedGender => ProductGender.fromValue(gender);
  final double price;
  final String sizes;
  final String status;
  final String imageUrl;
  final String description;
  final List<String> imageUrls;
  final List<ProductImage> images;
  final List<ProductColor> colors;
  final List<ProductVariant> variants;

  String get catalogImageUrl {
    if (images.isNotEmpty && images.first.thumbnailUrl.isNotEmpty) {
      return images.first.thumbnailUrl;
    }
    return imageUrl;
  }

  List<ProductColor> get activeColors =>
      colors.where((color) => color.active).toList(growable: false);

  bool get hasColorTracking => colors.isNotEmpty;

  List<ProductImage> imagesForColor(String? colorId) {
    if (images.isEmpty) {
      final fallbackUrls = imageUrls.isEmpty && imageUrl.isNotEmpty
          ? [imageUrl]
          : imageUrls;
      return [
        for (var index = 0; index < fallbackUrls.length; index++)
          ProductImage(url: fallbackUrls[index], sortOrder: index),
      ];
    }
    if (colorId != null) {
      final dedicated = images
          .where((image) => image.colorId == colorId)
          .toList(growable: false);
      if (dedicated.isNotEmpty) return dedicated;
      return images
          .where((image) => image.colorId == null)
          .toList(growable: false);
    }
    final general = images
        .where((image) => image.colorId == null)
        .toList(growable: false);
    return general.isNotEmpty ? general : images;
  }

  ProductColor? colorById(String? colorId) {
    if (colorId == null) return null;
    for (final color in colors) {
      if (color.id == colorId) return color;
    }
    return null;
  }

  /// Returns the sizes that can be shown to the customer.
  ///
  /// Products loaded from Supabase have explicit variants. The local catalog
  /// keeps a compact range such as "S - XL", so expand the common ranges for
  /// the same picker to work in both modes.
  static final Expando<List<String>> _sizeOptionsCache = Expando();

  List<String> get sizeOptions {
    final cached = _sizeOptionsCache[this];
    if (cached != null) return cached;
    final calculated = _buildSizeOptions();
    _sizeOptionsCache[this] = calculated;
    return calculated;
  }

  List<String> _buildSizeOptions() {
    if (variants.isNotEmpty) {
      final values = variants
          .map((variant) => variant.size.trim())
          .where((size) => size.isNotEmpty)
          .toSet()
          .toList();
      if (values.isNotEmpty) return values;
    }

    final raw = sizes.trim();
    if (raw.isEmpty) return const ['ONE'];

    final parts = raw
        .split(RegExp(r'\s*-\s*'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length == 2) {
      const alphaSizes = <String>[
        'XXXS',
        'XXS',
        'XS',
        'S',
        'M',
        'L',
        'XL',
        'XXL',
        'XXXL',
      ];
      final start = alphaSizes.indexOf(parts[0].toUpperCase());
      final end = alphaSizes.indexOf(parts[1].toUpperCase());
      if (start >= 0 && end >= start) {
        return alphaSizes.sublist(start, end + 1);
      }

      final numericStart = int.tryParse(parts[0]);
      final numericEnd = int.tryParse(parts[1]);
      if (numericStart != null &&
          numericEnd != null &&
          numericEnd >= numericStart) {
        return [
          for (var size = numericStart; size <= numericEnd; size++) '$size',
        ];
      }
    }

    return raw
        .split(RegExp(r'[,،/|]'))
        .map((size) => size.trim())
        .where((size) => size.isNotEmpty)
        .toList();
  }

  String get defaultSize => variants
      .firstWhere(
        (variant) => variant.active && variant.stockQuantity > 0,
        orElse: () => variants.isNotEmpty
            ? variants.first
            : ProductVariant(size: sizeOptions.first, stockQuantity: 999),
      )
      .size;

  String get defaultSizeForActiveColors => defaultSizeFor(null);

  String defaultSizeFor(String? colorId) {
    final available = variantsForColor(
      colorId,
    ).where((variant) => variant.active && variant.stockQuantity > 0);
    final fallback = variantsForColor(colorId);
    if (available.isNotEmpty) return available.first.size;
    if (fallback.isNotEmpty) return fallback.first.size;
    return sizeOptions.first;
  }

  List<String> sizeOptionsForColor(String? colorId) {
    final matching = variantsForColor(colorId)
        .map((variant) => variant.size.trim())
        .where((size) => size.isNotEmpty)
        .toSet()
        .toList();
    return matching.isEmpty ? sizeOptions : matching;
  }

  List<ProductVariant> variantsForColor(String? colorId) {
    if (variants.isEmpty) return const [];
    return variants.where((variant) => variant.colorId == colorId).toList();
  }

  ProductVariant? variantFor({required String size, String? colorId}) {
    for (final variant in variants) {
      if (variant.size == size && variant.colorId == colorId) return variant;
    }
    return null;
  }

  int stockFor(String size, {String? colorId}) {
    if (variants.isEmpty) return 999;
    for (final variant in variants) {
      if (variant.size == size && variant.colorId == colorId) {
        return variant.active ? variant.stockQuantity : 0;
      }
    }
    return 0;
  }
}

class ProductImage {
  const ProductImage({
    this.id,
    required this.url,
    this.thumbnailUrl = '',
    this.heroUrl = '',
    this.colorId,
    this.storagePath,
    this.sortOrder = 0,
    this.isCover = false,
  });

  final String? id;
  final String url;
  final String thumbnailUrl;
  final String heroUrl;
  final String? colorId;
  final String? storagePath;
  final int sortOrder;
  final bool isCover;
}

class ProductColor {
  const ProductColor({
    this.id,
    required this.nameAr,
    this.hexCode,
    this.active = true,
  });

  final String? id;
  final String nameAr;
  final String? hexCode;
  final bool active;
}

class ProductVariant {
  const ProductVariant({
    this.id,
    required this.size,
    required this.stockQuantity,
    this.colorId,
    this.colorNameAr,
    this.active = true,
  });

  final String? id;
  final String size;
  final int stockQuantity;
  final String? colorId;
  final String? colorNameAr;
  final bool active;

  bool get inStock => active && stockQuantity > 0;
}
