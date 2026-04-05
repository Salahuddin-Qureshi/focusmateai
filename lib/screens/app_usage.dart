import 'package:flutter/material.dart';
import 'package:focusmate_ai/theme.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:focusmate_ai/services/usage_service.dart';

class AppUsageScreen extends StatefulWidget {
  const AppUsageScreen({super.key});

  @override
  State<AppUsageScreen> createState() => _AppUsageScreenState();
}

class _AppUsageScreenState extends State<AppUsageScreen> with WidgetsBindingObserver {
  List<AppUsageInfo> _usageList = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndLoad();
    }
  }

  Future<void> _checkPermissionAndLoad() async {
    final hasPermission = await UsageService.checkPermission();
    if (mounted) {
      setState(() {
        _hasPermission = hasPermission;
      });
    }

    if (hasPermission) {
      await _loadStats();
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStats() async {
    if (mounted) setState(() => _isLoading = true);
    final stats = await UsageService.getUsageStats();
    if (mounted) {
      setState(() {
        _usageList = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    await UsageService.grantPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Wellbeing'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Usage Stats',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'See how you spend your time today',
              style: TextStyle(color: AppColors.textDim, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : !_hasPermission 
                  ? _buildPermissionDeniedView()
                  : _usageList.isEmpty 
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _usageList.length,
                        itemBuilder: (context, index) {
                          final item = _usageList[index];
                          return _appUsageCard(item);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, size: 60, color: AppColors.textDim.withAlpha(100)),
          const SizedBox(height: 16),
          Text(
            'No usage data recorded today.',
            style: TextStyle(color: AppColors.textDim, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep focusing, stats will appear soon!',
            style: TextStyle(color: Colors.white30, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 250,
        borderRadius: 24,
        blur: 15,
        border: 2,
        linearGradient: LinearGradient(
          colors: [Colors.white.withAlpha(15), Colors.white.withAlpha(5)],
        ),
        borderGradient: LinearGradient(
          colors: [AppColors.accentViolet.withAlpha(50), Colors.white.withAlpha(10)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: AppColors.accentViolet),
              const SizedBox(height: 16),
              const Text(
                'Permission Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'We need "Usage Access" to show your app statistics.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _requestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentViolet,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Grant Access', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appUsageCard(AppUsageInfo item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 80,
        borderRadius: 20,
        blur: 10,
        border: 1,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withAlpha(15), Colors.white.withAlpha(5)],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [item.color.withAlpha(50), Colors.white.withAlpha(10)],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Icon(item.icon, color: item.color, size: 30),
              const SizedBox(width: 20),
              Expanded(
                child: Text(item.packageName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              Text(item.usageTime, style: TextStyle(color: AppColors.textDim, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
