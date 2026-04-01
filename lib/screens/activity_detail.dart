import 'package:flutter/material.dart';
import 'package:focusmate_ai/theme.dart';
import 'package:glassmorphism/glassmorphism.dart';

class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Detail'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Center(
        child: GlassmorphicContainer(
          width: 340,
          height: 240,
          borderRadius: 24,
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
              'Detailed activity (chat, reels, browsing) will be shown here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}
