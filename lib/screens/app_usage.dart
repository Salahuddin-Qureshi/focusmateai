import 'package:flutter/material.dart';
import 'package:focusmate_ai/theme.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:focusmate_ai/services/usage_service.dart';

class AppUsageScreen extends StatefulWidget {
  const AppUsageScreen({super.key});

  @override
  State<AppUsageScreen> createState() => _AppUsageScreenState();
}

class _AppUsageScreenState extends State<AppUsageScreen> {
  List<AppUsageInfo> _usageList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await UsageService.getUsageStats();
    setState(() {
      _usageList = stats;
      _isLoading = false;
    });
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
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
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
