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
  static Future<bool> checkPermission() async {
    if (kIsWeb) return true;
    return await UsageStats.checkUsagePermission() ?? false;
  }

  static Future<void> grantPermission() async {
    if (kIsWeb) return;
    await UsageStats.grantUsagePermission();
  }

  static Future<List<AppUsageInfo>> getUsageStats() async {
    if (kIsWeb) {
      return [];
    } else {
      bool hasPermission = await checkPermission();
      if (!hasPermission) {
        return [];
      }
      return _getRealAndroidUsageStats();
    }
  }

  static Future<List<AppUsageInfo>> _getRealAndroidUsageStats() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(days: 1));

      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(startDate, endDate);
      
      if (usageStats.isEmpty) return [];

      // Filter out apps with zero usage and sort
      var filteredStats = usageStats.where((element) {
        final time = int.tryParse(element.totalTimeInForeground ?? '0') ?? 0;
        return time > 0;
      }).toList();

      filteredStats.sort((a, b) {
        final timeA = int.tryParse(a.totalTimeInForeground ?? '0') ?? 0;
        final timeB = int.tryParse(b.totalTimeInForeground ?? '0') ?? 0;
        return timeB.compareTo(timeA);
      });

      return filteredStats.take(15).map((stats) {
        final totalTime = int.tryParse(stats.totalTimeInForeground ?? '0') ?? 0;
        final minutes = totalTime ~/ 60000;
        final h = minutes ~/ 60;
        final m = minutes % 60;
        
        final displayName = stats.packageName!.split('.').last;
        final formattedName = displayName[0].toUpperCase() + displayName.substring(1);

        return AppUsageInfo(
          packageName: formattedName,
          usageTime: h > 0 ? '${h}h ${m}m' : '${m}m',
          icon: _getIconForPackage(stats.packageName!),
          color: _getColorForPackage(stats.packageName!),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching Android usage stats: $e');
      return [];
    }
  }

  static IconData _getIconForPackage(String packageName) {
    if (packageName.contains('instagram')) return Icons.camera_alt;
    if (packageName.contains('youtube')) return Icons.play_circle_filled;
    if (packageName.contains('whatsapp')) return Icons.message;
    if (packageName.contains('chrome')) return Icons.language;
    if (packageName.contains('facebook')) return Icons.facebook;
    return Icons.apps;
  }

  static Color _getColorForPackage(String packageName) {
    if (packageName.contains('instagram')) return Colors.purpleAccent;
    if (packageName.contains('youtube')) return Colors.redAccent;
    if (packageName.contains('whatsapp')) return Colors.greenAccent;
    if (packageName.contains('chrome')) return Colors.blueAccent;
    if (packageName.contains('facebook')) return Colors.blue;
    return Colors.cyanAccent;
  }
}
