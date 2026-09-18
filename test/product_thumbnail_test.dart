import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

import 'package:ironsam09/admin/product_thumbnail_generator.dart';
import 'package:ironsam09/core/utils/product_image_paths.dart';
import 'package:ironsam09/data/models/product.dart';
import 'package:ironsam09/features/cart/cart_state.dart';
import 'package:ironsam09/widgets/catalog_widgets.dart';
import 'package:ironsam09/widgets/safe_product_image.dart';

void main() {
  test('thumbnail paths are deterministic, unique, and product-scoped', () {
    final first = productThumbnailStoragePath(
      productId: 'product-1',
      originalStoragePath: 'product-1/1000_front.photo.jpg',
    );
    final repeated = productThumbnailStoragePath(
      productId: 'product-1',
      originalStoragePath: 'product-1/1000_front.photo.jpg',
    );
    final second = productThumbnailStoragePath(
      productId: 'product-1',
      originalStoragePath: 'product-1/archive/1000_front.photo.jpg',
    );

    expect(first, repeated);
    expect(first, startsWith('product-1/thumbs/'));
    expect(first, endsWith('.webp'));
    expect(second, isNot(first));

    final hero = productHeroStoragePath(
      productId: 'product-1',
      originalStoragePath: 'product-1/1000_front.photo.jpg',
    );
    expect(hero, startsWith('product-1/hero/'));
    expect(hero, endsWith('.webp'));
    expect(hero.split('/').last, first.split('/').last);
  });

  test(
    'thumbnail generation caps the longest edge without upscaling',
    () async {
      final largeSource = image.Image(width: 1600, height: 1200);
      image.fill(largeSource, color: image.ColorRgb8(30, 80, 140));
      final largeThumbnail = image.decodeWebP(
        await generateProductThumbnail(image.encodePng(largeSource)),
      );

      expect(largeThumbnail, isNotNull);
      expect(largeThumbnail!.width, 800);
      expect(largeThumbnail.height, 600);

      final smallSource = image.Image(width: 320, height: 640);
      image.fill(smallSource, color: image.ColorRgb8(140, 80, 30));
      final smallThumbnail = image.decodeWebP(
        await generateProductThumbnail(image.encodePng(smallSource)),
      );

      expect(smallThumbnail, isNotNull);
      expect(smallThumbnail!.width, 320);
      expect(smallThumbnail.height, 640);
    },
  );

  test('hero generation caps the longest edge without upscaling', () async {
    final largeSource = image.Image(width: 2400, height: 1800);
    image.fill(largeSource, color: image.ColorRgb8(30, 80, 140));
    final largeHero = image.decodeWebP(
      await generateProductHeroImage(image.encodePng(largeSource)),
    );

    expect(largeHero, isNotNull);
    expect(largeHero!.width, 1600);
    expect(largeHero.height, 1200);

    final smallSource = image.Image(width: 640, height: 480);
    final smallHero = image.decodeWebP(
      await generateProductHeroImage(image.encodePng(smallSource)),
    );
    expect(smallHero, isNotNull);
    expect(smallHero!.width, 640);
    expect(smallHero.height, 480);
  });

  test('Hero requests its derivative with the original as fallback', () {
    const originalUrl = 'https://images.example.com/original.jpg';
    const heroUrl = 'https://images.example.com/hero.webp';
    const product = Product(
      name: 'Hero product',
      category: 'Test',
      gender: 'unisex',
      price: 100,
      sizes: 'M',
      status: 'Available',
      imageUrl: originalUrl,
      images: [ProductImage(url: originalUrl, heroUrl: heroUrl)],
    );

    final source = buildHeroImageSources([product]).single;
    expect(source.url, heroUrl);
    expect(source.fallbackUrl, originalUrl);
    expect(product.imageUrl, originalUrl);
    expect(product.images.single.url, originalUrl);
  });

  testWidgets('catalog card requests thumbnail while retaining original', (
    tester,
  ) async {
    const originalUrl = 'https://images.example.com/original.jpg';
    const thumbnailUrl = 'https://images.example.com/thumbnail.webp';
    const product = Product(
      name: 'Thumbnail product',
      category: 'Test',
      gender: 'unisex',
      price: 100,
      sizes: 'M',
      status: 'Available',
      imageUrl: originalUrl,
      images: [ProductImage(url: originalUrl, thumbnailUrl: thumbnailUrl)],
    );
    final store = StoreState();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 360,
            child: ProductCard(product: product, store: store),
          ),
        ),
      ),
    );

    final productImage = tester.widget<SafeProductImage>(
      find.byType(SafeProductImage),
    );
    expect(productImage.url, thumbnailUrl);
    expect(productImage.fallbackUrl, originalUrl);
    expect(product.imageUrl, originalUrl);
    expect(product.images.single.url, originalUrl);
  });
}
