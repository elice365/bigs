import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageCompressorResult {
  ImageCompressorResult({
    required this.bytes,
    required this.suggestedName,
  });

  final Uint8List bytes;
  final String? suggestedName;
}

class ImageCompressor {
  static const int _maxBytes = 1024 * 1024; // 1MB target
  static const int _maxDimension = 1920;

  /// Returns compressed image bytes when the payload exceeds [_maxBytes].
  static Future<ImageCompressorResult?> compressIfNeeded(
    Uint8List data, {
    required String originalName,
    String? extension,
  }) async {
    if (data.lengthInBytes <= _maxBytes) {
      return ImageCompressorResult(
        bytes: data,
        suggestedName: null,
      );
    }

    final params = _CompressorParams(
      Uint8List.fromList(data),
      extension?.toLowerCase(),
      originalName,
    );
    final result = await compute(_compressImage, params);
    return result;
  }
}

class _CompressorParams {
  _CompressorParams(this.bytes, this.extension, this.originalName);

  final Uint8List bytes;
  final String? extension;
  final String originalName;
}

ImageCompressorResult _compressImage(_CompressorParams params) {
  final image = img.decodeImage(params.bytes);
  if (image == null) {
    return ImageCompressorResult(bytes: params.bytes, suggestedName: null);
  }

  img.Image processed = image;
  if (processed.width > ImageCompressor._maxDimension ||
      processed.height > ImageCompressor._maxDimension) {
    processed = _resizeToFit(processed, ImageCompressor._maxDimension);
  }

  List<int> encoded = params.bytes;
  String? suggestedName;

  switch (params.extension) {
    case 'jpg':
    case 'jpeg':
      encoded = _encodeJpeg(processed);
      break;
    case 'png':
      encoded = _encodePng(processed);
      break;
    case 'gif':
      encoded = _encodeGif(processed);
      suggestedName = _replaceExtension(params.originalName, 'gif');
      break;
    default:
      encoded = _encodeJpeg(processed);
      suggestedName = _replaceExtension(params.originalName, 'jpg');
      break;
  }

  if (encoded.length > ImageCompressor._maxBytes) {
    encoded = _encodeJpeg(processed);
    suggestedName ??= _replaceExtension(params.originalName, 'jpg');
  }

  while (encoded.length > ImageCompressor._maxBytes &&
      (processed.width > 640 || processed.height > 640)) {
    processed = _resizeToFit(processed, (math.max(processed.width, processed.height) * 0.8).round());
    encoded = _encodeJpeg(processed);
  }

  return ImageCompressorResult(
    bytes: Uint8List.fromList(encoded),
    suggestedName: suggestedName,
  );
}

List<int> _encodeJpeg(img.Image image) {
  var quality = 85;
  List<int> encoded = img.encodeJpg(image, quality: quality);
  while (encoded.length > ImageCompressor._maxBytes && quality > 20) {
    quality -= 10;
    encoded = img.encodeJpg(image, quality: quality);
  }
  return encoded;
}

img.Image _resizeToFit(img.Image image, int maxDimension) {
  final width = image.width;
  final height = image.height;
  if (width <= maxDimension && height <= maxDimension) {
    return image;
  }
  final aspect = width / height;
  int targetWidth;
  int targetHeight;
  if (width >= height) {
    targetWidth = maxDimension;
    targetHeight = (maxDimension / aspect).round();
  } else {
    targetHeight = maxDimension;
    targetWidth = (maxDimension * aspect).round();
  }
  targetWidth = math.max(targetWidth, 1);
  targetHeight = math.max(targetHeight, 1);
  return img.copyResize(
    image,
    width: targetWidth,
    height: targetHeight,
    interpolation: img.Interpolation.linear,
  );
}

List<int> _encodePng(img.Image image) {
  int level = 6;
  List<int> encoded = img.encodePng(image, level: level);
  while (encoded.length > ImageCompressor._maxBytes && level < 9) {
    level++;
    encoded = img.encodePng(image, level: level);
  }
  return encoded;
}

List<int> _encodeGif(img.Image image) {
  return img.encodeGif(image);
}

String _replaceExtension(String originalName, String newExtension) {
  final dotIndex = originalName.lastIndexOf('.');
  if (dotIndex == -1) {
    return '$originalName.$newExtension';
  }
  return '${originalName.substring(0, dotIndex)}.$newExtension';
}
