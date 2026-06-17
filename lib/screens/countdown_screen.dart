import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n.dart';
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
    _logger.onSessionStart(0.0);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const ActiveSessionScreen(
          initialNoiseDb: 0.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String s(String key) => L10n.of(context, key);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s('place_chest'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        height: 1.5,
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

                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}