import 'package:flutter_test/flutter_test.dart';

import 'package:ironsam09/main.dart';
import 'package:ironsam09/pages/catalog/storefront_audience.dart';

void main() {
  Product item(String name, ProductGender gender) => Product(
    name: name,
    category: 'اختبار',
    gender: gender.value,
    price: 10,
    sizes: 'M',
    status: 'متوفر',
    imageUrl: '',
  );

  final groupedProducts = <Product>[
    for (var index = 1; index <= 4; index++) item('m$index', ProductGender.men),
    for (var index = 1; index <= 4; index++)
      item('w$index', ProductGender.women),
    for (var index = 1; index <= 3; index++)
      item('u$index', ProductGender.unisex),
  ];

  List<String> namesFor(StorefrontAudience audience) => filterCatalogProducts(
    products: groupedProducts,
    audience: audience,
    selectedCategory: CatalogPage.allCategory,
    query: '',
  ).map((product) => product.name).toList();

  test('actual database gender values normalize centrally', () {
    expect(ProductGender.fromValue('men'), ProductGender.men);
    expect(ProductGender.fromValue('women'), ProductGender.women);
    expect(ProductGender.fromValue('unisex'), ProductGender.unisex);
    expect(ProductGender.fromValue('الرجال'), ProductGender.men);
    expect(ProductGender.fromValue('نساء'), ProductGender.women);
    expect(ProductGender.fromValue('للجنسين'), ProductGender.unisex);
  });

  test('men and women audiences include unisex in normal source order', () {
    expect(namesFor(StorefrontAudience.men), [
      'm1',
      'm2',
      'm3',
      'm4',
      'u1',
      'u2',
      'u3',
    ]);
    expect(namesFor(StorefrontAudience.women), [
      'w1',
      'w2',
      'w3',
      'w4',
      'u1',
      'u2',
      'u3',
    ]);
  });

  test('all deterministically interleaves grouped gender buckets', () {
    expect(namesFor(StorefrontAudience.all), [
      'w1',
      'm1',
      'u1',
      'w2',
      'm2',
      'u2',
      'w3',
      'm3',
      'u3',
      'w4',
      'm4',
    ]);
    expect(namesFor(StorefrontAudience.all), namesFor(StorefrontAudience.all));
  });
}
