import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/location_service.dart';
import '../../shared/widgets/gradient_button.dart';
import 'profile_setup_controller.dart';

class SetupPhotoScreen extends ConsumerStatefulWidget {
  final String displayName;
  final String birthday;

  const SetupPhotoScreen({
    super.key,
    required this.displayName,
    required this.birthday,
  });

  @override
  ConsumerState<SetupPhotoScreen> createState() => _SetupPhotoScreenState();
}

class _SetupPhotoScreenState extends ConsumerState<SetupPhotoScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedImage;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _finish({bool skip = false}) async {
    final controller = ref.read(profileSetupProvider.notifier);
    String? photoUrl;

    if (!skip && _selectedImage != null) {
      photoUrl = await controller.uploadPhoto(_selectedImage!);
      if (!mounted) return;
      final setupState = ref.read(profileSetupProvider);
      if (setupState.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(setupState.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final success = await controller.completeProfile(
      displayName: widget.displayName,
      birthday: widget.birthday,
      photoUrl: photoUrl,
    );

    if (!mounted) return;
    if (success) {
      final locationGranted = await LocationService.checkPermissionStatus();
      if (!mounted) return;
      if (!locationGranted) {
        context.go(AppRoutes.permissionsLocation);
      } else {
        final notificationGranted = await Permission.notification.isGranted;
        if (!mounted) return;
        if (!notificationGranted) {
          context.go(AppRoutes.permissionsNotifications);
        } else {
          context.go(AppRoutes.home);
        }
      }
    } else {
      final setupState = ref.read(profileSetupProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(setupState.errorMessage ?? 'Something went wrong'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(profileSetupProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1BCCE8), Color(0xFF31B8F6)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    _StepIndicator(current: 2, total: 3),
                    const SizedBox(height: 48),
                    Text(
                      'HEY ${widget.displayName.toUpperCase()}!',
                      style: GoogleFonts.lexendDeca(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "HOW DO WE KNOW\nIT'S YOU?",
                      style: GoogleFonts.lexendDeca(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add a profile photo so friends can recognise you 📸',
                      style: GoogleFonts.lexendDeca(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Avatar circle
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                            border: Border.all(
                              color: _selectedImage != null
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              width: _selectedImage != null ? 3 : 2,
                            ),
                            boxShadow: _selectedImage != null
                                ? [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    )
                                  ]
                                : null,
                          ),
                          child: ClipOval(
                            child: _selectedImage != null
                                ? Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_rounded,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Upload\nPhoto',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.lexendDeca(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Upload button
                    Center(
                      child: TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library_outlined,
                            color: Colors.white),
                        label: Text(
                          'Choose from gallery',
                          style: GoogleFonts.lexendDeca(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Finish button
                    GradientButton(
                      label: _selectedImage != null ? 'Finish 🎉' : 'Upload Image',
                      textColor: const Color(0xFF31B8F6),
                      colors: _selectedImage != null
                          ? [Colors.white, Colors.white.withValues(alpha: 0.85)]
                          : [
                              Colors.white.withValues(alpha: 0.5),
                              Colors.white.withValues(alpha: 0.4),
                            ],
                      onPressed:
                          setupState.isLoading ? null : () => _finish(),
                      isLoading: setupState.isLoading,
                    ),
                    const SizedBox(height: 12),

                    // Skip button
                    Center(
                      child: TextButton(
                        onPressed: setupState.isLoading
                            ? null
                            : () => _finish(skip: true),
                        child: Text(
                          'Skip for now',
                          style: GoogleFonts.lexendDeca(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isActive = i == current;
        final isPast = i < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 8),
          width: isActive ? 32 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive || isPast
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }
}
