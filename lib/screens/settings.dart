import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:focusmate_ai/theme.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  Map<Permission, bool> _permissionStats = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.location,
      Permission.contacts,
    ];

    Map<Permission, bool> stats = {};
    for (var p in permissions) {
      stats[p] = await p.isGranted;
    }

    if (mounted) {
      setState(() {
        _permissionStats = stats;
      });
    }
  }

  Future<void> _requestPermission(Permission permission, String name) async {
    final status = await permission.request();

    if (status.isGranted) {
      _showSuccessDialog(name);
    } else if (status.isPermanentlyDenied && !kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$name is permanently denied. Please enable in settings.',
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }

    _checkAllPermissions();
  }

  void _showSuccessDialog(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.accentCyan, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 12),
            Text('Permission Granted'),
          ],
        ),
        content: Text('The $name has been successfully authorized.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Great!',
              style: TextStyle(
                color: AppColors.accentCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Center'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Safety & Privacy',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage how FocusMate AI interacts with your hardware.',
                style: TextStyle(color: AppColors.textDim),
              ),
              const SizedBox(height: 32),
              _permissionTile(LucideIcons.camera, 'Camera', Permission.camera),
              const SizedBox(height: 16),
              _permissionTile(
                LucideIcons.mic,
                'Microphone',
                Permission.microphone,
              ),
              const SizedBox(height: 16),
              _permissionTile(
                LucideIcons.image,
                'Gallery & Photos',
                Permission.photos,
              ),
              const SizedBox(height: 16),
              _permissionTile(
                LucideIcons.mapPin,
                'Location Services',
                Permission.location,
              ),
              const SizedBox(height: 16),
              _permissionTile(
                LucideIcons.userCheck,
                'Contacts',
                Permission.contacts,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _permissionTile(IconData icon, String title, Permission permission) {
    bool isGranted = _permissionStats[permission] ?? false;

    return GlassmorphicContainer(
      width: double.infinity,
      height: 90,
      borderRadius: 20,
      blur: 15,
      border: 1,
      linearGradient: LinearGradient(
        colors: [Colors.white.withAlpha(10), Colors.white.withAlpha(5)],
      ),
      borderGradient: LinearGradient(
        colors: [
          isGranted
              ? Colors.green.withAlpha(80)
              : AppColors.accentCyan.withAlpha(80),
          Colors.white.withAlpha(10),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isGranted ? Colors.green : AppColors.accentViolet)
                    .withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isGranted ? Colors.greenAccent : AppColors.accentViolet,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isGranted ? 'Access Granted' : 'Requires Approval',
                    style: TextStyle(
                      color: isGranted ? Colors.greenAccent : AppColors.textDim,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!isGranted)
              ElevatedButton(
                onPressed: () => _requestPermission(permission, title),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Enable',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            else
              const Icon(Icons.check_circle, color: Colors.greenAccent),
          ],
        ),
      ),
    );
  }
}
