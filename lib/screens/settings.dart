import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:focusmate_ai/theme.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _requestPermission(BuildContext context, Permission permission, String name) async {
    final status = await permission.request();
    String message = '';
    Color color = Colors.blue;

    if (status.isGranted) {
      _showSuccessDialog(context, name);
    } else if (status.isDenied) {
      message = '$name Permission Denied.';
      color = Colors.redAccent;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    } else if (status.isPermanentlyDenied) {
      message = '$name is permanently denied. Open settings?';
      color = Colors.orange;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }

    if (status.isPermanentlyDenied && !kIsWeb) {
      await openAppSettings();
    }
  }

  void _showSuccessDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppColors.accentCyan, width: 2)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 30),
            const SizedBox(width: 12),
            const Text('Permission Granted'),
          ],
        ),
        content: Text('The $name has been perfectly authorized for this session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Great!', style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Permissions'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _permissionTile(context, LucideIcons.camera, 'Camera Access', Permission.camera),
              const SizedBox(height: 16),
              _permissionTile(context, LucideIcons.mic, 'Microphone Access', Permission.microphone),
              const SizedBox(height: 16),
              _permissionTile(context, LucideIcons.image, 'Photos & Gallery', Permission.photos),
              const SizedBox(height: 16),
              _permissionTile(context, LucideIcons.mapPin, 'Location Access', Permission.location),
              const SizedBox(height: 16),
              _permissionTile(context, LucideIcons.userCheck, 'Contacts Access', Permission.contacts),
              const SizedBox(height: 16),
              _permissionTile(context, LucideIcons.barChart2, 'Usage Stats (Android)', Permission.notification), // We use notification as stand-in for web tests
              const SizedBox(height: 40),
              const Text(
                'Note: Camera and Mic will show real Chrome prompts. Contacts and Photos are mobile-specific but coded for your APK.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _permissionTile(BuildContext context, IconData icon, String title, Permission permission) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 90,
      borderRadius: 20,
      blur: 15,
      border: 1,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withAlpha(10), Colors.white.withAlpha(5)],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.accentCyan.withAlpha(80), Colors.white.withAlpha(10)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentViolet.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.accentViolet, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => _requestPermission(context, permission, title),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Allow'),
            ),
          ],
        ),
      ),
    );
  }
}
