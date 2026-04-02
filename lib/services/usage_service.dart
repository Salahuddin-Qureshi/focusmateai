import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:usage_stats/usage_stats.dart';
import 'package:flutter/material.dart';

class AppUsageInfo {
  final String packageName;
  final String usageTime;
  final IconData icon;
  final Color color;

  AppUsageInfo({
    required this.packageName,
    required this.usageTime,
    required this.icon,
    this.color = Colors.blue,
  });
}

class UsageService {
  static Future<List<AppUsageInfo>> getUsageStats() async {
    if (kIsWeb) {
      return _getMockUsageStats();
    } else {
      return _getRealAndroidUsageStats();
    }
  }

  static List<AppUsageInfo> _getMockUsageStats() {
    return [
      AppUsageInfo(packageName: 'Instagram', usageTime: '2h 15m', icon: Icons.camera_alt, color: Colors.purpleAccent),
      AppUsageInfo(packageName: 'TikTok', usageTime: '1h 45m', icon: Icons.music_video, color: Colors.cyanAccent),
      AppUsageInfo(packageName: 'Slack', usageTime: '3h 12m', icon: Icons.work, color: Colors.greenAccent),
      AppUsageInfo(packageName: 'Chrome', usageTime: '4h 50m', icon: Icons.language, color: Colors.blueAccent),
      AppUsageInfo(packageName: 'Netflix', usageTime: '1h 10m', icon: Icons.movie, color: Colors.redAccent),
    ];
  }

  static Future<List<AppUsageInfo>> _getRealAndroidUsageStats() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(days: 1));

      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(startDate, endDate);
      
      // Filter out apps with zero usage and sort
      usageStats = usageStats.where((element) => int.parse(element.totalTimeInForeground!) > 0).toList();
      usageStats.sort((a, b) => int.parse(b.totalTimeInForeground!).compareTo(int.parse(a.totalTimeInForeground!)));

      return usageStats.take(10).map((stats) {
        final minutes = int.parse(stats.totalTimeInForeground!) ~/ 60000;
        final h = minutes ~/ 60;
        final m = minutes % 60;
        
        return AppUsageInfo(
          packageName: stats.packageName!.split('.').last.toUpperCase(),
          usageTime: h > 0 ? '${h}h ${m}m' : '${m}m',
          icon: Icons.apps, // In a real app, you would fetch the app icon using package_info
          color: Colors.blueAccent,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching Android usage stats: $e');
      return _getMockUsageStats();
    }
  }
}
