enum StorefrontAudience {
  all(label: 'الكل'),
  men(label: 'الرجال', productGender: 'رجال'),
  women(label: 'النساء', productGender: 'نساء');

  const StorefrontAudience({required this.label, this.productGender});

  final String label;
  final String? productGender;

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
