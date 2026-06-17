import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// monitors device movement using the accelerometer.
///
/// detects two distinct conditions:
///   1. [onMovementDetected] - large displacement (phone moved away from chest)
///   2. [onTremorDetected]  - high-frequency low-amplitude oscillation (hand tremor)
///   3. [onStillDetected]   - device has settled again after either condition
/// 
class MovementMonitor {
  // large movement: phone lifted/shifted
  static const double movementThreshold = 1.8; // m/s²
  // tremor: rapid small oscillations - detected via rolling variance.
  // chest breathing produces slow variance; hand tremor is much faster.
  // threshold set high enough to ignore normal breathing movement on chest.
  static const double tremorVarianceThreshold = 0.1; // (m/s²)²
  static const int _tremorWindowSize = 50; // ~600ms at typical 50Hz
  static const Duration _settleWindow = Duration(seconds: 2);
  static const Duration _calibrationDuration = Duration(milliseconds: 1200);

  StreamSubscription<AccelerometerEvent>? _subscription;

  double _baseX = 0.0, _baseY = 0.0, _baseZ = 9.8;
  bool _calibrated = false;
  final List<List<double>> _calibrationSamples = [];

  bool _isMoving = false;
  bool _isTremoring = false;
  DateTime _lastMovement = DateTime.fromMillisecondsSinceEpoch(0);

  // rolling window of magnitudes for variance calculation
  final List<double> _magnitudeWindow = [];

  void Function()? onMovementDetected;
  void Function()? onTremorDetected;
  void Function()? onStillDetected;

  int movementEventCount = 0;
  int tremorEventCount = 0;

  void start() {
    _calibrated = false;
    _calibrationSamples.clear();
    _isMoving = false;
    _isTremoring = false;
    _magnitudeWindow.clear();
    movementEventCount = 0;
    tremorEventCount = 0;

    final calibrationStart = DateTime.now();

    _subscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      final now = DateTime.now();

      if (!_calibrated) {
        _calibrationSamples.add([event.x, event.y, event.z]);
        if (now.difference(calibrationStart) >= _calibrationDuration) {
          _baseX = _calibrationSamples.map((s) => s[0]).reduce((a, b) => a + b) / _calibrationSamples.length;
          _baseY = _calibrationSamples.map((s) => s[1]).reduce((a, b) => a + b) / _calibrationSamples.length;
          _baseZ = _calibrationSamples.map((s) => s[2]).reduce((a, b) => a + b) / _calibrationSamples.length;
          _calibrated = true;
        }
        return;
      }

      final dx = event.x - _baseX;
      final dy = event.y - _baseY;
      final dz = event.z - _baseZ;
      final magnitude = sqrt(dx * dx + dy * dy + dz * dz);

      // large movement detection
      if (magnitude > movementThreshold) {
        _lastMovement = now;
        if (!_isMoving) {
          _isMoving = true;
          _isTremoring = false; // large movement overrides tremor state
          movementEventCount++;
          onMovementDetected?.call();
        }
      } else if (_isMoving && now.difference(_lastMovement) >= _settleWindow) {
        _isMoving = false;
        onStillDetected?.call();
      }

      // tremor detection (only when not already flagging large movement)
      if (!_isMoving) {
        _magnitudeWindow.add(magnitude);
        if (_magnitudeWindow.length > _tremorWindowSize) {
          _magnitudeWindow.removeAt(0);
        }

        if (_magnitudeWindow.length == _tremorWindowSize) {
          final mean = _magnitudeWindow.reduce((a, b) => a + b) / _tremorWindowSize;
          final variance = _magnitudeWindow
              .map((v) => (v - mean) * (v - mean))
              .reduce((a, b) => a + b) / _tremorWindowSize;

          if (variance > tremorVarianceThreshold && !_isTremoring) {
            _isTremoring = true;
            tremorEventCount++;
            onTremorDetected?.call();
          } else if (variance <= tremorVarianceThreshold && _isTremoring) {
            _isTremoring = false;
            onStillDetected?.call();
          }
        }
      }
    });
  }

  bool get isMoving => _isMoving;
  bool get isTremoring => _isTremoring;

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() => stop();
}