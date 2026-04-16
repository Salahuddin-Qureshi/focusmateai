import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:usage_stats/usage_stats.dart';
import 'package:flutter/material.dart';

class AppUsageInfo {
  final String packageName;
  final String displayName;
  final String usageTime;
  final int minutes;
  final IconData icon;
  final Color color;
  final AppCategory category;

  AppUsageInfo({
    required this.packageName,
    required this.displayName,
    required this.usageTime,
    required this.minutes,
    required this.icon,
    required this.category,
    this.color = Colors.blue,
  });
}

enum AppCategory { social, productivity, entertainment, system, other }

class DailyUsageData {
  final DateTime date;
  final int totalMinutes;
  DailyUsageData(this.date, this.totalMinutes);
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

  static Future<List<AppUsageInfo>> getUsageStats({DateTime? date}) async {
    if (kIsWeb) {
      return [];
    } else {
      bool hasPermission = await checkPermission();
      if (!hasPermission) {
        return [];
      }
      return _getRealAndroidUsageStats(date ?? DateTime.now());
    }
  }

  static Future<List<DailyUsageData>> getWeeklyTotalUsage() async {
    if (kIsWeb) return [];

    List<DailyUsageData> weeklyData = [];
    DateTime now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      final stats = await _getRealAndroidUsageStats(day);
      int totalMinutes = stats.fold(0, (sum, item) => sum + item.minutes);
      weeklyData.add(DailyUsageData(day, totalMinutes));
    }
    return weeklyData;
  }

  static Future<Map<String, dynamic>> getDailyComparison() async {
    final today = await getUsageStats(date: DateTime.now());
    final yesterday = await getUsageStats(
      date: DateTime.now().subtract(const Duration(days: 1)),
    );

    int todayTotal = today.fold(0, (sum, item) => sum + item.minutes);
    int yesterdayTotal = yesterday.fold(0, (sum, item) => sum + item.minutes);

    double change = 0;
    if (yesterdayTotal > 0) {
      change = ((todayTotal - yesterdayTotal) / yesterdayTotal) * 100;
    }

    return {
      'totalMinutes': todayTotal,
      'changePercentage': change.abs().toStringAsFixed(1),
      'isIncrease': todayTotal > yesterdayTotal,
    };
  }

  static Future<List<DailyUsageData>> getAppWeeklyUsage(
    String packageName,
  ) async {
    if (kIsWeb) return [];

    List<DailyUsageData> weeklyData = [];
    DateTime now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      DateTime day = now.subtract(Duration(days: i));
      DateTime startDate = DateTime(day.year, day.month, day.day, 0, 0, 0);
      DateTime endDate = DateTime(day.year, day.month, day.day, 23, 59, 59);

      final usageStats = await UsageStats.queryUsageStats(startDate, endDate);
      final appStat = usageStats.where((e) => e.packageName == packageName);

      int totalMinutes = 0;
      for (var stat in appStat) {
        totalMinutes +=
            (int.tryParse(stat.totalTimeInForeground ?? '0') ?? 0) ~/ 60000;
      }

      weeklyData.add(DailyUsageData(day, totalMinutes));
    }
    return weeklyData;
  }

  static Future<List<AppUsageInfo>> _getRealAndroidUsageStats(
    DateTime date,
  ) async {
    try {
      // Set to start and end of the specific day
      DateTime startDate = DateTime(date.year, date.month, date.day, 0, 0, 0);
      DateTime endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);

      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(
        startDate,
        endDate,
      );

      if (usageStats.isEmpty) return [];

      // Improved Filtering
      var filteredStats = usageStats.where((element) {
        final time = int.tryParse(element.totalTimeInForeground ?? '0') ?? 0;
        final pkg = element.packageName ?? '';

        // Hide very low usage (less than 10 seconds)
        if (time < 10000) return false;

        // Aggressive Filtering for System/Background processes
        if (pkg.contains('com.android.providers') ||
            pkg.contains('com.android.systemui') ||
            pkg.contains('com.google.android.gms') ||
            pkg.contains('com.android.launcher') ||
            pkg.contains('com.sec.android.app.launcher') || // Samsung
            pkg.contains('com.miui') || // Xiaomi/MIUI
            pkg.contains('com.xiaomi') || // Xiaomi
            pkg.contains('launcher') || // Any launcher
            pkg.contains('service') || // Background services
            pkg.contains('inputmethod') || // Keyboards
            pkg.contains('security') || // Security apps
            pkg == 'android' ||
            pkg == 'com.android.settings' ||
            pkg == 'com.android.phone' || // Dialer
            pkg == 'com.android.server.telecom' ||
            pkg == 'com.android.incallui') {
          return false;
        }

        return true;
      }).toList();

      // Aggregate by package name (sometimes queryUsageStats returns multiples for same pkg)
      Map<String, int> aggregated = {};
      for (var stat in filteredStats) {
        int time = int.tryParse(stat.totalTimeInForeground ?? '0') ?? 0;
        aggregated[stat.packageName!] =
            (aggregated[stat.packageName!] ?? 0) + time;
      }

      var sortedList = aggregated.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedList.take(20).map((entry) {
        final totalTime = entry.value;
        final minutes = totalTime ~/ 60000;
        final h = minutes ~/ 60;
        final m = minutes % 60;

        String displayName = entry.key.split('.').last;
        // Fix for common names
        if (entry.key == 'com.whatsapp')
          displayName = 'WhatsApp';
        else if (entry.key.contains('instagram'))
          displayName = 'Instagram';
        else if (entry.key.contains('youtube'))
          displayName = 'YouTube';
        else if (entry.key.contains('chrome'))
          displayName = 'Chrome';
        else if (entry.key.contains('facebook'))
          displayName = 'Facebook';
        else
          displayName = displayName[0].toUpperCase() + displayName.substring(1);

        return AppUsageInfo(
          packageName: entry.key,
          displayName: displayName,
          minutes: minutes,
          usageTime: h > 0 ? '${h}h ${m}m' : '${m}m',
          icon: _getIconForPackage(entry.key),
          color: _getColorForPackage(entry.key),
          category: _getCategoryForPackage(entry.key),
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

  static AppCategory _getCategoryForPackage(String packageName) {
    if (packageName.contains('instagram') ||
        packageName.contains('facebook') ||
        packageName.contains('whatsapp') ||
        packageName.contains('social')) {
      return AppCategory.social;
    }
    if (packageName.contains('youtube') ||
        packageName.contains('netflix') ||
        packageName.contains('spotify') ||
        packageName.contains('video')) {
      return AppCategory.entertainment;
    }
    if (packageName.contains('chrome') ||
        packageName.contains('drive') ||
        packageName.contains('calendar') ||
        packageName.contains('office')) {
      return AppCategory.productivity;
    }
    return AppCategory.other;
  }
}
