import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:focusmate_ai/theme.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _requestUsagePermission(BuildContext context) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usage Access permission is not applicable on web.')),
      );
      return;
    }
    await openAppSettings();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opened app settings. Please enable Usage Access.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 340,
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Permissions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '- Accessibility Service (required for in‑app tracking)\n'
                  '- Usage Stats permission (app‑usage time)\n'
                  '- Internet permission (send data to backend)',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Request Usage Stats Permission'),
                  onPressed: () => _requestUsagePermission(context),
                ),
                // Future: add toggles for each permission.
              ],
            ),
          ),
        ),
      ),
    );
  }
}
