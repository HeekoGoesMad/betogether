import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/story_model.dart';
import '../../friends/providers/friend_provider.dart';
import '../repositories/story_repository.dart';

/// Provider for the story repository.
final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepository();
});

/// Stream of stories from friends (non-expired).
final friendStoriesProvider = StreamProvider<List<StoryModel>>((ref) {
  final friendUidsAsync = ref.watch(friendUidsProvider);
  final repo = ref.watch(storyRepositoryProvider);

  return friendUidsAsync.when(
    data: (uids) => repo.getFriendStories(uids),
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Stream of current user's own stories.
final myStoriesProvider = StreamProvider<List<StoryModel>>((ref) {
  final repo = ref.watch(storyRepositoryProvider);
  return repo.getMyStories();
});

/// Stories grouped by owner UID for feed display.
final groupedStoriesProvider = Provider<Map<String, List<StoryModel>>>((ref) {
  final storiesAsync = ref.watch(friendStoriesProvider);

  return storiesAsync.when(
    data: (stories) {
      final grouped = <String, List<StoryModel>>{};
      for (final story in stories) {
        grouped.putIfAbsent(story.ownerId, () => []).add(story);
      }
      return grouped;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

/// State for story upload.
class StoryUploadState {
  final bool isUploading;
  final double progress;
  final String? errorMessage;
  final StoryModel? uploadedStory;

  const StoryUploadState({
    this.isUploading = false,
    this.progress = 0.0,
    this.errorMessage,
    this.uploadedStory,
  });

  StoryUploadState copyWith({
    bool? isUploading,
    double? progress,
    String? errorMessage,
    StoryModel? uploadedStory,
    bool clearError = false,
  }) {
    return StoryUploadState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      uploadedStory: uploadedStory ?? this.uploadedStory,
    );
  }
}

class StoryUploadController extends StateNotifier<StoryUploadState> {
  final StoryRepository _repo;

  StoryUploadController(this._repo) : super(const StoryUploadState());

  Future<StoryModel?> uploadStory(
    Uint8List imageBytes, {
    String caption = '',
  }) async {
    state = state.copyWith(isUploading: true, progress: 0.1, clearError: true);

    state = state.copyWith(progress: 0.3); // Compressing
    final story = await _repo.uploadStory(imageBytes, caption: caption);

    if (story != null) {
      state = state.copyWith(
        isUploading: false,
        progress: 1.0,
        uploadedStory: story,
      );
    } else {
      state = state.copyWith(
        isUploading: false,
        progress: 0.0,
        errorMessage: 'Failed to upload story. Please try again.',
      );
    }
    return story;
  }

  void reset() => state = const StoryUploadState();
}

final storyUploadProvider =
    StateNotifierProvider<StoryUploadController, StoryUploadState>((ref) {
  final repo = ref.watch(storyRepositoryProvider);
  return StoryUploadController(repo);
});
