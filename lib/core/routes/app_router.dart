import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/profile_setup/setup_name_screen.dart';
import '../../features/profile_setup/setup_birthday_screen.dart';
import '../../features/profile_setup/setup_photo_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/friends/screens/add_friend_screen.dart';
import '../../features/friends/screens/friend_requests_screen.dart';
import '../../features/stories/screens/story_upload_screen.dart';
import '../../features/permissions/screens/location_permission_screen.dart';
import '../../features/permissions/screens/notification_permission_screen.dart';

/// Route name constants
class AppRoutes {
  static const splash = '/';
  static const auth = '/auth';
  static const setupName = '/setup/name';
  static const setupBirthday = '/setup/birthday';
  static const setupPhoto = '/setup/photo';
  static const home = '/home';
  static const addFriend = '/friends/add';
  static const friendRequests = '/friends/requests';
  static const storyUpload = '/stories/upload';
  static const permissionsLocation = '/permissions/location';
  static const permissionsNotifications = '/permissions/notifications';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupName,
        builder: (context, state) => const SetupNameScreen(),
      ),
      GoRoute(
        path: AppRoutes.setupBirthday,
        builder: (context, state) {
          final name = state.extra as String? ?? '';
          return SetupBirthdayScreen(displayName: name);
        },
      ),
      GoRoute(
        path: AppRoutes.setupPhoto,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return SetupPhotoScreen(
            displayName: args['name'] as String? ?? '',
            birthday: args['birthday'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.addFriend,
        builder: (context, state) => const AddFriendScreen(),
      ),
      GoRoute(
        path: AppRoutes.friendRequests,
        builder: (context, state) => const FriendRequestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.storyUpload,
        builder: (context, state) => const StoryUploadScreen(),
      ),
      GoRoute(
        path: AppRoutes.permissionsLocation,
        builder: (context, state) => const LocationPermissionScreen(),
      ),
      GoRoute(
        path: AppRoutes.permissionsNotifications,
        builder: (context, state) => const NotificationPermissionScreen(),
      ),
    ],
  );
});
