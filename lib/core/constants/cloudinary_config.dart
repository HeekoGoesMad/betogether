/// Cloudinary configuration for BeTogether media uploads.
///
/// Uses unsigned upload preset — no server-side signing required.
/// All media (avatars, stories) are uploaded to Cloudinary instead of Firebase Storage.
class CloudinaryConfig {
  CloudinaryConfig._();

  /// Your Cloudinary cloud name
  static const String cloudName = 'dztravbro';

  /// Unsigned upload preset (created in Cloudinary Dashboard)
  static const String uploadPreset = 'betogether_uploads';

  /// Base upload URL for image uploads
  static String get imageUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Base upload URL for video uploads
  static String get videoUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/video/upload';

  /// Folder paths for organizing media
  static const String avatarFolder = 'betogether/avatars';
  static const String storyFolder = 'betogether/stories';
}
