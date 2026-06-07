import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Service for compressing images before upload to minimize storage and bandwidth.
///
/// Compression strategy:
/// - Avatars: 512×512 JPEG, quality 80 → ~50-80KB
/// - Story images: 1080px max width JPEG, quality 75 → ~100-200KB
class ImageCompressService {
  ImageCompressService._();

  /// Compress an avatar image to 512×512 JPEG.
  ///
  /// Returns compressed bytes or null if compression fails.
  static Future<Uint8List?> compressAvatar(Uint8List imageBytes) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 512,
        minHeight: 512,
        quality: 80,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      // Return original bytes if compression fails
      return imageBytes;
    }
  }

  /// Compress a story image to max 1080px width JPEG.
  ///
  /// Returns compressed bytes or null if compression fails.
  static Future<Uint8List?> compressStoryImage(Uint8List imageBytes) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 1080,
        minHeight: 1080,
        quality: 75,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      return imageBytes;
    }
  }

  /// Generic compression with custom parameters.
  static Future<Uint8List?> compress(
    Uint8List imageBytes, {
    int maxWidth = 1080,
    int maxHeight = 1080,
    int quality = 75,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      return imageBytes;
    }
  }
}
