import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_data.dart';

/// records interaction events and session data for usability test reporting.
/// all data is stored locally in SharedPreferences as JSON.
class InteractionLogger {
  static const String _sessionsKey = 'breathin_sessions';
  static const String _eventsKey = 'breathin_events';

  static final InteractionLogger _instance = InteractionLogger._();
  factory InteractionLogger() => _instance;
  InteractionLogger._();

  final List<Map<String, dynamic>> _pendingEvents = [];
  DateTime? _screenStartTime;
  String? _currentScreen;

  int _tooFastWarningCount = 0;
  int _tremorWarningCount = 0;

  // screen timing

  void onScreenEnter(String screenName) {
    _screenStartTime = DateTime.now();
    _currentScreen = screenName;
    _log('screen_enter', {'screen': screenName});
  }

  void onScreenExit(String screenName) {
    if (_screenStartTime != null && _currentScreen == screenName) {
      final dwell = DateTime.now().difference(_screenStartTime!).inMilliseconds;
      _log('screen_exit', {'screen': screenName, 'dwell_ms': dwell});
    }
  }

  // action events

  void onSessionStart(double d) {
    _tooFastWarningCount = 0;
    _tremorWarningCount = 0;
    _log('session_start', {});
  }

  void onSessionEnd(SessionData data) {
    _log('session_end', {
      'duration_s': data.duration.inSeconds,
      'cycles': data.breathingCycles,
      'too_fast_warnings': data.tooFastWarnings,
      'tremor_warnings': data.tremorWarnings,
    });
  }

  void onSettingsChanged(String key, dynamic value) {
    _log('settings_change', {'key': key, 'value': value.toString()});
  }

  void onBreathCycleCompleted(int cycleNumber) {
    _log('breath_cycle', {'cycle': cycleNumber});
  }

  void onHapticsTriggered(String reason) {
    _log('haptic', {'reason': reason});
  }

  void onTooFastWarning() {
    _tooFastWarningCount++;
    _log('warning', {'type': 'too_fast', 'count': _tooFastWarningCount});
  }

  void onTremorWarning() {
    _tremorWarningCount++;
    _log('warning', {'type': 'tremor', 'count': _tremorWarningCount});
  }

  // persistence

  void _log(String event, Map<String, dynamic> data) {
    _pendingEvents.add({
      'ts': DateTime.now().toIso8601String(),
      'event': event,
      ...data,
    });
  }

  Future<void> saveSession(SessionData session) async {
    final prefs = await SharedPreferences.getInstance();

    final sessions = prefs.getStringList(_sessionsKey) ?? [];
    sessions.add(jsonEncode(session.toMap()));
    await prefs.setStringList(_sessionsKey, sessions);

    final events = prefs.getStringList(_eventsKey) ?? [];
    for (final e in _pendingEvents) {
      events.add(jsonEncode(e));
    }
    await prefs.setStringList(_eventsKey, events);
    _pendingEvents.clear();
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_sessionsKey) ?? [];
    return raw.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_eventsKey) ?? [];
    return raw.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  /// returns a human-readable summary string for the report appendix.
  Future<String> exportSummary() async {
    final sessions = await getSessions();
    if (sessions.isEmpty) return 'No sessions recorded.';

    final durations = sessions
        .map((s) => (s['durationSeconds'] as num).toInt())
        .toList();
    final cycles =
        sessions.map((s) => (s['breathingCycles'] as num).toInt()).toList();
    final tooFastCounts = sessions
        .map((s) => (s['tooFastWarnings'] as num? ?? 0).toInt())
        .toList();
    final tremorCounts = sessions
        .map((s) => (s['tremorWarnings'] as num? ?? 0).toInt())
        .toList();

    final avgDuration = durations.reduce((a, b) => a + b) / durations.length;
    final avgCycles = cycles.reduce((a, b) => a + b) / cycles.length;
    final avgTooFast = tooFastCounts.reduce((a, b) => a + b) / tooFastCounts.length;
    final avgTremor = tremorCounts.reduce((a, b) => a + b) / tremorCounts.length;

    final buf = StringBuffer();
    buf.writeln('Interaction Log Summary');
    buf.writeln('Total sessions      : ${sessions.length}');
    buf.writeln('Avg duration        : ${avgDuration.toStringAsFixed(0)} s');
    buf.writeln('Avg cycles          : ${avgCycles.toStringAsFixed(1)}');
    buf.writeln('Avg too-fast warns  : ${avgTooFast.toStringAsFixed(1)}');
    buf.writeln('Avg tremor warns    : ${avgTremor.toStringAsFixed(1)}');
    buf.writeln('');
    buf.writeln('Per-session detail:');
    for (var i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      buf.writeln(
          '  #${i + 1}  ${s['durationSeconds']}s  '
          '${s['breathingCycles']} cycles  '
          '${tooFastCounts[i]} too-fast  '
          '${tremorCounts[i]} tremor');
    }
    return buf.toString();
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
    await prefs.remove(_eventsKey);
  }
}