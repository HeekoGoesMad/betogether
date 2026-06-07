import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/routes/app_router.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isUploading = false;
  final _picker = ImagePicker();

  Future<void> _pickAndUploadPhoto() async {
    if (_isUploading) return;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() => _isUploading = true);

      final user = FirebaseService.auth.currentUser;
      if (user == null) {
        setState(() => _isUploading = false);
        return;
      }

      final file = File(picked.path);
      final bytes = await file.readAsBytes();

      final result = await CloudinaryService.uploadAvatar(
        bytes,
        userId: user.uid,
      );

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to upload photo.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        setState(() => _isUploading = false);
        return;
      }

      final newPhotoUrl = result.secureUrl;

      // Update Firestore profile
      await FirebaseService.firestore.collection('users').doc(user.uid).update({
        'photoUrl': newPhotoUrl,
      });

      // Update FirebaseAuth photoUrl
      await user.updatePhotoURL(newPhotoUrl);

      // Refresh profile data
      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile photo updated successfully! 🎉'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  static const _prompts = [
    "What's new...",
    "Share a vibe!",
    "Today's story?",
    "Post a moment",
    "What's up?",
    "Add a note...",
    "Share the day!",
    "How's it going?"
  ];
  late final String _storyPrompt;

  @override
  void initState() {
    super.initState();
    _storyPrompt = (List<String>.from(_prompts)..shuffle()).first;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await FirebaseService.getUserProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseService.auth.signOut();
    if (!mounted) return;
    context.go(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final name = _profile?['displayName'] as String? ?? 'User';
    final email = _profile?['email'] as String? ?? '';
    final photoUrl = _profile?['photoUrl'] as String? ?? '';
    final username = _profile?['username'] as String? ?? '';
    final friends = _profile?['friends'] as List? ?? [];
    final birthday = _profile?['birthday'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Avatar with Thought Bubble Badge.
          // Use a fixed-size Stack so the bubble is WITHIN Flutter's hit-test
          // bounds (children outside a Stack's layout box are never tappable).
          SizedBox(
            width: 160,
            height: 158, // 110 avatar + 48 bubble space above
            child: Stack(
              children: [
                // Thought bubble — top-left, fully within bounds
                Positioned(
                  top: 4,
                  left: 4,
                  child: _ThoughtBubble(
                    text: _storyPrompt,
                    onTap: () => context.push(AppRoutes.storyUpload),
                  ),
                ),
                // Avatar — bottom-center of the SizedBox
                Positioned(
                  bottom: 0,
                  left: 25, // (160 - 110) / 2
                  child: GestureDetector(
                    onTap: () => context.push(AppRoutes.storyUpload),
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.brandGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: Colors.white,
                        backgroundImage: photoUrl.isNotEmpty &&
                                !photoUrl.startsWith('data:')
                            ? CachedNetworkImageProvider(photoUrl)
                            : null,
                        child: photoUrl.isEmpty || photoUrl.startsWith('data:')
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: GoogleFonts.lexendDeca(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            name,
            style: GoogleFonts.lexendDeca(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (username.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: GoogleFonts.lexendDeca(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(
                  value: '${friends.length}',
                  label: 'Friends',
                  icon: Icons.people_outline,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.divider,
                ),
                _StatItem(
                  value: birthday,
                  label: 'Birthday',
                  icon: Icons.cake_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: _pickAndUploadPhoto,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_camera_outlined, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profile Photo',
                                style: GoogleFonts.lexendDeca(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                              ),
                              Text(
                                _isUploading ? 'Uploading new photo...' : 'Tap to change photo',
                                style: GoogleFonts.lexendDeca(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _isUploading ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isUploading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        else
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: ClipOval(
                              child: photoUrl.isNotEmpty && !photoUrl.startsWith('data:')
                                  ? CachedNetworkImage(
                                      imageUrl: photoUrl,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.person, size: 20, color: AppColors.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24, color: AppColors.divider),
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: email,
                ),
                const Divider(height: 24, color: AppColors.divider),
                _InfoRow(
                  icon: Icons.fingerprint,
                  label: 'User ID',
                  value: FirebaseService.auth.currentUser?.uid
                          .substring(0, 12) ??
                      '',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Sign out button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, size: 18),
              label: Text(
                'Sign Out',
                style: GoogleFonts.lexendDeca(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.lexendDeca(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.lexendDeca(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.lexendDeca(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
            Text(
              value.isNotEmpty ? value : '—',
              style: GoogleFonts.lexendDeca(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ThoughtBubble extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _ThoughtBubble({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF4FF), // light blue-gray
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Text(
              text,
              style: GoogleFonts.lexendDeca(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Tail: medium circle — bottom-right corner pointing toward profile pic
          Positioned(
            bottom: -7,
            right: 10,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Color(0xFFEDF4FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Tail: small circle
          Positioned(
            bottom: -14,
            right: 4,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFEDF4FF),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
