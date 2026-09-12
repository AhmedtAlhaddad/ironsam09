class Category {
  const Category({
    this.id,
    required this.nameAr,
    this.slug = '',
    this.active = true,
  });

  final String? id;
  final String nameAr;
  final String slug;
  final bool active;
}
