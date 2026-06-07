import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../constants/cloudinary_config.dart';
import 'image_compress_service.dart';

/// Result of a Cloudinary upload operation.
class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
  });
}

/// Service for uploading and managing media on Cloudinary.
///
/// Uses unsigned upload preset — no server-side signing required.
/// All images are compressed before upload to minimize storage costs.
class CloudinaryService {
  CloudinaryService._();

  /// Upload an avatar image (compressed to 512×512).
  ///
  /// Returns [CloudinaryUploadResult] with secure URL and public ID,
  /// or null if upload fails.
  static Future<CloudinaryUploadResult?> uploadAvatar(
    Uint8List imageBytes, {
    required String userId,
  }) async {
    // Compress to avatar size
    final compressed = await ImageCompressService.compressAvatar(imageBytes);
    if (compressed == null) return null;

    return _uploadBytes(
      compressed,
      folder: CloudinaryConfig.avatarFolder,
      publicId: 'avatar_$userId',
    );
  }

  /// Upload a story image (compressed to 1080px max).
  ///
  /// Returns [CloudinaryUploadResult] with secure URL and public ID,
  /// or null if upload fails.
  static Future<CloudinaryUploadResult?> uploadStoryImage(
    Uint8List imageBytes, {
    required String storyId,
  }) async {
    // Compress to story size
    final compressed =
        await ImageCompressService.compressStoryImage(imageBytes);
    if (compressed == null) return null;

    return _uploadBytes(
      compressed,
      folder: CloudinaryConfig.storyFolder,
      publicId: 'story_$storyId',
    );
  }

  /// Upload raw bytes to Cloudinary.
  ///
  /// [folder] — Cloudinary folder path (e.g. 'betogether/avatars')
  /// [publicId] — Optional custom public ID for the asset
  static Future<CloudinaryUploadResult?> _uploadBytes(
    Uint8List bytes, {
    required String folder,
    String? publicId,
  }) async {
    try {
      final uri = Uri.parse(CloudinaryConfig.imageUploadUrl);
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['folder'] = folder;
      if (publicId != null) {
        request.fields['public_id'] = publicId;
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '${publicId ?? 'upload'}.jpg',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return CloudinaryUploadResult(
          secureUrl: data['secure_url'] as String,
          publicId: data['public_id'] as String,
        );
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Upload a video to Cloudinary.
  ///
  /// Videos are uploaded to the video endpoint; Cloudinary handles
  /// server-side transcoding and optimization.
  static Future<CloudinaryUploadResult?> uploadVideo(
    Uint8List videoBytes, {
    required String storyId,
  }) async {
    try {
      final uri = Uri.parse(CloudinaryConfig.videoUploadUrl);
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['folder'] = CloudinaryConfig.storyFolder;
      request.fields['public_id'] = 'video_$storyId';
      // Let Cloudinary handle video compression
      request.fields['resource_type'] = 'video';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          videoBytes,
          filename: 'video_$storyId.mp4',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return CloudinaryUploadResult(
          secureUrl: data['secure_url'] as String,
          publicId: data['public_id'] as String,
        );
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
