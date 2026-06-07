import 'package:flutter_test/flutter_test.dart';
import 'package:betogether/features/stories/providers/story_provider.dart';

void main() {
  group('StoryUploadState', () {
    test('default state has correct values', () {
      const state = StoryUploadState();

      expect(state.isUploading, isFalse);
      expect(state.progress, 0.0);
      expect(state.errorMessage, isNull);
      expect(state.uploadedStory, isNull);
    });

    test('copyWith preserves unmodified fields', () {
      const original = StoryUploadState(
        isUploading: true,
        progress: 0.5,
        errorMessage: 'error',
      );

      final copy = original.copyWith();

      expect(copy.isUploading, isTrue);
      expect(copy.progress, 0.5);
      expect(copy.errorMessage, 'error');
    });

    test('copyWith overrides specified fields', () {
      const original = StoryUploadState(isUploading: false);

      final modified = original.copyWith(
        isUploading: true,
        progress: 0.3,
      );

      expect(modified.isUploading, isTrue);
      expect(modified.progress, 0.3);
    });

    test('copyWith clearError removes error', () {
      const withError = StoryUploadState(errorMessage: 'Upload failed');

      final cleared = withError.copyWith(clearError: true);

      expect(cleared.errorMessage, isNull);
    });

    test('upload lifecycle state transitions', () {
      // Idle → Uploading → Complete
      const idle = StoryUploadState();
      expect(idle.isUploading, isFalse);
      expect(idle.progress, 0.0);

      final uploading = idle.copyWith(
        isUploading: true,
        progress: 0.1,
      );
      expect(uploading.isUploading, isTrue);
      expect(uploading.progress, 0.1);

      final progressing = uploading.copyWith(progress: 0.5);
      expect(progressing.progress, 0.5);
      expect(progressing.isUploading, isTrue);

      final completed = progressing.copyWith(
        isUploading: false,
        progress: 1.0,
      );
      expect(completed.isUploading, isFalse);
      expect(completed.progress, 1.0);
    });

    test('upload error state transition', () {
      const uploading = StoryUploadState(isUploading: true, progress: 0.3);

      final errored = uploading.copyWith(
        isUploading: false,
        progress: 0.0,
        errorMessage: 'Network error',
      );

      expect(errored.isUploading, isFalse);
      expect(errored.progress, 0.0);
      expect(errored.errorMessage, 'Network error');
    });

    test('retry after error clears error', () {
      const errored = StoryUploadState(
        errorMessage: 'Failed',
        progress: 0.0,
      );

      final retrying = errored.copyWith(
        isUploading: true,
        progress: 0.1,
        clearError: true,
      );

      expect(retrying.isUploading, isTrue);
      expect(retrying.errorMessage, isNull);
    });
  });
}
