import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/friend_request_model.dart';
import '../repositories/friend_repository.dart';

/// Provider for the friend repository.
final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository();
});

/// Stream of current user's friends as UserModel list.
final friendListProvider = StreamProvider<List<UserModel>>((ref) {
  final repo = ref.watch(friendRepositoryProvider);
  return repo.getFriendsList();
});

/// Stream of current user's friend UIDs.
final friendUidsProvider = StreamProvider<List<String>>((ref) {
  final repo = ref.watch(friendRepositoryProvider);
  return repo.getFriendUids();
});

/// Stream of incoming pending friend requests.
final pendingRequestsProvider = StreamProvider<List<FriendRequestModel>>((ref) {
  final repo = ref.watch(friendRepositoryProvider);
  return repo.getPendingRequests();
});

/// State for friend actions (send, accept, reject).
class FriendActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const FriendActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  FriendActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return FriendActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class FriendActionController extends StateNotifier<FriendActionState> {
  final FriendRepository _repo;

  FriendActionController(this._repo) : super(const FriendActionState());

  Future<void> sendRequest(String toUid) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    final result = await _repo.sendFriendRequest(toUid);
    if (result != null) {
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Friend request sent!',
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not send request. Maybe already sent?',
      );
    }
  }

  Future<void> acceptRequest(String requestId) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    final success = await _repo.acceptRequest(requestId);
    state = state.copyWith(
      isLoading: false,
      successMessage: success ? 'Friend added! 🎉' : null,
      errorMessage: success ? null : 'Failed to accept request.',
    );
  }

  Future<void> rejectRequest(String requestId) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    final success = await _repo.rejectRequest(requestId);
    state = state.copyWith(
      isLoading: false,
      successMessage: success ? 'Request declined.' : null,
      errorMessage: success ? null : 'Failed to decline request.',
    );
  }

  Future<void> removeFriend(String friendUid) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    final success = await _repo.removeFriend(friendUid);
    state = state.copyWith(
      isLoading: false,
      successMessage: success ? 'Friend removed.' : null,
      errorMessage: success ? null : 'Failed to remove friend.',
    );
  }

  void clearMessages() => state = state.copyWith(clearMessages: true);
}

final friendActionProvider =
    StateNotifierProvider<FriendActionController, FriendActionState>((ref) {
  final repo = ref.watch(friendRepositoryProvider);
  return FriendActionController(repo);
});

/// Search results provider.
final friendSearchProvider =
    FutureProvider.family<List<UserModel>, String>((ref, query) {
  final repo = ref.watch(friendRepositoryProvider);
  return repo.searchByUsername(query);
});
