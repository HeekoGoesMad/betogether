import 'package:flutter_test/flutter_test.dart';
import 'package:betogether/features/profile_setup/profile_setup_controller.dart';

void main() {
  group('ProfileSetupController', () {
    late ProfileSetupController controller;

    setUp(() {
      controller = ProfileSetupController();
    });

    test('initial state is idle', () {
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.uploadedPhotoUrl, isNull);
    });
  });

  group('ProfileSetupState', () {
    test('default state has correct values', () {
      const state = ProfileSetupState();

      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.uploadedPhotoUrl, isNull);
    });

    test('copyWith preserves unmodified fields', () {
      const original = ProfileSetupState(
        isLoading: true,
        errorMessage: 'error',
        uploadedPhotoUrl: 'https://example.com/photo.jpg',
      );

      final copy = original.copyWith();

      expect(copy.isLoading, isTrue);
      expect(copy.errorMessage, 'error');
      expect(copy.uploadedPhotoUrl, 'https://example.com/photo.jpg');
    });

    test('copyWith overrides specified fields', () {
      const original = ProfileSetupState(isLoading: true);

      final modified = original.copyWith(
        isLoading: false,
        uploadedPhotoUrl: 'https://cloudinary.com/new.jpg',
      );

      expect(modified.isLoading, isFalse);
      expect(modified.uploadedPhotoUrl, 'https://cloudinary.com/new.jpg');
    });

    test('copyWith clearError removes error', () {
      const withError = ProfileSetupState(errorMessage: 'Upload failed');

      final cleared = withError.copyWith(clearError: true);

      expect(cleared.errorMessage, isNull);
    });

    test('copyWith clearError takes priority over new error', () {
      const state = ProfileSetupState(errorMessage: 'old');

      final result = state.copyWith(
        errorMessage: 'new',
        clearError: true,
      );

      expect(result.errorMessage, isNull);
    });

    test('loading state transitions', () {
      const idle = ProfileSetupState();
      final loading = idle.copyWith(isLoading: true);
      final done = loading.copyWith(
        isLoading: false,
        uploadedPhotoUrl: 'https://res.cloudinary.com/dztravbro/avatar.jpg',
      );

      expect(idle.isLoading, isFalse);
      expect(loading.isLoading, isTrue);
      expect(done.isLoading, isFalse);
      expect(done.uploadedPhotoUrl, contains('cloudinary'));
    });

    test('error state transitions', () {
      const idle = ProfileSetupState();
      final loading = idle.copyWith(isLoading: true, clearError: true);
      final errored = loading.copyWith(
        isLoading: false,
        errorMessage: 'Network error',
      );
      final recovered = errored.copyWith(
        isLoading: true,
        clearError: true,
      );

      expect(loading.errorMessage, isNull);
      expect(errored.errorMessage, 'Network error');
      expect(recovered.errorMessage, isNull);
      expect(recovered.isLoading, isTrue);
    });
  });
}
