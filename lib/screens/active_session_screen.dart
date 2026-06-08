import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_data.dart';
import '../services/breathing_detector.dart';
import '../services/feedback_manager.dart';
import '../services/movement_monitor.dart';
import '../theme/app_theme.dart';
import '../utils/interaction_logger.dart';
import 'stats_screen.dart';

class ActiveSessionScreen extends StatefulWidget {
  final FeedbackMode feedbackMode;
  final double initialNoiseDb;

  const ActiveSessionScreen({
    super.key,
    required this.feedbackMode,
    required this.initialNoiseDb,
  });

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen>
    with TickerProviderStateMixin {
  final _logger = InteractionLogger();

  late FeedbackManager _feedbackManager;
  late BreathingDetector _breathingDetector;
  late MovementMonitor _movementMonitor;
  late SessionData _session;

  // circle animation
  late AnimationController _circleController;
  late Animation<double> _circleSize;

  BreathPhase _phase = BreathPhase.inhale;
  StreamSubscription<BreathPhase>? _phaseSub;
  StreamSubscription<double>? _progressSub;

  // hold pulse
  late AnimationController _holdPulseController;

  // warning banner
  String? _warningMessage;
  Timer? _warningTimer;

  static const double _minCircleSize = 160.0;
  static const double _maxCircleSize = 260.0;

  // whether tremor haptic feedback is enabled
  bool _tremorFeedbackEnabled = true;

  // track the guided phase timestamps
  DateTime _lastDetectedInhale = DateTime.fromMillisecondsSinceEpoch(0);

  // if two detected inhales happen faster than this, the user is breathing too fast.
  // guided inhale repeats every 19s (4+7+8) - warn if user inhales again within 12s.
  static const int _tooFastThresholdSeconds = 12;

  @override
  void initState() {
    super.initState();
    _logger.onScreenEnter('active_session');

    _session = SessionData(
      startTime: DateTime.now(),
      feedbackMode: widget.feedbackMode,
      initialNoiseDb: widget.initialNoiseDb,
    );

    _holdPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: FeedbackManager.inhaleSeconds),
    );
    _circleSize = Tween<double>(
      begin: _minCircleSize,
      end: _maxCircleSize,
    ).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOut),
    );

    _feedbackManager = FeedbackManager(mode: widget.feedbackMode);
    _breathingDetector = BreathingDetector();
    _movementMonitor = MovementMonitor();

    // tremor feedback preference
    SharedPreferences.getInstance().then((prefs) {
      _tremorFeedbackEnabled = prefs.getBool('tremor_feedback') ?? true;
    });

    // breathing detector callbacks
    // compare the detected inhale timing against the guided rhythm.
    // if the user inhales significantly earlier than the guide expects, they're breathing too fast — fire the warning
    _breathingDetector.onInhaleDetected = () {
      final now = DateTime.now();
      final timeSinceLastDetected =
          now.difference(_lastDetectedInhale).inSeconds;

      // only warn if we've seen at least one previous inhale (not first breath) and the gap between two real inhales is shorter than the threshold.
      if (_lastDetectedInhale != DateTime.fromMillisecondsSinceEpoch(0) &&
          timeSinceLastDetected < _tooFastThresholdSeconds) {
        _feedbackManager.triggerTooFastWarning();
        _showWarning('Breathe slower');
      }
      _lastDetectedInhale = now;
    };

    _breathingDetector.onExhaleDetected = () {
      // missing: breathe deeper
    };

    // movement monitor callbacks
    // when the phone is picked up / moved away from the chest, pause warnings since the gyroscope readings are no longer valid chest-motion data.
    _movementMonitor.onMovementDetected = () {
      _showWarning('Hold your phone still against your chest');
    };
    _movementMonitor.onTremorDetected = () {
      if (!_tremorFeedbackEnabled) return;
      _feedbackManager.triggerStabilizeWarning();
      _showWarning('Try to steady your hand');
    };
    _movementMonitor.onStillDetected = () {
      _clearWarning();
    };

    _phaseSub = _feedbackManager.phaseStream.listen(_onPhaseChange);
    _progressSub = _feedbackManager.progressStream.listen(_onProgress);

    _feedbackManager.start();
    _breathingDetector.start();
    _movementMonitor.start();
  }

  void _onPhaseChange(BreathPhase phase) {
    if (!mounted) return;
    setState(() => _phase = phase);

    switch (phase) {
      case BreathPhase.inhale:
        _holdPulseController.stop();
        _circleController.forward(from: 0);
        _session.totalInhales++;
        break;
      case BreathPhase.hold:
        _circleController.stop();
        _holdPulseController.repeat(reverse: true);
        break;
      case BreathPhase.exhale:
        _holdPulseController.stop();
        _circleController.reverse(from: 1);
        _session.totalExhales++;
        if (_feedbackManager.completedCycles > _session.breathingCycles) {
          _session.breathingCycles = _feedbackManager.completedCycles;
        }
        break;
    }
  }

  void _onProgress(double progress) {
    // gyroscope-sync logic
  }

  void _showWarning(String message) {
    if (!mounted) return;
    _warningTimer?.cancel();
    setState(() => _warningMessage = message);
    // auto-dismiss after 3 seconds
    _warningTimer = Timer(const Duration(seconds: 3), _clearWarning);
  }

  void _clearWarning() {
    if (!mounted) return;
    _warningTimer?.cancel();
    setState(() => _warningMessage = null);
  }

  Future<void> _endSession() async {
    _session.breathingCycles = _feedbackManager.completedCycles;
    _session.finish();

    _feedbackManager.stop();
    _breathingDetector.stop();
    _movementMonitor.stop();

    _logger.onSessionEnd(_session);
    await _logger.saveSession(_session);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StatsScreen(session: _session),
      ),
    );
  }

  Color get _phaseColor {
    switch (_phase) {
      case BreathPhase.inhale:
        return AppTheme.primary;
      case BreathPhase.hold:
        return AppTheme.primaryDark;
      case BreathPhase.exhale:
        return AppTheme.primaryLight;
    }
  }

  @override
  void dispose() {
    _logger.onScreenExit('active_session');
    _warningTimer?.cancel();
    _phaseSub?.cancel();
    _progressSub?.cancel();
    _feedbackManager.dispose();
    _breathingDetector.dispose();
    _movementMonitor.dispose();
    _circleController.dispose();
    _holdPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // top status bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.feedbackMode == FeedbackMode.haptic
                              ? Icons.vibration
                              : Icons.visibility_outlined,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.feedbackMode == FeedbackMode.haptic
                              ? 'Haptic'
                              : 'Visual',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<BreathPhase>(
                    stream: _feedbackManager.phaseStream,
                    builder: (_, __) => Text(
                      'Cycle ${_feedbackManager.completedCycles + 1}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),

              // warning banner
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _warningMessage != null
                    ? Container(
                        key: ValueKey(_warningMessage),
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.orange, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _warningMessage!,
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(key: ValueKey('empty'), height: 0),
              ),

              // animated breathing cycle
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: Listenable.merge(
                            [_circleController, _holdPulseController]),
                        builder: (context, child) {
                          final holdOpacity = _phase == BreathPhase.hold
                              ? 0.85 + _holdPulseController.value * 0.15
                              : 1.0;
                          return Opacity(
                            opacity: holdOpacity,
                            child: Container(
                              width: _circleSize.value,
                              height: _circleSize.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _phaseColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: _phaseColor.withValues(alpha: 0.35),
                                    blurRadius: 48,
                                    spreadRadius: 12,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'KEEP\nBREATHING',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _phase.instruction,
                          key: ValueKey(_phase),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.subtle,
                                    fontStyle: FontStyle.italic,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // end session button
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: _endSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'END SESSION',
                        style: TextStyle(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.subtle.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}