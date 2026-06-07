import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/firebase_service.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/social_sign_in_button.dart';
import 'auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    final controller = ref.read(authControllerProvider.notifier);
    final user = await controller.signInWithGoogle();
    if (!mounted || user == null) return;
    final hasProfile = await FirebaseService.hasCompletedProfile();
    if (!mounted) return;
    if (hasProfile) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.setupName);
    }
  }

  Future<void> _handleEmailAuth() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final controller = ref.read(authControllerProvider.notifier);
    final state = ref.read(authControllerProvider);
    final email = _emailCtrl.text;
    final password = _passwordCtrl.text;

    final user = state.mode == AuthMode.signUp
        ? await controller.signUpWithEmail(email, password)
        : await controller.signInWithEmail(email, password);

    if (!mounted || user == null) return;
    final hasProfile = await FirebaseService.hasCompletedProfile();
    if (!mounted) return;
    if (hasProfile) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.setupName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isSignUp = authState.mode == AuthMode.signUp;

    // Show snackbar on error
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1BCCE8),
              Color(0xFF9B3FC0),
              Color(0xFFD44FA0),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Text('🌍', style: TextStyle(fontSize: 38)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'BeTogether',
                    style: GoogleFonts.lexendDeca(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // White card
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                isSignUp ? 'Create Account' : 'Welcome Back',
                                style: GoogleFonts.lexendDeca(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isSignUp
                                    ? 'Join your friends on the map'
                                    : 'Sign in to find your friends',
                                style: GoogleFonts.lexendDeca(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Google Button
                              SocialSignInButton(
                                label: AppStrings.continueWithGoogle,
                                isLoading: authState.isGoogleLoading,
                                onPressed: authState.isGoogleLoading ||
                                        authState.isLoading
                                    ? null
                                    : _handleGoogleSignIn,
                                icon: _googleIcon(),
                              ),
                              const SizedBox(height: 12),

                              // Facebook Button (placeholder)
                              SocialSignInButton(
                                label: AppStrings.continueWithFacebook,
                                onPressed: null, // Placeholder
                                disabledTooltip:
                                    AppStrings.facebookComingSoon,
                                icon: _facebookIcon(),
                              ),
                              const SizedBox(height: 24),

                              // Divider
                              Row(
                                children: [
                                  const Expanded(
                                      child: Divider(
                                          color: AppColors.divider)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      AppStrings.orContinueWith,
                                      style: GoogleFonts.lexendDeca(
                                        fontSize: 12,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                      child: Divider(
                                          color: AppColors.divider)),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Email field
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: GoogleFonts.lexendDeca(
                                    fontSize: 14,
                                    color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: 'Email address',
                                  prefixIcon: Icon(Icons.email_outlined,
                                      color: AppColors.textHint),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return AppStrings.emailRequired;
                                  }
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(v)) {
                                    return AppStrings.emailInvalid;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Password field
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscurePassword,
                                textInputAction: isSignUp
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                style: GoogleFonts.lexendDeca(
                                    fontSize: 14,
                                    color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline,
                                      color: AppColors.textHint),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return AppStrings.passwordRequired;
                                  }
                                  if (v.length < 6) {
                                    return AppStrings.passwordTooShort;
                                  }
                                  return null;
                                },
                                onFieldSubmitted:
                                    isSignUp ? null : (_) => _handleEmailAuth(),
                              ),

                              // Confirm password (sign up only)
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: isSignUp
                                    ? Column(
                                        children: [
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: _confirmCtrl,
                                            obscureText: _obscureConfirm,
                                            textInputAction:
                                                TextInputAction.done,
                                            style: GoogleFonts.lexendDeca(
                                                fontSize: 14,
                                                color: AppColors.textPrimary),
                                            decoration: InputDecoration(
                                              hintText: 'Confirm Password',
                                              prefixIcon: const Icon(
                                                  Icons.lock_outline,
                                                  color: AppColors.textHint),
                                              suffixIcon: IconButton(
                                                onPressed: () => setState(
                                                    () => _obscureConfirm =
                                                        !_obscureConfirm),
                                                icon: Icon(
                                                  _obscureConfirm
                                                      ? Icons
                                                          .visibility_outlined
                                                      : Icons
                                                          .visibility_off_outlined,
                                                  color: AppColors.textHint,
                                                ),
                                              ),
                                            ),
                                            validator: (v) {
                                              if (v != _passwordCtrl.text) {
                                                return AppStrings
                                                    .passwordMismatch;
                                              }
                                              return null;
                                            },
                                            onFieldSubmitted: (_) =>
                                                _handleEmailAuth(),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 24),

                              // Sign up/in button
                              GradientButton(
                                label: isSignUp
                                    ? AppStrings.signUpAndAccept
                                    : AppStrings.signIn,
                                onPressed: authState.isLoading ||
                                        authState.isGoogleLoading
                                    ? null
                                    : _handleEmailAuth,
                                isLoading: authState.isLoading,
                              ),
                              const SizedBox(height: 16),

                              // Terms text (sign up only)
                              if (isSignUp)
                                Text(
                                  AppStrings.termsText,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lexendDeca(
                                    fontSize: 11,
                                    color: AppColors.textHint,
                                    height: 1.5,
                                  ),
                                ),
                              const SizedBox(height: 16),

                              // Toggle mode
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: isSignUp
                                            ? AppStrings.alreadyHaveAccount
                                            : AppStrings.dontHaveAccount,
                                        style: GoogleFonts.lexendDeca(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      TextSpan(
                                        text: isSignUp
                                            ? 'Sign In'
                                            : 'Sign Up',
                                        style: GoogleFonts.lexendDeca(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = ref
                                              .read(authControllerProvider
                                                  .notifier)
                                              .toggleMode,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _googleIcon() {
    return CustomPaint(
      painter: _GoogleLogoPainter(),
    );
  }

  Widget _facebookIcon() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.facebookBlue,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw colored arcs to approximate Google logo
    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335),
    ];
    final starts = [0.1, 0.6, 0.85, 1.35];
    final sweeps = [0.5, 0.25, 0.5, 0.25];
    final paint = Paint()
      ..strokeWidth = size.width * 0.22
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.7),
        starts[i] * 3.14159,
        sweeps[i] * 3.14159,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
