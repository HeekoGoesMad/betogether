import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/models/story_model.dart';
import '../providers/map_provider.dart';
import '../../friends/providers/friend_provider.dart';
import '../../stories/screens/story_feed_screen.dart';
import '../../stories/providers/story_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(0, 0);
  bool _isInitialized = false;
  bool _isFollowingUser = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLocation();
    _registerViewers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unregisterViewers();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _unregisterViewers();
    } else if (state == AppLifecycleState.resumed) {
      _registerViewers();
    }
  }

  Future<void> _initLocation() async {
    final hasPermission = await LocationService.checkPermission();
    if (!hasPermission) {
      await LocationService.requestPermission();
    }

    final position = await LocationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isInitialized = true;
      });
    }

    // Start streaming location updates — use active foreground interval (-1)
    LocationService.startSmartTracking(
      viewerCount: -1, // Active foreground: fastest 5s interval
      onPosition: (pos) {
        if (!mounted) return;
        final newPos = LatLng(pos.latitude, pos.longitude);
        setState(() => _currentPosition = newPos);

        // Upload to RTDB
        final repo = ref.read(locationRepositoryProvider);
        repo.updateMyLocation(pos.latitude, pos.longitude);

        // Follow user on map
        if (_isFollowingUser) {
          _mapController.move(newPos, _mapController.camera.zoom);
        }
      },
      onPaused: () {
        // GPS paused due to inactivity — user is stationary
      },
    );
  }

  /// Register as viewer for all friends (triggers their GPS).
  void _registerViewers() {
    final friendUids = ref.read(friendUidsProvider).valueOrNull ?? [];
    final repo = ref.read(locationRepositoryProvider);
    for (final uid in friendUids) {
      repo.registerViewing(uid);
    }
    repo.setupPresence();
  }

  /// Unregister viewing when leaving map.
  void _unregisterViewers() {
    final friendUids = ref.read(friendUidsProvider).valueOrNull ?? [];
    final repo = ref.read(locationRepositoryProvider);
    for (final uid in friendUids) {
      repo.unregisterViewing(uid);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    // Listen to focus target from other screens (like Friends List)
    ref.listen<LatLng?>(mapFocusTargetProvider, (prev, next) {
      if (next != null) {
        _mapController.move(next, 16.0);
        setState(() => _isFollowingUser = false);
        Future.microtask(() {
          ref.read(mapFocusTargetProvider.notifier).state = null;
        });
      }
    });

    final friendUids = ref.watch(friendUidsProvider).valueOrNull ?? [];
    final friendLocations =
        ref.watch(friendLocationsProvider(friendUids)).valueOrNull ?? {};
    final friends = ref.watch(friendListProvider).valueOrNull ?? [];
    final groupedStories = ref.watch(groupedStoriesProvider);

    final currentUserUid = FirebaseService.auth.currentUser?.uid ?? '';
    final currentUserDisplayName = FirebaseService.auth.currentUser?.displayName ?? 'You';
    final currentUserPhotoUrl = FirebaseService.auth.currentUser?.photoURL ?? '';
    final allFriendUids = friends.map((f) => f.uid).toList();

    final allMapUsers = <_MapUser>[];

    // Add current user to map users list
    if (_isInitialized) {
      allMapUsers.add(
        _MapUser(
          uid: currentUserUid,
          displayName: currentUserDisplayName,
          photoUrl: currentUserPhotoUrl,
          position: _currentPosition,
          friendUids: allFriendUids,
          isOnline: true,
          isStale: false,
          lastUpdated: DateTime.now().millisecondsSinceEpoch,
          isCurrentUser: true,
        ),
      );
    }

    // Add friends to map users list
    for (final entry in friendLocations.entries) {
      final friendData = friends.where((f) => f.uid == entry.key);
      final friend = friendData.isNotEmpty ? friendData.first : null;
      if (friend == null) continue;

      allMapUsers.add(
        _MapUser(
          uid: entry.key,
          displayName: friend.displayName,
          photoUrl: friend.photoUrl,
          position: LatLng(entry.value.lat, entry.value.lng),
          friendUids: friend.friends,
          isOnline: entry.value.isOnline,
          isStale: entry.value.isStale,
          lastUpdated: entry.value.lastUpdated,
        ),
      );
    }

    // Cluster users within 25 meters of each other
    final groups = <List<_MapUser>>[];
    final remainingUsers = List<_MapUser>.from(allMapUsers);

    while (remainingUsers.isNotEmpty) {
      final first = remainingUsers.removeAt(0);
      final currentGroup = [first];

      for (int i = remainingUsers.length - 1; i >= 0; i--) {
        final other = remainingUsers[i];
        final distance = LocationService.calculateDistance(
          first.position.latitude,
          first.position.longitude,
          other.position.latitude,
          other.position.longitude,
        );

        if (distance <= 25.0) {
          currentGroup.add(other);
          remainingUsers.removeAt(i);
        }
      }
      groups.add(currentGroup);
    }

    // Convert groups to map markers
    final markers = <Marker>[];
    for (final group in groups) {
      if (group.isEmpty) continue;

      if (group.length == 1) {
        final u = group[0];
        if (u.isCurrentUser) {
          markers.add(
            Marker(
              point: u.position,
              width: 32,
              height: 32,
              child: _CurrentUserMarker(),
            ),
          );
        } else {
          final friendStories = groupedStories[u.uid] ?? [];
          final hasStories = friendStories.isNotEmpty;
          markers.add(
            Marker(
              point: u.position,
              width: 96,
              height: 96,
              child: GestureDetector(
                onTap: () {
                  if (hasStories) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoryViewerPage(stories: friendStories),
                      ),
                    );
                  }
                },
                child: _FriendMarkerWidget(
                  name: u.displayName,
                  photoUrl: u.photoUrl,
                  isOnline: u.isOnline,
                  isStale: u.isStale,
                  hasStories: hasStories,
                  lastUpdated: u.lastUpdated,
                ),
              ),
            ),
          );
        }
      } else {
        // Collided group marker
        final avgPos = _getAveragePosition(group);
        bool hasFriendship = false;
        for (int i = 0; i < group.length; i++) {
          for (int j = i + 1; j < group.length; j++) {
            final u1 = group[i];
            final u2 = group[j];
            if (u1.friendUids.contains(u2.uid) || u2.friendUids.contains(u1.uid)) {
              hasFriendship = true;
              break;
            }
          }
          if (hasFriendship) break;
        }

        final groupOnline = group.any((u) => u.isOnline && !u.isStale);
        final groupLastUpdated = group.fold<int>(0, (prev, u) => u.lastUpdated > prev ? u.lastUpdated : prev);

        markers.add(
          Marker(
            point: avgPos,
            width: 120,
            height: 120,
            child: GestureDetector(
              onTap: () => _showGroupDetails(context, group, groupedStories),
              child: _GroupMarkerWidget(
                group: group,
                hasFriends: hasFriendship,
                isOnline: groupOnline,
                lastUpdated: groupLastUpdated,
              ),
            ),
          ),
        );
      }
    }

    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter:
                _isInitialized ? _currentPosition : const LatLng(0, 0),
            initialZoom: 15.0,
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture && _isFollowingUser) {
                setState(() => _isFollowingUser = false);
              }
            },
          ),
          children: [
            // OpenStreetMap tile layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.betogether',
              maxZoom: 19,
            ),

            // Markers layer
            MarkerLayer(
              markers: markers,
            ),
          ],
        ),

        // Back to My Location pill
        if (!_isFollowingUser)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _isFollowingUser ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 120),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isFollowingUser = true;
                      _mapController.move(_currentPosition, 15.0);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.my_location,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Back to My Location',
                          style: GoogleFonts.lexendDeca(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  LatLng _getAveragePosition(List<_MapUser> group) {
    double sumLat = 0.0;
    double sumLng = 0.0;
    for (final u in group) {
      sumLat += u.position.latitude;
      sumLng += u.position.longitude;
    }
    return LatLng(sumLat / group.length, sumLng / group.length);
  }

  void _showGroupDetails(BuildContext context, List<_MapUser> group, Map<String, List<StoryModel>> groupedStories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hanging Out Here',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: group.length,
                    itemBuilder: (context, index) {
                      final user = group[index];
                      final stories = groupedStories[user.uid] ?? [];
                      final hasStories = stories.isNotEmpty;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundImage: user.photoUrl.isNotEmpty
                              ? CachedNetworkImageProvider(user.photoUrl)
                              : null,
                          child: user.photoUrl.isEmpty
                              ? Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?')
                              : null,
                        ),
                        title: Text(
                          user.displayName,
                          style: GoogleFonts.lexendDeca(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          user.isCurrentUser ? 'You' : (user.isOnline && !user.isStale ? 'Online' : 'Offline'),
                          style: GoogleFonts.lexendDeca(
                            fontSize: 12,
                            color: user.isOnline && !user.isStale
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                        trailing: hasStories
                            ? ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StoryViewerPage(stories: stories),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  minimumSize: const Size(60, 32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'View Story',
                                  style: GoogleFonts.lexendDeca(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Pulsing blue dot for current user's location.
class _CurrentUserMarker extends StatefulWidget {
  @override
  State<_CurrentUserMarker> createState() => _CurrentUserMarkerState();
}

class _CurrentUserMarkerState extends State<_CurrentUserMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.2 * _animation.value),
          ),
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom map marker for a friend showing their avatar.
class _FriendMarkerWidget extends StatelessWidget {
  final String name;
  final String photoUrl;
  final bool isOnline;
  final bool isStale;
  final bool hasStories;
  final int lastUpdated;

  const _FriendMarkerWidget({
    required this.name,
    required this.photoUrl,
    required this.isOnline,
    required this.lastUpdated,
    this.isStale = false,
    this.hasStories = false,
  });

  String _getRelativeTime(int timestamp) {
    if (timestamp == 0) return 'Offline';
    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = now - timestamp;

    if (difference < 0) return 'Just now'; // Safety check for small clock desyncs

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
  Widget build(BuildContext context) {
    final bool activeOnline = isOnline && !isStale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with status ring / story gradient
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: hasStories
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  )
                : null,
            border: hasStories
                ? null
                : Border.all(
                    color: isStale
                        ? Colors.grey
                        : isOnline
                            ? AppColors.success
                            : Colors.grey.shade400,
                    width: 3,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: hasStories ? const EdgeInsets.all(3) : EdgeInsets.zero,
          child: ClipOval(
            child: photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 20),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 20),
                    ),
                  )
                : Container(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 20),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        // Name and Status label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name.length > 10 ? '${name.substring(0, 10)}…' : name,
                style: GoogleFonts.lexendDeca(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeOnline ? AppColors.success : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    activeOnline ? 'Online' : _getRelativeTime(lastUpdated),
                    style: GoogleFonts.lexendDeca(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: activeOnline ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapUser {
  final String uid;
  final String displayName;
  final String photoUrl;
  final LatLng position;
  final List<String> friendUids;
  final bool isOnline;
  final bool isStale;
  final int lastUpdated;
  final bool isCurrentUser;

  _MapUser({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.position,
    required this.friendUids,
    this.isOnline = false,
    this.isStale = false,
    this.lastUpdated = 0,
    this.isCurrentUser = false,
  });
}

class _GroupMarkerWidget extends StatelessWidget {
  final List<_MapUser> group;
  final bool hasFriends;
  final bool isOnline;
  final int lastUpdated;

  const _GroupMarkerWidget({
    required this.group,
    required this.hasFriends,
    required this.isOnline,
    required this.lastUpdated,
  });

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

  String _getGroupNames() {
    if (group.length == 2) {
      return '${group[0].displayName} & ${group[1].displayName}';
    }
    return '${group[0].displayName}, ${group[1].displayName} +${group.length - 2}';
  }

  @override
  Widget build(BuildContext context) {
    final displayCount = group.length > 3 ? 3 : group.length;
    final groupNames = _getGroupNames();

    final Widget facePile = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(displayCount, (index) {
          final user = group[index];
          return Align(
            widthFactor: 0.6,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: user.photoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(user.photoUrl)
                    : null,
                child: user.photoUrl.isEmpty
                    ? Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.lexendDeca(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
            ),
          );
        }),
        if (group.length > 3)
          Align(
            widthFactor: 0.6,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '+${group.length - 3}',
                  style: GoogleFonts.lexendDeca(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    final Widget animatedBody = hasFriends
        ? _FlameAnimationWidget(child: facePile)
        : _BasicGroupWidget(child: facePile);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        animatedBody,
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                groupNames.length > 18 ? '${groupNames.substring(0, 16)}…' : groupNames,
                style: GoogleFonts.lexendDeca(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? AppColors.success : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOnline ? 'Online' : _getRelativeTime(lastUpdated),
                    style: GoogleFonts.lexendDeca(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: isOnline ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlameAnimationWidget extends StatefulWidget {
  final Widget child;
  const _FlameAnimationWidget({required this.child});

  @override
  State<_FlameAnimationWidget> createState() => _FlameAnimationWidgetState();
}

class _FlameAnimationWidgetState extends State<_FlameAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: _glow.value * 0.4),
                blurRadius: 16,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.red.withValues(alpha: _glow.value * 0.2),
                blurRadius: 28,
                spreadRadius: 8,
              ),
            ],
          ),
          child: ScaleTransition(
            scale: _scale,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                widget.child,
                Positioned(
                  top: -14,
                  right: -8,
                  child: Transform.rotate(
                    angle: -0.1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.orange, Colors.redAccent],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '🔥',
                            style: TextStyle(fontSize: 10),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Hanging Out',
                            style: GoogleFonts.lexendDeca(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BasicGroupWidget extends StatelessWidget {
  final Widget child;
  const _BasicGroupWidget({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            top: -12,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.group,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
