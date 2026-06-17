import 'dart:async';
import 'package:projeto_final/models/session_data.dart';

import "../services/haptic_service.dart";
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/interaction_logger.dart';

enum BreathPhase { inhale, hold, exhale }

extension BreathPhaseLabel on BreathPhase {
  String get labelKey {
    switch (this) {
      case BreathPhase.inhale: return 'inhale_label';
      case BreathPhase.hold:   return 'hold_label';
      case BreathPhase.exhale: return 'exhale_label';
    }
  }
  String get instructionKey {
    switch (this) {
      case BreathPhase.inhale: return 'breathe_in';
      case BreathPhase.hold:   return 'hold_breath';
      case BreathPhase.exhale: return 'breathe_out';
    }
  }
}

// durations in ms for single-pulse patterns
int _pulseMs(String key) {
  switch (key) {
    case 'Short':  return 60;
    case 'Medium': return 120;
    case 'Long':   return 250;
    default:       return 120;
  }
}

// builds a vibration pattern list for N identical pulses with gaps between them.
// Format: [delay, on, off, on, off, ...] as expected by VibrationEffect.createWaveform
List<int> _buildRepeatPattern(int count, int pulseDuration, int gapMs) {
  final pattern = <int>[];
  for (int i = 0; i < count; i++) {
    pattern.add(i == 0 ? 0 : gapMs); // pre-delay (0 for first)
    pattern.add(pulseDuration);
  }
  return pattern;
}

class FeedbackManager {
  static const int inhaleSeconds = 4;
  static const int holdSeconds   = 7;
  static const int exhaleSeconds = 8;

  final InteractionLogger _logger = InteractionLogger();

  final StreamController<BreathPhase> _phaseController = StreamController.broadcast();
  Stream<BreathPhase> get phaseStream => _phaseController.stream;

  final StreamController<double> _progressController = StreamController.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  // ignore: unused_field
  BreathPhase _currentPhase = BreathPhase.inhale;
  Timer? _phaseTimer;
  Timer? _progressTimer;
  int _cycleCount = 0;
  bool _running = false;

  // single-pulse durations (ms) for inhale / exhale
  // default: Long
  // default: Medium

  // multi-pulse pattern keys for warnings
  String _slowPatternKey     = '3 Short';
  String _deepPatternKey     = '2 Medium';
  String _stabilizePatternKey = '2 Short';

  FeedbackManager({required FeedbackMode mode}) {
    _loadPatterns();
  }

  Future<void> _loadPatterns() async {
    final prefs = await SharedPreferences.getInstance();
    _slowPatternKey     = prefs.getString('slowPattern')               ?? '3 Short';
    _deepPatternKey     = prefs.getString('deepPattern')               ?? '3 Medium';
    _stabilizePatternKey = prefs.getString('stabilizePattern')         ?? '2 Short';
  }

  // parses "3 Short" → (count: 3, pulseMs: 60)
  ({int count, int ms}) _parseWarningPattern(String key) {
    final parts = key.split(' ');
    final count = int.tryParse(parts[0]) ?? 3;
    final ms    = _pulseMs(parts.length > 1 ? parts[1] : 'Short');
    return (count: count, ms: ms);
  }

  void start() {
    _running = true;
    _runPhase(BreathPhase.inhale);
  }

  void stop() {
    _running = false;
    _phaseTimer?.cancel();
    _progressTimer?.cancel();
  }

  int get completedCycles => _cycleCount;

  void _runPhase(BreathPhase phase) {
    if (!_running) return;
    _currentPhase = phase;
    _phaseController.add(phase);

    final duration = _phaseDuration(phase);

    final start = DateTime.now();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!_running) { t.cancel(); return; }
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      final progress = (elapsed / (duration * 1000)).clamp(0.0, 1.0);
      _progressController.add(progress);
    });

    _phaseTimer = Timer(Duration(seconds: duration), () {
      if (!_running) return;
      _progressTimer?.cancel();
      _progressController.add(1.0);
      final next = _nextPhase(phase);
      if (next == BreathPhase.inhale) {
        _cycleCount++;
        _logger.onBreathCycleCompleted(_cycleCount);
      }
      _runPhase(next);
    });
  }

  int _phaseDuration(BreathPhase phase) {
    switch (phase) {
      case BreathPhase.inhale: return inhaleSeconds;
      case BreathPhase.hold:   return holdSeconds;
      case BreathPhase.exhale: return exhaleSeconds;
    }
  }

  BreathPhase _nextPhase(BreathPhase phase) {
    switch (phase) {
      case BreathPhase.inhale: return BreathPhase.hold;
      case BreathPhase.hold:   return BreathPhase.exhale;
      case BreathPhase.exhale: return BreathPhase.inhale;
    }
  }

  Future<void> _triggerWarning(String patternKey, String logLabel) async {
    
    final p = _parseWarningPattern(patternKey);
    HapticService.vibratePattern(pattern: _buildRepeatPattern(p.count, p.ms, 150));
    _logger.onHapticsTriggered(logLabel);
  }

  Future<void> triggerTooFastWarning() =>
      _triggerWarning(_slowPatternKey, 'too_fast_warning');

  Future<void> triggerTooDeeperWarning() =>
      _triggerWarning(_deepPatternKey, 'too_shallow_warning');

  Future<void> triggerStabilizeWarning() =>
      _triggerWarning(_stabilizePatternKey, 'stabilize_warning');

  void dispose() {
    stop();
    _phaseController.close();
    _progressController.close();
  }
}