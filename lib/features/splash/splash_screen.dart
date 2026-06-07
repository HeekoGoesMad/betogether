import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/location_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _taglineController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // App name animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Tagline animation
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeIn),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 150));
    await _textController.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    await _taglineController.forward();

    // Wait then navigate
    await Future.delayed(const Duration(milliseconds: 1200));
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;
    final user = FirebaseService.auth.currentUser;
    if (user != null) {
      final hasProfile = await FirebaseService.hasCompletedProfile();
      if (!mounted) return;
      if (hasProfile) {
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
        context.go(AppRoutes.setupName);
      }
    } else {
      context.go(AppRoutes.auth);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              const Spacer(flex: 3),
              // Logo
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) => Transform.scale(
                  scale: _logoScale.value,
                  child: Opacity(
                    opacity: _logoOpacity.value,
                    child: child,
                  ),
                ),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '🌍',
                      style: TextStyle(fontSize: 56),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // App name
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) => SlideTransition(
                  position: _textSlide,
                  child: Opacity(
                    opacity: _textOpacity.value,
                    child: child,
                  ),
                ),
                child: Text(
                  'BeTogether',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Tagline
              AnimatedBuilder(
                animation: _taglineController,
                builder: (context, child) => Opacity(
                  opacity: _taglineOpacity.value,
                  child: child,
                ),
                child: Text(
                  'Your map, your people.',
                  style: GoogleFonts.lexendDeca(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(flex: 4),
              // Bottom pulsing dots
              AnimatedBuilder(
                animation: _taglineController,
                builder: (context, child) => Opacity(
                  opacity: _taglineOpacity.value,
                  child: child,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == 1 ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == 1
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
