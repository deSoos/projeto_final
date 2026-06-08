import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Detects breathing rhythm using the gyroscope.
///
/// When the phone is placed against the chest/abdomen, chest movement during breathing produces subtle rotational signals. This service:
///   1. Calibrates a baseline over the first second.
///   2. Detects when the pitch (X-axis rotation) crosses a threshold above or below the baseline, which is interpreted as inhale / exhale motion.
///   3. Fires [onInhaleDetected] and [onExhaleDetected] callbacks.

class BreathingDetector {
  static const double _movementThreshold = 0.08; // rad/s
  static const Duration _calibrationDuration = Duration(milliseconds: 1000);
  static const Duration _debounce = Duration(milliseconds: 800);

  StreamSubscription<GyroscopeEvent>? _subscription;

  // calibration baseline
  double _baselineX = 0.0;
  bool _calibrated = false;
  final List<double> _calibrationSamples = [];

  // state machine
  bool _wasAbove = false;
  DateTime _lastEvent = DateTime.fromMillisecondsSinceEpoch(0);

  // callbacks
  VoidCallback? onInhaleDetected;
  VoidCallback? onExhaleDetected;

  // stats
  int detectedInhales = 0;
  int detectedExhales = 0;

  Future<void> start() async {
    _calibrated = false;
    _calibrationSamples.clear();
    detectedInhales = 0;
    detectedExhales = 0;

    final calibrationStart = DateTime.now();

    _subscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      final now = DateTime.now();

      if (!_calibrated) {
        _calibrationSamples.add(event.x);
        if (now.difference(calibrationStart) >= _calibrationDuration) {
          _baselineX = _calibrationSamples.reduce((a, b) => a + b) /
              _calibrationSamples.length;
          _calibrated = true;
        }
        return;
      }

      final delta = event.x - _baselineX;
      final magnitude = delta.abs();

      if (magnitude < _movementThreshold) return; // noise floor
      if (now.difference(_lastEvent) < _debounce) return; // debounce

      final isAbove = delta > 0;

      if (isAbove && !_wasAbove) {
        // rising motion → chest expanding → inhale
        _wasAbove = true;
        _lastEvent = now;
        detectedInhales++;
        onInhaleDetected?.call();
      } else if (!isAbove && _wasAbove) {
        // falling motion → chest contracting → exhale
        _wasAbove = false;
        _lastEvent = now;
        detectedExhales++;
        onExhaleDetected?.call();
      }
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() => stop();
}