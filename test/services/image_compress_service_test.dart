import 'package:flutter_test/flutter_test.dart';
import 'package:betogether/core/services/image_compress_service.dart';
import 'dart:typed_data';

void main() {
  group('ImageCompressService', () {
    // Note: flutter_image_compress requires native bindings, so these tests
    // verify the API contract and fallback behavior. Full compression testing
    // requires integration tests on a real device.

    test('compressAvatar returns bytes on fallback', () async {
      // Create minimal test bytes (not a valid JPEG, so compression will fail
      // and should return the original bytes as fallback)
      final testBytes = Uint8List.fromList(List.filled(100, 0xFF));

      final result = await ImageCompressService.compressAvatar(testBytes);

      // Should return original bytes as fallback when compression fails
      expect(result, isNotNull);
      expect(result!.length, greaterThan(0));
    });

    test('compressStoryImage returns bytes on fallback', () async {
      final testBytes = Uint8List.fromList(List.filled(200, 0xAA));

      final result = await ImageCompressService.compressStoryImage(testBytes);

      expect(result, isNotNull);
      expect(result!.length, greaterThan(0));
    });

    test('compress with custom parameters returns bytes on fallback', () async {
      final testBytes = Uint8List.fromList(List.filled(150, 0xBB));

      final result = await ImageCompressService.compress(
        testBytes,
        maxWidth: 640,
        maxHeight: 480,
        quality: 50,
      );

      expect(result, isNotNull);
      expect(result!.length, greaterThan(0));
    });

    test('compressAvatar handles empty bytes', () async {
      final testBytes = Uint8List(0);

      final result = await ImageCompressService.compressAvatar(testBytes);

      // Should return original (empty) bytes as fallback
      expect(result, isNotNull);
    });
  });
}
