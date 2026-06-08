import 'package:flutter/services.dart';

/// wraps the native platform channel for alarm-priority vibration.
///
/// using USAGE_ALARM on Android makes vibrations bypass the silent mode /
/// vibration intensity setting, which is particularly important on Samsung
/// One UI devices where the vibration stream can be muted independently.
///
/// Falls back to a no-op silently on platforms where the channel is absent

class HapticService {
  static const _channel = MethodChannel('com.example.projeto_final/haptic');

  static Future<void> vibrate({required int duration}) async {
    try {
      await _channel.invokeMethod('vibrate', {'duration': duration});
    } on MissingPluginException {
      // channel not available on this platform — ignore
    }
  }

  static Future<void> vibratePattern({required List<int> pattern}) async {
    try {
      await _channel.invokeMethod('vibratePattern', {'pattern': pattern});
    } on MissingPluginException {
      // channel not available on this platform — ignore
    }
  }

  static Future<void> cancel() async {
    try {
      await _channel.invokeMethod('cancel');
    } on MissingPluginException {
      // ignore
    }
  }
}