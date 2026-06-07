import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/friend_provider.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingRequestsProvider);
    final actionState = ref.watch(friendActionProvider);

    ref.listen<FriendActionState>(friendActionProvider, (prev, next) {
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Friend Requests',
          style: GoogleFonts.lexendDeca(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
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
                      Icons.mail_outline,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending requests',
                    style: GoogleFonts.lexendDeca(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "When someone adds you, you'll see it here",
                    style: GoogleFonts.lexendDeca(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: request.fromPhotoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(request.fromPhotoUrl)
                            : null,
                        child: request.fromPhotoUrl.isEmpty
                            ? Text(
                                request.fromName.isNotEmpty
                                    ? request.fromName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.lexendDeca(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      // Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.fromName,
                              style: GoogleFonts.lexendDeca(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Wants to be your friend',
                              style: GoogleFonts.lexendDeca(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Accept / Reject buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Accept
                          SizedBox(
                            height: 36,
                            width: 36,
                            child: IconButton.filled(
                              onPressed: actionState.isLoading
                                  ? null
                                  : () {
                                      ref
                                          .read(friendActionProvider.notifier)
                                          .acceptRequest(request.id);
                                    },
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.success,
                              ),
                              icon: const Icon(Icons.check,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Reject
                          SizedBox(
                            height: 36,
                            width: 36,
                            child: IconButton.outlined(
                              onPressed: actionState.isLoading
                                  ? null
                                  : () {
                                      ref
                                          .read(friendActionProvider.notifier)
                                          .rejectRequest(request.id);
                                    },
                              style: IconButton.styleFrom(
                                side: BorderSide(
                                  color: AppColors.error.withValues(alpha: 0.4),
                                ),
                              ),
                              icon: Icon(Icons.close,
                                  size: 18,
                                  color:
                                      AppColors.error.withValues(alpha: 0.8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => Center(
          child: Text(
            'Failed to load requests',
            style: GoogleFonts.lexendDeca(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
