import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/friend_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../map/providers/map_provider.dart';

class FriendListScreen extends ConsumerWidget {
  const FriendListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendListProvider);
    final pendingAsync = ref.watch(pendingRequestsProvider);

    return Column(
      children: [
        // Pending requests banner
        pendingAsync.when(
          data: (requests) {
            if (requests.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Text(
                      '${requests.length}',
                      style: GoogleFonts.lexendDeca(
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  'Friend Requests',
                  style: GoogleFonts.lexendDeca(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${requests.length} pending',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                onTap: () =>
                    context.push('/friends/requests'),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 8),

        // Friends list
        Expanded(
          child: friendsAsync.when(
            data: (friends) {
              if (friends.isEmpty) {
                return _EmptyFriendsState();
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(friendListProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    return _FriendTile(friend: friends[index]);
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (error, stackTrace) {
              if (kDebugMode) {
                print('Error in friendListProvider: $error\n$stackTrace');
              }
              return Center(
                child: Text(
                  'Failed to load friends',
                  style: GoogleFonts.lexendDeca(color: AppColors.textSecondary),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FriendTile extends ConsumerWidget {
  final UserModel friend;

  const _FriendTile({required this.friend});

  String _getRelativeTime(int timestamp) {
    if (timestamp == 0) return 'Offline';
    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = now - timestamp;

    if (difference < 0) return 'Just now';

    final seconds = difference ~/ 1000;
    if (seconds < 60) return 'Just now';

    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m ago';

    final hours = minutes ~/ 60;
    if (hours < 24) return '${hours}h ago';

    final days = hours ~/ 24;
    return '${days}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(singleFriendLocationProvider(friend.uid));

    return locationAsync.maybeWhen(
      data: (location) {
        final bool isOnline = location?.isOnline ?? false;
        final bool isStale = location?.isStale ?? true;
        final bool activeOnline = isOnline && !isStale;
        final int lastUpdated = location?.lastUpdated ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: friend.photoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(friend.photoUrl)
                      : null,
                  child: friend.photoUrl.isEmpty
                      ? Text(
                          friend.displayName.isNotEmpty
                              ? friend.displayName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.lexendDeca(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: activeOnline ? AppColors.success : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              friend.displayName,
              style: GoogleFonts.lexendDeca(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Row(
              children: [
                Text(
                  '@${friend.username}',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '•',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    activeOnline ? 'Online' : _getRelativeTime(lastUpdated),
                    style: GoogleFonts.lexendDeca(
                      fontSize: 12,
                      fontWeight: activeOnline ? FontWeight.w600 : FontWeight.w400,
                      color: activeOnline ? AppColors.success : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.location_on_outlined,
                color: activeOnline
                    ? AppColors.primary
                    : AppColors.textHint,
              ),
              onPressed: () {
                if (location != null) {
                  ref.read(homeTabIndexProvider.notifier).state = 0;
                  ref.read(mapFocusTargetProvider.notifier).state =
                      LatLng(location.lat, location.lng);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${friend.displayName}\'s location is not available.'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
      orElse: () => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: friend.photoUrl.isNotEmpty
                ? CachedNetworkImageProvider(friend.photoUrl)
                : null,
            child: friend.photoUrl.isEmpty
                ? Text(
                    friend.displayName.isNotEmpty
                        ? friend.displayName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.lexendDeca(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          title: Text(
            friend.displayName,
            style: GoogleFonts.lexendDeca(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            '@${friend.username}',
            style: GoogleFonts.lexendDeca(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(
              Icons.location_on_outlined,
              color: AppColors.textHint,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${friend.displayName}\'s location is not available.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyFriendsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No friends yet',
            style: GoogleFonts.lexendDeca(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add friends to see them on the map!',
            style: GoogleFonts.lexendDeca(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
