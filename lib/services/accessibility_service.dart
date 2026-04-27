import 'dart:async';
import 'package:flutter/services.dart';

class AppAccessibilityService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.focusmate.ai/accessibility');
  static const EventChannel _eventChannel =
      EventChannel('com.focusmate.ai/app_events');

  /// Stream of foreground app package names
  static Stream<String> get onForegroundAppChanged =>
      _eventChannel.receiveBroadcastStream().cast<String>();

  /// Checks if the accessibility service is enabled in Android settings
  static Future<bool> isServiceEnabled() async {
    try {
      final bool isEnabled = await _methodChannel.invokeMethod('isAccessibilityServiceEnabled');
      return isEnabled;
    } on PlatformException catch (e) {
      print("Failed to check accessibility service status: '${e.message}'.");
      return false;
    }
  }

  /// Opens the Android Accessibility Settings page
  static Future<void> openSettings() async {
    try {
      await _methodChannel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      print("Failed to open accessibility settings: '${e.message}'.");
    }
  }
}
