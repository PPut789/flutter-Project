import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/user_repository.dart';
import '../utils/app_routes.dart';
import '../widgets/app_chrome.dart';
import 'home_page.dart';
import 'location_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Please enter both email and password.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final preferences = await UserRepository.loadPreferences();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        smoothRoute(
          preferences == null
              ? const LocationPage()
              : HomePage(preferences: preferences),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = _authErrorText(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        errorMessage = 'กรุณากรอกอีเมลก่อนรีเซ็ตรหัสผ่าน';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งลิงก์รีเซ็ตรหัสผ่านไปที่อีเมลแล้ว')),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = _authErrorText(error);
      });
    }
  }

  String _authErrorText(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      default:
        return error.message ?? 'Cannot sign in. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF5),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _LoginWallpaperPainter()),
            ),
            Positioned(
              top: 44,
              right: 24,
              child: IgnorePointer(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: const Color(0xFF07524F).withValues(alpha: 0.10),
                  size: 18,
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(26, 12, 26, 22),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 34,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: RoundBackButton(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.75,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const Spacer(flex: 2),
                          _AuthCard(
                            title: "เข้าสู่ระบบ",
                            subtitle: "ยินดีต้อนรับกลับมา",
                            children: [
                              _AuthField(
                                controller: emailController,
                                label: "อีเมล",
                                hint: "youremail@gmail.com",
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 18),
                              _AuthField(
                                controller: passwordController,
                                label: "รหัสผ่าน",
                                hint: "••••••••••",
                                obscureText: true,
                              ),
                              const SizedBox(height: 2),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: isLoading ? null : _resetPassword,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF07524F),
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  child: const Text('ลืมรหัสผ่าน?'),
                                ),
                              ),
                              if (errorMessage.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                _AuthErrorText(message: errorMessage),
                              ],
                              const SizedBox(height: 26),
                              _LoginButton(
                                isLoading: isLoading,
                                onPressed: _signIn,
                              ),
                              const SizedBox(height: 22),
                              const _DividerText(label: 'หรือ'),
                              const SizedBox(height: 14),
                              _GoogleButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Google Sign-In ยังไม่เปิดใช้งาน',
                                            ),
                                          ),
                                        );
                                      },
                              ),
                            ],
                          ),
                          const Spacer(flex: 3),
                          _AuthSwitchLink(
                            text: "ยังไม่มีบัญชี?",
                            actionText: "สมัครสมาชิก",
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                smoothRoute(const RegisterPage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _AuthCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: appTextMuted, fontSize: 14),
          ),
          const SizedBox(height: 28),
          ...children,
        ],
      ),
    );
  }
}

class _AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
  });

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  late bool isObscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: isObscured,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
            suffixIcon: widget.obscureText
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        isObscured = !isObscured;
                      });
                    },
                    icon: Icon(
                      isObscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFFCFAFD),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: appBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: appBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: appPurple, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoginButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF07524F),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB8CAC8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('เข้าสู่ระบบ'),
      ),
    );
  }
}

class _DividerText extends StatelessWidget {
  final String label;

  const _DividerText({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: appTextMuted,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1F2933),
          side: const BorderSide(color: appBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _GoogleMark(),
            SizedBox(width: 10),
            Text('Google', style: TextStyle(color: Color(0xFF1F2933))),
          ],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 19,
      height: 19,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.20;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    void drawArc(double start, double sweep, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(arcRect, start, sweep, false, paint);
    }

    drawArc(-0.10, 1.45, const Color(0xFF4285F4));
    drawArc(1.35, 1.42, const Color(0xFF34A853));
    drawArc(2.77, 0.88, const Color(0xFFFBBC05));
    drawArc(3.65, 1.52, const Color(0xFFEA4335));

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.50),
      Offset(size.width * 0.96, size.height * 0.50),
      bluePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.78, size.height * 0.50),
      Offset(size.width * 0.78, size.height * 0.66),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoginWallpaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paleGreenPaint = Paint()
      ..color = const Color(0xFFE8F0EA).withValues(alpha: 0.76)
      ..style = PaintingStyle.fill;
    final warmCreamPaint = Paint()
      ..color = const Color(0xFFFBF6EA).withValues(alpha: 0.94)
      ..style = PaintingStyle.fill;
    final ivoryPaint = Paint()
      ..color = const Color(0xFFFFFCF5).withValues(alpha: 0.96)
      ..style = PaintingStyle.fill;
    final translucentCreamPaint = Paint()
      ..color = const Color(0xFFF4EBDC).withValues(alpha: 0.36)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0xFFC8C1B2).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final faintLinePaint = Paint()
      ..color = const Color(0xFFCFC9BA).withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    final greenLinePaint = Paint()
      ..color = const Color(0xFFB7C8BE).withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final baseLayer = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.12)
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.08,
        size.width * 0.56,
        size.height * 0.13,
        size.width * 0.34,
        size.height * 0.10,
      )
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.08,
        size.width * 0.08,
        size.height * 0.11,
        0,
        size.height * 0.08,
      )
      ..close();
    canvas.drawPath(baseLayer, paleGreenPaint);

    final creamLayer = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.07)
      ..cubicTo(
        size.width * 0.80,
        size.height * 0.04,
        size.width * 0.68,
        size.height * 0.08,
        size.width * 0.52,
        size.height * 0.07,
      )
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.06,
        size.width * 0.18,
        size.height * 0.03,
        0,
        size.height * 0.06,
      )
      ..close();
    canvas.drawPath(creamLayer, warmCreamPaint);

    final mainIvoryWave = Path()
      ..moveTo(0, size.height * 0.10)
      ..cubicTo(
        size.width * 0.16,
        size.height * 0.06,
        size.width * 0.30,
        size.height * 0.13,
        size.width * 0.43,
        size.height * 0.10,
      )
      ..cubicTo(
        size.width * 0.61,
        size.height * 0.06,
        size.width * 0.78,
        size.height * 0.09,
        size.width,
        size.height * 0.06,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(mainIvoryWave, ivoryPaint);

    final softBlob = Path()
      ..moveTo(0, size.height * 0.15)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.11,
        size.width * 0.45,
        size.height * 0.16,
        size.width * 0.55,
        size.height * 0.22,
      )
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.29,
        size.width * 0.76,
        size.height * 0.30,
        size.width,
        size.height * 0.24,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(softBlob, translucentCreamPaint);

    final leftSweep = Path()
      ..moveTo(size.width * 0.02, size.height * 0.13)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.10,
        size.width * 0.32,
        size.height * 0.13,
        size.width * 0.48,
        size.height * 0.10,
      );
    canvas.drawPath(leftSweep, greenLinePaint);

    final longSweep = Path()
      ..moveTo(0, size.height * 0.18)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.12,
        size.width * 0.42,
        size.height * 0.14,
        size.width * 0.60,
        size.height * 0.08,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.03,
        size.width * 0.88,
        size.height * 0.06,
        size.width,
        size.height * 0.04,
      );
    canvas.drawPath(longSweep, linePaint);

    for (var i = 0; i < 15; i++) {
      final inset = i * 8.2;
      final arcRect = Rect.fromLTWH(
        -size.width * 0.05 + inset * 0.10,
        -size.height * 0.18 + inset * 0.12,
        size.width * 0.62 + inset * 0.42,
        size.height * 0.34 + inset * 0.20,
      );
      canvas.drawArc(arcRect, -0.40, 2.25, false, faintLinePaint);
    }

    for (var i = 0; i < 18; i++) {
      final inset = i * 7.4;
      final arcRect = Rect.fromLTWH(
        size.width * 0.45 + inset * 0.10,
        -size.height * 0.13 + inset * 0.12,
        size.width * 0.70 + inset * 0.72,
        size.height * 0.34 + inset * 0.18,
      );
      canvas.drawArc(arcRect, 2.58, 3.00, false, faintLinePaint);
    }

    for (var i = 0; i < 8; i++) {
      final inset = i * 10.0;
      final arcRect = Rect.fromLTWH(
        size.width * 0.18 + inset * 0.30,
        size.height * 0.03 + inset * 0.15,
        size.width * 0.86 + inset,
        size.height * 0.22 + inset * 0.15,
      );
      canvas.drawArc(arcRect, 3.18, 1.55, false, faintLinePaint);
    }

    final sparklePaint = Paint()
      ..color = const Color(0xFFC8C1B2).withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    void drawSparkle(Offset center, double radius, [Paint? paint]) {
      final usedPaint = paint ?? sparklePaint;
      canvas.drawLine(
        center.translate(-radius, 0),
        center.translate(radius, 0),
        usedPaint,
      );
      canvas.drawLine(
        center.translate(0, -radius),
        center.translate(0, radius),
        usedPaint,
      );
    }

    drawSparkle(Offset(size.width * 0.90, size.height * 0.13), 5);
    drawSparkle(Offset(size.width * 0.86, size.height * 0.08), 2.7);
    drawSparkle(Offset(size.width * 0.95, size.height * 0.07), 2.2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AuthErrorText extends StatelessWidget {
  final String message;

  const _AuthErrorText({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
    );
  }
}

class _AuthSwitchLink extends StatelessWidget {
  final String text;
  final String actionText;
  final VoidCallback onTap;

  const _AuthSwitchLink({
    required this.text,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            "$text ",
            style: const TextStyle(color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: const TextStyle(
              color: Color(0xFF07524F),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
