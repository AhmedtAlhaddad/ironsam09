import 'dart:convert';

const productImagesBucket = 'product-images';

String productThumbnailStoragePath({
  required String productId,
  required String originalStoragePath,
}) => _productImageVariantStoragePath(
  productId: productId,
  originalStoragePath: originalStoragePath,
  directory: 'thumbs',
);

String productHeroStoragePath({
  required String productId,
  required String originalStoragePath,
}) => _productImageVariantStoragePath(
  productId: productId,
  originalStoragePath: originalStoragePath,
  directory: 'hero',
);

String _productImageVariantStoragePath({
  required String productId,
  required String originalStoragePath,
  required String directory,
}) {
  final normalizedPath = originalStoragePath.trim().replaceAll('\\', '/');
  final fileName = normalizedPath.split('/').last;
  final extensionIndex = fileName.lastIndexOf('.');
  final rawStem = extensionIndex > 0
      ? fileName.substring(0, extensionIndex)
      : fileName;
  final safeStem = rawStem
      .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  final stem = safeStem.isEmpty ? 'image' : safeStem;
  final hash = _stableHash32(normalizedPath);
  final suffix = hash.toRadixString(16).padLeft(8, '0');
  return '$productId/$directory/${stem}_$suffix.webp';
}

int _stableHash32(String value) {
  var hash = 5381;
  for (final byte in utf8.encode(value)) {
    hash = ((hash * 33) ^ byte) & 0xffffffff;
  }
  return hash;
}
