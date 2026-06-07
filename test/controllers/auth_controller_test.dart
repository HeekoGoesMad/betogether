import 'package:flutter_test/flutter_test.dart';
import 'package:betogether/features/auth/auth_controller.dart';

void main() {
  group('AuthController', () {
    late AuthController controller;

    setUp(() {
      controller = AuthController();
    });

    test('initial state is sign up mode', () {
      expect(controller.state.mode, AuthMode.signUp);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.isGoogleLoading, isFalse);
      expect(controller.state.errorMessage, isNull);
    });

    test('toggleMode switches from signUp to signIn', () {
      controller.toggleMode();

      expect(controller.state.mode, AuthMode.signIn);
    });

    test('toggleMode switches from signIn to signUp', () {
      controller.toggleMode(); // signUp → signIn
      controller.toggleMode(); // signIn → signUp

      expect(controller.state.mode, AuthMode.signUp);
    });

    test('toggleMode clears error message', () {
      // Manually set error state
      controller.state = AuthState(
        mode: AuthMode.signUp,
        errorMessage: 'Some error',
      );

      controller.toggleMode();

      expect(controller.state.errorMessage, isNull);
    });

    test('clearError removes error message', () {
      controller.state = AuthState(errorMessage: 'Error!');

      controller.clearError();

      expect(controller.state.errorMessage, isNull);
    });
  });

  group('AuthState', () {
    test('default state has correct values', () {
      const state = AuthState();

      expect(state.isLoading, isFalse);
      expect(state.isGoogleLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.mode, AuthMode.signUp);
    });

    test('copyWith preserves unmodified fields', () {
      const original = AuthState(
        isLoading: true,
        isGoogleLoading: true,
        errorMessage: 'error',
        mode: AuthMode.signIn,
      );

      final copy = original.copyWith();

      expect(copy.isLoading, isTrue);
      expect(copy.isGoogleLoading, isTrue);
      expect(copy.errorMessage, 'error');
      expect(copy.mode, AuthMode.signIn);
    });

    test('copyWith overrides specified fields', () {
      const original = AuthState(isLoading: true, mode: AuthMode.signUp);

      final modified = original.copyWith(
        isLoading: false,
        errorMessage: 'new error',
      );

      expect(modified.isLoading, isFalse);
      expect(modified.errorMessage, 'new error');
      expect(modified.mode, AuthMode.signUp); // unchanged
    });

    test('copyWith clearError removes error', () {
      const withError = AuthState(errorMessage: 'has error');

      final cleared = withError.copyWith(clearError: true);

      expect(cleared.errorMessage, isNull);
    });

    test('copyWith clearError overrides new error message', () {
      const state = AuthState(errorMessage: 'old');

      final result = state.copyWith(
        errorMessage: 'new',
        clearError: true,
      );

      expect(result.errorMessage, isNull);
    });
  });

  group('AuthMode', () {
    test('has correct values', () {
      expect(AuthMode.values.length, 2);
      expect(AuthMode.signIn.name, 'signIn');
      expect(AuthMode.signUp.name, 'signUp');
    });
  });
}
