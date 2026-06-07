import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes/app_router.dart';
import '../../shared/widgets/gradient_button.dart';

class SetupBirthdayScreen extends StatefulWidget {
  final String displayName;

  const SetupBirthdayScreen({super.key, required this.displayName});

  @override
  State<SetupBirthdayScreen> createState() => _SetupBirthdayScreenState();
}

class _SetupBirthdayScreenState extends State<SetupBirthdayScreen>
    with SingleTickerProviderStateMixin {
  final _monthCtrl = TextEditingController();
  final _dayCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _monthFocus = FocusNode();
  final _dayFocus = FocusNode();
  final _yearFocus = FocusNode();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

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

    _monthCtrl.addListener(() => setState(() {}));
    _dayCtrl.addListener(() => setState(() {}));
    _yearCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animController.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    _yearCtrl.dispose();
    _monthFocus.dispose();
    _dayFocus.dispose();
    _yearFocus.dispose();
    super.dispose();
  }

  bool get _isComplete {
    final month = int.tryParse(_monthCtrl.text);
    final day = int.tryParse(_dayCtrl.text);
    final year = int.tryParse(_yearCtrl.text);
    return month != null &&
        month >= 1 &&
        month <= 12 &&
        day != null &&
        day >= 1 &&
        day <= 31 &&
        year != null &&
        year >= 1900 &&
        year <= DateTime.now().year;
  }

  String get _birthdayString {
    final m = _monthCtrl.text.padLeft(2, '0');
    final d = _dayCtrl.text.padLeft(2, '0');
    final y = _yearCtrl.text;
    return '$m/$d/$y';
  }

  void _goNext() {
    if (!_isComplete) return;
    context.go(AppRoutes.setupPhoto, extra: {
      'name': widget.displayName,
      'birthday': _birthdayString,
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    _StepIndicator(current: 1, total: 3),
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
                      "WHAT'S YOUR BDAY?",
                      style: GoogleFonts.lexendDeca(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We use this to keep your account secure 🎂',
                      style: GoogleFonts.lexendDeca(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Date picker row
                    Row(
                      children: [
                        // Month
                        Expanded(
                          flex: 2,
                          child: _DateField(
                            controller: _monthCtrl,
                            focusNode: _monthFocus,
                            hint: 'MM',
                            maxLength: 2,
                            onChanged: (v) {
                              if (v.length == 2) {
                                FocusScope.of(context)
                                    .requestFocus(_dayFocus);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Day
                        Expanded(
                          flex: 2,
                          child: _DateField(
                            controller: _dayCtrl,
                            focusNode: _dayFocus,
                            hint: 'DD',
                            maxLength: 2,
                            onChanged: (v) {
                              if (v.length == 2) {
                                FocusScope.of(context)
                                    .requestFocus(_yearFocus);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Year
                        Expanded(
                          flex: 3,
                          child: _DateField(
                            controller: _yearCtrl,
                            focusNode: _yearFocus,
                            hint: 'YYYY',
                            maxLength: 4,
                            onSubmitted: _isComplete ? (_) => _goNext() : null,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: _isComplete ? 1.0 : 0.5,
                      duration: const Duration(milliseconds: 200),
                      child: GradientButton(
                        label: 'Next',
                        textColor: const Color(0xFF31B8F6),
                        colors: [
                          Colors.white,
                          Colors.white.withValues(alpha: 0.85),
                        ],
                        onPressed: _isComplete ? _goNext : null,
                      ),
                    ),
                    const SizedBox(height: 36),
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

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final int maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _DateField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.maxLength,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(maxLength),
        ],
        textInputAction:
            maxLength == 4 ? TextInputAction.done : TextInputAction.next,
        style: GoogleFonts.lexendDeca(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          filled: false,
          hintText: hint,
          hintStyle: GoogleFonts.lexendDeca(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
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
