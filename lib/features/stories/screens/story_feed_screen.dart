import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/story_model.dart';
import '../providers/story_provider.dart';

/// Horizontal story avatar row (Instagram-style) displayed at top of map.
class StoryFeedWidget extends ConsumerWidget {
  final VoidCallback onAddStoryTap;

  const StoryFeedWidget({super.key, required this.onAddStoryTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedStories = ref.watch(groupedStoriesProvider);
    final myStories = ref.watch(myStoriesProvider).valueOrNull ?? [];

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        children: [
          // Add story button
          _StoryAvatar(
            name: 'Your Story',
            photoUrl: '',
            hasUnviewed: false,
            isAddButton: true,
            onTap: onAddStoryTap,
            storyCount: myStories.length,
          ),

          // Friend stories
          ...groupedStories.entries.map((entry) {
            final stories = entry.value;
            if (stories.isEmpty) return const SizedBox.shrink();
            final owner = stories.first;
            final currentUid = ''; // Will be filled by auth
            final hasUnviewed =
                stories.any((s) => !s.isViewedBy(currentUid));

            return _StoryAvatar(
              name: owner.ownerName,
              photoUrl: owner.ownerPhotoUrl,
              hasUnviewed: hasUnviewed,
              storyCount: stories.length,
              onTap: () => _openStoryViewer(context, stories),
            );
          }),
        ],
      ),
    );
  }

  void _openStoryViewer(BuildContext context, List<StoryModel> stories) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewerPage(stories: stories),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final String name;
  final String photoUrl;
  final bool hasUnviewed;
  final bool isAddButton;
  final VoidCallback onTap;
  final int storyCount;

  const _StoryAvatar({
    required this.name,
    required this.photoUrl,
    required this.hasUnviewed,
    this.isAddButton = false,
    required this.onTap,
    this.storyCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewed
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    )
                  : null,
                border: hasUnviewed
                  ? null
                  : Border.all(color: AppColors.divider, width: 2),
              ),
              padding: const EdgeInsets.all(2.5),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: photoUrl.isNotEmpty
                  ? CachedNetworkImageProvider(photoUrl)
                  : null,
                child: isAddButton
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    )
                  : photoUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.lexendDeca(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name.length > 8 ? '${name.substring(0, 8)}…' : name,
              style: GoogleFonts.lexendDeca(
                fontSize: 10,
                fontWeight:
                    hasUnviewed ? FontWeight.w600 : FontWeight.w400,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen story viewer with progress bar and auto-advance.
class StoryViewerPage extends ConsumerStatefulWidget {
  final List<StoryModel> stories;

  const StoryViewerPage({required this.stories, super.key});

  @override
  ConsumerState<StoryViewerPage> createState() => StoryViewerPageState();
}

class StoryViewerPageState extends ConsumerState<StoryViewerPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _progressController;
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStory();
        }
      });
    _startStory();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _startStory() {
    _progressController.reset();
    _isImageLoaded = false;

    // Mark as viewed
    final story = widget.stories[_currentIndex];
    ref.read(storyRepositoryProvider).markAsViewed(story.storyId);
  }

  void _onImageLoaded() {
    if (_isImageLoaded) return;
    _isImageLoaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _progressController.forward();
      }
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _startStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startStory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story image
            CachedNetworkImage(
              imageUrl: story.imageUrl,
              fit: BoxFit.contain,
              imageBuilder: (context, imageProvider) {
                _onImageLoaded();
                return Image(image: imageProvider, fit: BoxFit.contain);
              },
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (_, __, ___) {
                _onImageLoaded();
                return const Center(
                  child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                );
              },
            ),

            // Progress bars
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(widget.stories.length, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 3,
                      child: index == _currentIndex
                          ? AnimatedBuilder(
                              animation: _progressController,
                              builder: (_, __) => LinearProgressIndicator(
                                value: _progressController.value,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation(
                                    Colors.white),
                              ),
                            )
                          : Container(
                              color: index < _currentIndex
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                            ),
                    ),
                  );
                }),
              ),
            ),

            // Header (owner info + close)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: story.ownerPhotoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(story.ownerPhotoUrl)
                        : null,
                    child: story.ownerPhotoUrl.isEmpty
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      story.ownerName,
                      style: GoogleFonts.lexendDeca(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Caption
            if (story.caption.isNotEmpty)
              Positioned(
                bottom: 60,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    story.caption,
                    style: GoogleFonts.lexendDeca(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
