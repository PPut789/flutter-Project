import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/user_repository.dart';
import '../utils/app_routes.dart';
import 'home_page.dart';
import 'location_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static Future<void>? _googleSignInInitialization;

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

  Future<void> _signInWithGoogle() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final credential = await _createGoogleCredential();
      await UserRepository.ensureUserProfile(credential.user);
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
    } on GoogleSignInException catch (error) {
      if (!mounted) return;
      if (error.code == GoogleSignInExceptionCode.canceled) return;
      setState(() {
        errorMessage = _googleSignInErrorText(error);
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = _authErrorText(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage =
            'ไม่สามารถเข้าสู่ระบบด้วย Google ได้ กรุณาลองใหม่อีกครั้ง';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<UserCredential> _createGoogleCredential() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile');
      return FirebaseAuth.instance.signInWithPopup(provider);
    }

    await _initializeGoogleSignIn();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.uiUnavailable,
        description: 'Google Sign-In is not available on this platform.',
      );
    }

    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> _initializeGoogleSignIn() {
    return _googleSignInInitialization ??= GoogleSignIn.instance.initialize();
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

  String _googleSignInErrorText(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'การตั้งค่า Google Sign-In ยังไม่ครบ กรุณาตรวจสอบ SHA-1 และ google-services.json';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'อุปกรณ์นี้ยังไม่รองรับการเข้าสู่ระบบด้วย Google';
      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.userMismatch:
        return 'การเข้าสู่ระบบด้วย Google ถูกขัดจังหวะ กรุณาลองใหม่อีกครั้ง';
      case GoogleSignInExceptionCode.canceled:
        return '';
      case GoogleSignInExceptionCode.unknownError:
        return 'ไม่สามารถเข้าสู่ระบบด้วย Google ได้ กรุณาลองใหม่อีกครั้ง';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF5FB),
      body: SafeArea(
        child: ColoredBox(
          color: const Color(0xFFEAF5FB),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(30, 18, 30, 22),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        _AuthCard(
                          children: [
                            _AuthField(
                              controller: emailController,
                              label: "อีเมล",
                              hint: "กรอกอีเมลของคุณ",
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 18),
                            _AuthField(
                              controller: passwordController,
                              label: "รหัสผ่าน",
                              hint: "กรอกรหัสผ่านของคุณ",
                              obscureText: true,
                            ),
                            const SizedBox(height: 2),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: isLoading ? null : _resetPassword,
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF7EC8E3),
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
                              onPressed: isLoading ? null : _signInWithGoogle,
                            ),
                          ],
                        ),
                        const Spacer(),
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
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  final List<Widget> children;

  const _AuthCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image.asset(
              'assets/logos/login_brand_header_transparent.png',
              width: 262,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 18),
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
          style: const TextStyle(
            color: Color(0xFF3A6384),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: isObscured,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9AAEC0),
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Icon(
              widget.obscureText
                  ? Icons.lock_outline_rounded
                  : Icons.person_outline_rounded,
              size: 21,
              color: const Color(0xFF6D8396),
            ),
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
                      color: const Color(0xFF6D8396),
                      size: 20,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.82),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: Color(0xFF7AAED3), width: 1),
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
      height: 50,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF76ADD1),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFEAF7FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFC8D7E3), height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7A93A7),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFC8D7E3), height: 1)),
      ],
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
          backgroundColor: Colors.white.withValues(alpha: 0.52),
          side: const BorderSide(color: Color(0xFFBFD1DF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _GoogleMark(),
            SizedBox(width: 10),
            Text(
              'เข้าสู่ระบบด้วย Google',
              style: TextStyle(color: Color(0xFF526B7E)),
            ),
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
            style: const TextStyle(color: Color(0xFF8A9EAF)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionText,
            style: const TextStyle(
              color: Color(0xFF4A8FBD),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
