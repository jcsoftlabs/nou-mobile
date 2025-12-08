import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo NOU
            Image.asset(
              'assets/images/logo.png',
              width: 250,
              height: 250,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 100,
                    color: Colors.red,
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0000)),
            ),
          ],
        ),
      ),
    );
  }
}
