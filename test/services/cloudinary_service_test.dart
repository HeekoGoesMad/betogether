import 'package:flutter_test/flutter_test.dart';
import 'package:betogether/core/constants/cloudinary_config.dart';

void main() {
  group('CloudinaryConfig', () {
    test('cloud name is configured', () {
      expect(CloudinaryConfig.cloudName, 'dztravbro');
    });

    test('upload preset is configured', () {
      expect(CloudinaryConfig.uploadPreset, 'betogether_uploads');
    });

    test('image upload URL is correct', () {
      expect(
        CloudinaryConfig.imageUploadUrl,
        'https://api.cloudinary.com/v1_1/dztravbro/image/upload',
      );
    });

    test('video upload URL is correct', () {
      expect(
        CloudinaryConfig.videoUploadUrl,
        'https://api.cloudinary.com/v1_1/dztravbro/video/upload',
      );
    });

    test('avatar folder is set', () {
      expect(CloudinaryConfig.avatarFolder, 'betogether/avatars');
    });

    test('story folder is set', () {
      expect(CloudinaryConfig.storyFolder, 'betogether/stories');
    });
  });

  group('CloudinaryService URL format', () {
    test('upload URL contains cloud name', () {
      expect(CloudinaryConfig.imageUploadUrl, contains('dztravbro'));
    });

    test('upload URL uses HTTPS', () {
      expect(CloudinaryConfig.imageUploadUrl, startsWith('https://'));
    });

    test('upload URL targets correct API version', () {
      expect(CloudinaryConfig.imageUploadUrl, contains('/v1_1/'));
    });
  });
}
