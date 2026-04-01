import 'package:flutter/material.dart';
import 'package:focusmate_ai/theme.dart';
import 'package:glassmorphism/glassmorphism.dart';

class AppUsageScreen extends StatelessWidget {
  const AppUsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Usage'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Center(
        child: GlassmorphicContainer(
          width: 300,
          height: 200,
          borderRadius: 20,
          blur: 20,
          border: 1,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withAlpha(20), Colors.white.withAlpha(5)],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentViolet.withAlpha(80),
              AppColors.accentCyan.withAlpha(80),
            ],
          ),
          child: const Center(
            child: Text(
              'App usage stats will appear here',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}
