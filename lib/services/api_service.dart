import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focusmate_ai/services/usage_service.dart';

class ApiService {
  // Updated with your IP from mobile hotspot
  static const String baseUrl = 'http://10.42.164.120:8000';

  static Future<Map<String, dynamic>> evaluateUsage() async {
    print('DEBUG: evaluateUsage() function entered');
    try {
      print('DEBUG: Getting SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      final goal = prefs.getString('user_goal') ?? 'Be more productive';

      print('DEBUG: --- AI EVALUATION START ---');
      print('DEBUG: Connecting to: $baseUrl/analyze');

      print('DEBUG: Querying local usage stats...');
      final stats = await UsageService.getUsageStats(date: DateTime.now());
      print('DEBUG: Usage data collected: ${stats.length} apps');

      final payload = {
        "user_id": "current_user",
        "goal": goal,
        "usage_data": stats
            .map(
              (e) => {
                "name": e.displayName,
                "minutes": e.minutes,
                "category": e.category.name,
              },
            )
            .toList(),
      };

      print('DEBUG: Sending POST request to backend...');
      final response = await http
          .post(
            Uri.parse('$baseUrl/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      print('DEBUG: Backend responded with status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // Save the verdict locally so we can show it even if offline later
        await prefs.setString('last_ai_verdict', result['verdict']);
        return result;
      } else {
        throw Exception('Failed to evaluate: ${response.body}');
      }
    } catch (e) {
      print('!!! API Error: $e');
      return {
        'error': e.toString(),
        'verdict':
            'Connection Failed. Please check if your PC firewall is off and IP is correct.',
      };
    }
  }

  static Future<void> saveGoal(String goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_goal', goal);
  }

  static Future<String?> getGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_goal');
  }

  static Future<String?> getLastVerdict() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_ai_verdict');
  }
}
