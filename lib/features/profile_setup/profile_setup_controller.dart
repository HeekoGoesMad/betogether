import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/notification_service.dart';

class ProfileSetupState {
  final bool isLoading;
  final String? errorMessage;
  final String? uploadedPhotoUrl;

  const ProfileSetupState({
    this.isLoading = false,
    this.errorMessage,
    this.uploadedPhotoUrl,
  });

  ProfileSetupState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? uploadedPhotoUrl,
  }) {
    return ProfileSetupState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      uploadedPhotoUrl: uploadedPhotoUrl ?? this.uploadedPhotoUrl,
    );
  }
}

class ProfileSetupController extends StateNotifier<ProfileSetupState> {
  ProfileSetupController() : super(const ProfileSetupState());

  /// Compress and upload photo to Cloudinary.
  ///
  /// Returns the Cloudinary secure URL or null on failure.
  Future<String?> uploadPhoto(File imageFile) async {
    final user = FirebaseService.auth.currentUser;
    if (user == null) return null;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final bytes = await imageFile.readAsBytes();

      // Upload to Cloudinary (compression handled internally)
      final result = await CloudinaryService.uploadAvatar(
        bytes,
        userId: user.uid,
      );

      if (result == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to upload photo. Please try again.',
        );
        return null;
      }

      state = state.copyWith(
        isLoading: false,
        uploadedPhotoUrl: result.secureUrl,
      );
      return result.secureUrl;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to process photo. Please try again.',
      );
      return null;
    }
  }

  /// Complete profile setup and save to Firestore
  Future<bool> completeProfile({
    required String displayName,
    required String birthday,
    String? photoUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await FirebaseService.saveUserProfile(
        displayName: displayName,
        birthday: birthday,
        photoUrl: photoUrl,
      );
      // Also update Firebase Auth display name and sync FCM token
      final user = FirebaseService.auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        try {
          await NotificationService.updateToken(user.uid);
        } catch (_) {
          // Ignore failures to write token; user can still proceed
        }
      }
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save profile. Please try again.',
      );
      return false;
    }
  }
}

final profileSetupProvider =
    StateNotifierProvider<ProfileSetupController, ProfileSetupState>(
  (ref) => ProfileSetupController(),
);
