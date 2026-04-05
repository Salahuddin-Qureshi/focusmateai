import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:focusmate_ai/theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient blobs (Aesthetic)
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
          Positioned(
            bottom: 100,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentCyan.withAlpha(26),
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
                    const SizedBox(height: 40),
                    // Central Focus Score
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: CircularProgressIndicator(
                              value: 0.85,
                              strokeWidth: 12,
                              backgroundColor: Colors.white10,
                              color: AppColors.accentViolet,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                '85%',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMain,
                                ),
                              ),
                              Text(
                                'Focus Score',
                                style: TextStyle(
                                  color: AppColors.textDim,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: GlassCard(
                            title: 'Productive',
                            value: '4h 12m',
                            icon: LucideIcons.brain,
                            color: AppColors.accentCyan,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
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
                    // Live Location Proof (Real Data)
                    _LiveLocationCard(),
                    // AI Insight Bubble
                    GlassmorphicContainer(
                      width: double.infinity,
                      height: 100,
                      borderRadius: 20,
                      blur: 20,
                      alignment: Alignment.center,
                      border: 2,
                      linearGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withAlpha(20),
                          Colors.white.withAlpha(5),
                        ],
                      ),
                      borderGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.accentViolet.withAlpha(100),
                          AppColors.accentCyan.withAlpha(100),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Icon(LucideIcons.sparkles, color: AppColors.accentCyan, size: 28),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'You are 15 mins away from your deep work goal! Switch back?',
                                style: TextStyle(fontSize: 14, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        
        // Reverse Geocoding using free OpenStreetMap API (Nominatim)
        final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}');
        final resp = await http.get(uri, headers: {'User-Agent': 'FocusMate_AI_App'});
        final data = json.decode(resp.body);
        
        final city = data['address']['city'] ?? data['address']['town'] ?? data['address']['suburb'] ?? 'Unknown Area';
        // Wait... users can have country too
        final country = data['address']['country'] ?? '';
        
        if (mounted) {
          setState(() => _posStr = '$city, $country');
        }
      } else {
        if (mounted) setState(() => _posStr = 'Location Denied');
      }
    } catch (e) {
      if (mounted) setState(() => _posStr = 'Error fetching area name');
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
        colors: [AppColors.accentCyan.withAlpha(80), Colors.white.withAlpha(10)],
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
        colors: [
          Colors.white.withAlpha(10),
          Colors.white.withAlpha(5),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withAlpha(60),
          Colors.white.withAlpha(10),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: AppColors.textDim, fontSize: 12)),
        ],
      ),
    );
  }
}
