import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n.dart';
import '../models/session_data.dart';
import '../theme/app_theme.dart';
import '../utils/interaction_logger.dart';
import 'home_screen.dart';

const _gifs = [
  'assets/gifs/congratulations-evangelion.gif',
  'assets/gifs/dog-smile.gif',
  'assets/gifs/happy_dog.gif',
  'assets/gifs/sheep_thumbsup.gif',
  'assets/gifs/spongebob_thumbsup.gif',
];

class StatsScreen extends StatefulWidget {
  final SessionData session;
  const StatsScreen({super.key, required this.session});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  final _logger = InteractionLogger();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late String _selectedGif;

  @override
  void initState() {
    super.initState();
    _logger.onScreenEnter('stats');
    _selectedGif = _gifs[Random().nextInt(_gifs.length)];
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _logger.onScreenExit('stats');
    _fadeController.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  String _formatDuration() {
    final min = widget.session.durationMinutes;
    final sec = widget.session.durationSeconds;
    if (min > 0) return '${min}m ${sec}s';
    return '${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    String s(String key) => L10n.of(context, key);
    final cycleLabel = session.breathingCycles == 1
        ? s('breathing_cycles')
        : s('breathing_cycles_p');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Text(s('good_job'),
                    style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 12),
                Text(
                  '${s('completed')}\n${session.breathingCycles} $cycleLabel ${s('in_duration')} ${_formatDuration()}.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _GifOrEmoji(gifPath: _selectedGif),
                      const SizedBox(height: 16),
                      _StatRow(label: s('duration'), value: _formatDuration()),
                      _StatRow(label: cycleLabel, value: '${session.breathingCycles}'),
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _goHome,
                  icon: const Icon(Icons.home_outlined, size: 20),
                  label: Text(s('main_menu')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5),
                  ),
                ),
                const SizedBox(height: 20),
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
        ),
      ),
    );
  }
}

class _GifOrEmoji extends StatelessWidget {
  final String gifPath;
  const _GifOrEmoji({required this.gifPath});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      gifPath,
      height: 120,
      errorBuilder: (_, __, ___) =>
          const Text('🌿', style: TextStyle(fontSize: 64)),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    // theme colors for dark/light changes
    final textColor = Theme.of(context).colorScheme.onSurface;
    final labelColor = Theme.of(context).textTheme.bodyMedium?.color ?? AppTheme.subtle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}