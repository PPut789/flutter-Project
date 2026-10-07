import 'package:flutter/material.dart';

import '../utils/app_routes.dart';
import 'login_page.dart';
import 'register_page.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/backgrounds/start_travelthai_mock.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          _InvisibleStartButton(
            bottom: 104,
            onTap: () {
              Navigator.push(context, smoothRoute(const RegisterPage()));
            },
          ),
          _InvisibleStartButton(
            bottom: 20,
            onTap: () {
              Navigator.push(context, smoothRoute(const LoginPage()));
            },
          ),
        ],
      ),
    );
  }
}

class _InvisibleStartButton extends StatelessWidget {
  final double bottom;
  final VoidCallback onTap;

  const _InvisibleStartButton({required this.bottom, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: Center(
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.76,
          height: 64,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const StadiumBorder(),
              splashColor: Colors.white.withValues(alpha: 0.10),
              highlightColor: Colors.white.withValues(alpha: 0.04),
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }
}
