enum StorefrontAudience {
  all(label: 'الكل'),
  men(label: 'الرجال', productGender: 'رجال'),
  women(label: 'النساء', productGender: 'نساء');

  const StorefrontAudience({required this.label, this.productGender});

  final String label;
  final String? productGender;
}
