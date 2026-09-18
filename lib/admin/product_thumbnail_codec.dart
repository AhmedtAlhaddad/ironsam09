import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as image;

const productThumbnailMaxDimension = 800;
const productThumbnailQuality = 80;
const productHeroMaxDimension = 1600;
const productHeroQuality = 82;

Uint8List generateProductThumbnail(Uint8List sourceBytes) =>
    _generateProductImageVariant(
      sourceBytes,
      maxDimension: productThumbnailMaxDimension,
      quality: productThumbnailQuality,
    );

Uint8List generateProductHeroImage(Uint8List sourceBytes) =>
    _generateProductImageVariant(
      sourceBytes,
      maxDimension: productHeroMaxDimension,
      quality: productHeroQuality,
    );

Uint8List _generateProductImageVariant(
  Uint8List sourceBytes, {
  required int maxDimension,
  required int quality,
}) {
  final decoded = image.decodeImage(sourceBytes);
  if (decoded == null) {
    throw const FormatException('Unsupported or invalid product image.');
  }

  final firstFrame = decoded.getFrame(0);
  final longestEdge = math.max(firstFrame.width, firstFrame.height);
  final resized = longestEdge > maxDimension
      ? firstFrame.width >= firstFrame.height
            ? image.copyResize(
                firstFrame,
                width: maxDimension,
                interpolation: image.Interpolation.cubic,
              )
            : image.copyResize(
                firstFrame,
                height: maxDimension,
                interpolation: image.Interpolation.cubic,
              )
      : firstFrame;

  return image.encodeWebP(
    resized,
    singleFrame: true,
    lossless: false,
    quality: quality,
  );
}
