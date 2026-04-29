import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focusmate_ai/services/usage_service.dart';

class ApiService {
  // Directly insert your API keys here
  static const String openAiKey = 'PASTE_YOUR_OPENAI_API_KEY_HERE';
  static const String tavilyKey = 'PASTE_YOUR_TAVILY_API_KEY_HERE';

  static Future<Map<String, dynamic>> evaluateUsage() async {
    print(
      'DEBUG: evaluateUsage() function entered - RUNNING LOCALLY ON MOBILE',
    );
    try {
      print('DEBUG: Getting SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      final goal = prefs.getString('user_goal') ?? 'Be more productive';

      print('DEBUG: --- AI EVALUATION START ---');
      print('DEBUG: Querying local usage stats...');
      final stats = await UsageService.getUsageStats(date: DateTime.now());
      print('DEBUG: Usage data collected: ${stats.length} apps');

      // 1. Fetch trends from Tavily
      print('DEBUG: Searching Tavily for trends...');
      String trendsText = "No trends found. Please check your Tavily API Key.";

      if (tavilyKey != 'PASTE_YOUR_TAVILY_API_KEY_HERE') {
        try {
          final tavilyRes = await http
              .post(
                Uri.parse('https://api.tavily.com/search'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  "api_key": tavilyKey,
                  "query": "$goal latest trends and skills",
                  "search_depth": "basic",
                  "max_results": 3,
                }),
              )
              .timeout(const Duration(seconds: 10));

          if (tavilyRes.statusCode == 200) {
            final data = jsonDecode(tavilyRes.body);
            final results = data['results'] as List?;
            if (results != null && results.isNotEmpty) {
              trendsText = results
                  .map((r) => "- ${r['title']}: ${r['content']}")
                  .join("\n");
            }
          } else {
            print(
              'DEBUG: Tavily failed with status: ${tavilyRes.statusCode} - ${tavilyRes.body}',
            );
          }
        } catch (e) {
          print('DEBUG: Tavily Error: $e');
        }
      } else {
        print('DEBUG: Tavily skipped because API key is missing.');
      }

      // 2. Format App Usage Data
      String appsStr = "";
      if (stats.isEmpty) {
        appsStr = "No apps used today.";
      } else {
        for (var e in stats) {
          String details = e.capturedContent.isNotEmpty
              ? " | Details: ${e.capturedContent.join(', ')}"
              : "";
          appsStr +=
              "- ${e.displayName}: ${e.minutes} mins (${e.category.name})$details\n";
        }
      }

      // 3. Call OpenAI directly
      print('DEBUG: Calling OpenAI...');
      final prompt =
          """
User Goal: $goal

Latest real-world trends for this goal from web research:
$trendsText

Today's App Usage:
$appsStr

Instructions:
1. Act as a Data Analyst: Briefly compare the user's app usage (and specific content details) with the trends found. Explain what they might be missing out on.
2. Act as a Productivity Coach: Based on the analysis, give the user a 'Focus Verdict' (Success or Fail).
3. Suggest a specific, actionable plan for the next day.
Keep your response professional, encouraging, and direct. Format the output nicely so it looks good on a mobile screen.
""";

      final openAiRes = await http
          .post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $openAiKey',
            },
            body: jsonEncode({
              "model": "gpt-4",
              "messages": [
                {
                  "role": "system",
                  "content":
                      "You are FocusMate AI, an expert productivity coach and analyst. You combine web research with app usage analytics to guide users towards their goals.",
                },
                {"role": "user", "content": prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('DEBUG: OpenAI responded with status: ${openAiRes.statusCode}');
      if (openAiRes.statusCode == 200) {
        final result = jsonDecode(openAiRes.body);
        final verdict = result['choices'][0]['message']['content'];
        // Save the verdict locally so we can show it even if offline later
        await prefs.setString('last_ai_verdict', verdict);
        return {'verdict': verdict};
      } else {
        throw Exception('OpenAI Error: ${openAiRes.body}');
      }
    } catch (e) {
      print('!!! API Error: $e');
      return {
        'error': e.toString(),
        'verdict':
            'Evaluation Failed. Check your internet connection or API keys.\n\nError details: $e',
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
