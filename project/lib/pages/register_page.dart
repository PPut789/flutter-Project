import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/app_routes.dart';
import '../widgets/app_chrome.dart';
import 'location_page.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = emailController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (email.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        errorMessage = 'Please complete every field.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        errorMessage = 'Password must be at least 6 characters.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        errorMessage = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user?.updateDisplayName(username);

      if (!mounted) return;
      Navigator.pushReplacement(context, smoothRoute(const LocationPage()));
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

  String _authErrorText(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        return error.message ?? 'Cannot create account. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 58, 28, 28),
          child: _RegisterCard(
            children: [
              _RegisterField(
                controller: usernameController,
                label: "ชื่อผู้ใช้",
                hint: "กรอกชื่อผู้ใช้งาน",
                icon: Icons.person,
              ),
              const SizedBox(height: 12),
              _RegisterField(
                controller: emailController,
                label: "อีเมล",
                hint: "กรอกอีเมลของคุณ",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _RegisterField(
                controller: passwordController,
                label: "รหัสผ่าน",
                hint: "กรอกรหัสผ่านของคุณ",
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              _RegisterField(
                controller: confirmPasswordController,
                label: "ยืนยันรหัสผ่าน",
                hint: "กรอกรหัสผ่านอีกครั้ง",
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 14),
                _AuthErrorText(message: errorMessage),
              ],
              const SizedBox(height: 28),
              PrimaryActionButton(
                label: "สมัครสมาชิก",
                isLoading: isLoading,
                onPressed: _signUp,
              ),
              const SizedBox(height: 18),
              _AuthSwitchLink(
                text: "มีบัญชีอยู่แล้ว?",
                actionText: "เข้าสู่ระบบ",
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    smoothRoute(const LoginPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterCard extends StatelessWidget {
  final List<Widget> children;

  const _RegisterCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "สร้างบัญชี",
            style: TextStyle(
              color: Colors.black,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "กรอกข้อมูลเพื่อสมัครสมาชิก",
            style: TextStyle(color: appTextMuted),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _RegisterField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;

  const _RegisterField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
  });

  @override
  State<_RegisterField> createState() => _RegisterFieldState();
}

class _RegisterFieldState extends State<_RegisterField> {
  late bool isObscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
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
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: appBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: appBorder),
            ),
          ),
        ),
      ],
    );
  }
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
              color: appPurple,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
