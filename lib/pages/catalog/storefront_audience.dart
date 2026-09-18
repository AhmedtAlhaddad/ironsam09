import '../../data/models/product.dart';

enum StorefrontAudience {
  all(label: 'الكل'),
  men(label: 'الرجال', productGender: ProductGender.men),
  women(label: 'النساء', productGender: ProductGender.women);

  const StorefrontAudience({required this.label, this.productGender});

  final String label;
  final ProductGender? productGender;

  bool includesProductGender(String value) {
    final normalized = ProductGender.fromValue(value);
    return switch (this) {
      StorefrontAudience.all => true,
      StorefrontAudience.men =>
        normalized == ProductGender.men || normalized == ProductGender.unisex,
      StorefrontAudience.women =>
        normalized == ProductGender.women || normalized == ProductGender.unisex,
    };
  }

  String get sectionHeading => switch (this) {
    StorefrontAudience.all => 'تسوق التشكيلة',
    StorefrontAudience.men => 'ملابس الرجال',
    StorefrontAudience.women => 'ملابس النساء',
  };

  String? get sectionContext => switch (this) {
    StorefrontAudience.all => 'كل القطع',
    StorefrontAudience.men || StorefrontAudience.women => null,
  };
}
