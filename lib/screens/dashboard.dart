import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:focusmate_ai/theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';

import 'package:focusmate_ai/services/api_service.dart';
import 'package:focusmate_ai/services/accessibility_service.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _currentGoal = "Setting my goal...";
  String _aiVerdict = "Waiting for your first evaluation...";
  bool _isEvaluating = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final goal = await ApiService.getGoal();
    final verdict = await ApiService.getLastVerdict();
    if (mounted) {
      setState(() {
        _currentGoal = goal ?? "Become a Flutter Expert";
        _aiVerdict = verdict ?? "Evaluation results will appear here.";
      });
    }
  }

  Future<void> _showGoalDialog() async {
    final controller = TextEditingController(text: _currentGoal);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Set Your Focus Goal'),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: "e.g. Become a software engineer",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.saveGoal(controller.text);
              setState(() => _currentGoal = controller.text);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save Goal'),
          ),
        ],
      ),
    );
  }

  Future<void> _runAIEvaluation() async {
    setState(() => _isEvaluating = true);
    final result = await ApiService.evaluateUsage();
    if (mounted) {
      setState(() {
        _isEvaluating = false;
        if (result.containsKey('verdict')) {
          _aiVerdict = result['verdict'];
        } else {
          _aiVerdict = "Connection Error. Check if backend is running.";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentViolet.withAlpha(38),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              'FocusMate AI',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: AppColors.accentCyan,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'Daily Overview',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const CircleAvatar(
                          backgroundColor: AppColors.accentViolet,
                          child: Icon(LucideIcons.user, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Goal Section
                    GestureDetector(
                      onTap: _showGoalDialog,
                      child: GlassmorphicContainer(
                        width: double.infinity,
                        height: 100,
                        borderRadius: 24,
                        blur: 20,
                        border: 1,
                        linearGradient: LinearGradient(
                          colors: [Colors.white.withAlpha(15), Colors.white.withAlpha(5)],
                        ),
                        borderGradient: LinearGradient(
                          colors: [AppColors.accentCyan.withAlpha(50), Colors.white.withAlpha(10)],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.target, color: AppColors.accentCyan),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Primary Goal', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                                    Text(_currentGoal, 
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(LucideIcons.edit3, size: 16, color: AppColors.textDim),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Stats Cards
                    Row(
                      children: [
                        const Expanded(
                          child: GlassCard(
                            title: 'Productive',
                            value: '4h 12m',
                            icon: LucideIcons.brain,
                            color: AppColors.accentCyan,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: GlassCard(
                            title: 'Distractions',
                            value: '45m',
                            icon: LucideIcons.clapperboard,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    
                    // AI Focus Verdict
                    const Text('AI Focus Verdict', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    GlassmorphicContainer(
                      width: double.infinity,
                      height: 160,
                      borderRadius: 24,
                      blur: 30,
                      border: 2,
                      linearGradient: LinearGradient(
                        colors: [AppColors.accentViolet.withAlpha(20), Colors.black.withAlpha(10)],
                      ),
                      borderGradient: const LinearGradient(
                        colors: [AppColors.accentViolet, AppColors.accentCyan],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.sparkles, color: AppColors.accentCyan, size: 20),
                                const SizedBox(width: 8),
                                Text('AUTO-GEN COACH', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Text(_aiVerdict, 
                                style: const TextStyle(height: 1.4, fontSize: 14),
                                overflow: TextOverflow.fade,
                              ),
                            ),
                            if (_isEvaluating) 
                              const LinearProgressIndicator(backgroundColor: Colors.white10, color: AppColors.accentCyan)
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isEvaluating ? null : _runAIEvaluation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentCyan,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(_isEvaluating ? 'Agents Evaluating...' : 'Evaluate Today\'s Progress', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    _LiveFocusCard(),
                    const SizedBox(height: 24),
                    _LiveLocationCard(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveLocationCard extends StatefulWidget {
  @override
  State<_LiveLocationCard> createState() => _LiveLocationCardState();
}

class _LiveLocationCardState extends State<_LiveLocationCard> {
  String _posStr = 'Waiting for permission...';

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        List<Placemark> placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final city =
              place.locality ??
              place.subAdministrativeArea ??
              place.administrativeArea ??
              'Unknown City';
          final subArea = place.subLocality ?? '';

          if (mounted) {
            setState(
              () => _posStr = subArea.isNotEmpty ? '$subArea, $city' : city,
            );
          }
        }
      } else {
        if (mounted) setState(() => _posStr = 'Location Denied');
      }
    } catch (e) {
      if (mounted) setState(() => _posStr = 'Enable Precise Location');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 100,
      borderRadius: 20,
      blur: 20,
      border: 1,
      linearGradient: LinearGradient(
        colors: [Colors.white.withAlpha(20), Colors.white.withAlpha(5)],
      ),
      borderGradient: LinearGradient(
        colors: [
          AppColors.accentCyan.withAlpha(80),
          Colors.white.withAlpha(10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.mapPin, color: AppColors.accentCyan),
          const SizedBox(width: 12),
          Text(_posStr, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class _LiveFocusCard extends StatefulWidget {
  @override
  State<_LiveFocusCard> createState() => _LiveFocusCardState();
}

class _LiveFocusCardState extends State<_LiveFocusCard> {
  String _currentApp = "Detecting...";
  bool _isServiceEnabled = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _checkService();
  }

  Future<void> _checkService() async {
    final enabled = await AppAccessibilityService.isServiceEnabled();
    if (mounted) {
      setState(() {
        _isServiceEnabled = enabled;
      });
    }

    if (enabled) {
      _subscription = AppAccessibilityService.onForegroundAppChanged.listen((app) {
        if (mounted) {
          setState(() {
            _currentApp = app;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 120,
      borderRadius: 24,
      blur: 20,
      border: 1,
      linearGradient: LinearGradient(
        colors: [Colors.white.withAlpha(20), Colors.white.withAlpha(5)],
      ),
      borderGradient: LinearGradient(
        colors: [
          _isServiceEnabled ? AppColors.accentCyan : Colors.orange.withAlpha(100),
          Colors.white.withAlpha(10),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          children: [
            Icon(
              _isServiceEnabled ? LucideIcons.eye : LucideIcons.alertTriangle,
              color: _isServiceEnabled ? AppColors.accentCyan : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isServiceEnabled ? 'Live Focus Monitoring' : 'Accessibility Required',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textDim,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isServiceEnabled ? _currentApp : 'Enable to track focus',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!_isServiceEnabled)
              IconButton(
                icon: const Icon(LucideIcons.settings, color: Colors.white70),
                onPressed: () async {
                  await AppAccessibilityService.openSettings();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const GlassCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 140,
      borderRadius: 24,
      blur: 20,
      alignment: Alignment.center,
      border: 1.5,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withAlpha(10), Colors.white.withAlpha(5)],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withAlpha(60), Colors.white.withAlpha(10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(title, style: TextStyle(color: AppColors.textDim, fontSize: 12)),
        ],
      ),
    );
  }
}
