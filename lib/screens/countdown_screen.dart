import 'dart:async';
import 'package:flutter/material.dart';
import '../models/session_data.dart';
import '../theme/app_theme.dart';
import '../utils/interaction_logger.dart';
import 'active_session_screen.dart';

/// 3-second countdown shown immediately after "START SESSION" is tapped
class CountdownScreen extends StatefulWidget {
  const CountdownScreen({super.key});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen>
    with SingleTickerProviderStateMixin {
  final _logger = InteractionLogger();

  int _count = 3;
  final FeedbackMode _feedbackMode = FeedbackMode.haptic;
  final bool _ready = false;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _logger.onScreenEnter('countdown');

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 1.2, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    _startCountdown();
  }

  @override
  void dispose() {
    _logger.onScreenExit('countdown');
    _countdownTimer?.cancel();
    _scaleController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _scaleController.forward(from: 0);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_count <= 1) {
        timer.cancel();
        _navigateToSession();
        return;
      }
      setState(() => _count--);
      _scaleController.forward(from: 0);
    });
  }

  void _navigateToSession() {
    if (!mounted) return;
    _logger.onSessionStart(_feedbackMode, 0.0);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ActiveSessionScreen(
          feedbackMode: _feedbackMode,
          initialNoiseDb: 0.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const modeText = 'Place your phone against\nyour chest.';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  modeText,
                  key: ValueKey(_ready),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.onSurface,
                        height: 1.5,
                      ),
                ),
              ),

              const SizedBox(height: 48),

              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 36,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$_count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              if (_ready)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _feedbackMode == FeedbackMode.haptic
                            ? Icons.vibration
                            : Icons.visibility_outlined,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _feedbackMode == FeedbackMode.haptic
                            ? 'Haptic mode'
                            : 'Visual mode',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),

              const Spacer(),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.subtle.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}