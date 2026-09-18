import 'dart:typed_data';

import 'product_thumbnail_codec.dart' deferred as thumbnail_codec;

Future<Uint8List> generateProductThumbnail(Uint8List sourceBytes) async {
  await thumbnail_codec.loadLibrary();
  return thumbnail_codec.generateProductThumbnail(sourceBytes);
}

Future<Uint8List> generateProductHeroImage(Uint8List sourceBytes) async {
  await thumbnail_codec.loadLibrary();
  return thumbnail_codec.generateProductHeroImage(sourceBytes);
}
