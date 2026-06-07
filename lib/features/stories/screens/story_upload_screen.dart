import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/story_provider.dart';

class StoryUploadScreen extends ConsumerStatefulWidget {
  const StoryUploadScreen({super.key});

  @override
  ConsumerState<StoryUploadScreen> createState() => _StoryUploadScreenState();
}

class _StoryUploadScreenState extends ConsumerState<StoryUploadScreen> {
  File? _selectedImage;
  final _captionCtrl = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _upload() async {
    if (_selectedImage == null) return;

    final bytes = await _selectedImage!.readAsBytes();
    final controller = ref.read(storyUploadProvider.notifier);
    final story = await controller.uploadStory(
      bytes,
      caption: _captionCtrl.text.trim(),
    );

    if (!mounted) return;
    if (story != null) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(storyUploadProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'New Story',
          style: GoogleFonts.lexendDeca(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview / picker
            GestureDetector(
              onTap: _selectedImage == null ? _pickImage : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 360,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: _selectedImage == null
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignInside,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          // Change image button
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Material(
                              color:
                                  Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: _pickImage,
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.edit,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 56,
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to add a photo',
                            style: GoogleFonts.lexendDeca(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _PickerButton(
                                icon: Icons.photo_library_outlined,
                                label: 'Gallery',
                                onTap: _pickImage,
                              ),
                              const SizedBox(width: 16),
                              _PickerButton(
                                icon: Icons.camera_alt_outlined,
                                label: 'Camera',
                                onTap: _takePhoto,
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Caption input
            TextField(
              controller: _captionCtrl,
              maxLength: 200,
              maxLines: 3,
              style: GoogleFonts.lexendDeca(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add a caption...',
                hintStyle: GoogleFonts.lexendDeca(
                  color: AppColors.textHint,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                counterStyle: GoogleFonts.lexendDeca(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Upload progress
            if (uploadState.isUploading)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: uploadState.progress,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Compressing & uploading...',
                    style: GoogleFonts.lexendDeca(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Error message
            if (uploadState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  uploadState.errorMessage!,
                  style: GoogleFonts.lexendDeca(
                    color: AppColors.error,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Upload button
            GradientButton(
              label: 'Share Story ✨',
              onPressed: _selectedImage != null && !uploadState.isUploading
                  ? _upload
                  : null,
              isLoading: uploadState.isUploading,
            ),

            const SizedBox(height: 8),
            Text(
              'Stories disappear after 24 hours',
              style: GoogleFonts.lexendDeca(
                fontSize: 12,
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.lexendDeca(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
