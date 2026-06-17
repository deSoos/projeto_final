import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n.dart';
import '../main.dart' show appState;
import '../theme/app_theme.dart';
import '../utils/interaction_logger.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _logger = InteractionLogger();

  bool   _showStats          = true;
  bool   _tremorFeedback     = true;
  String _inhalePattern      = 'Long';
  String _exhalePattern      = 'Medium';
  String _slowPattern        = '3 Short';
  String _deepPattern        = '3 Medium';
  String _stabilizePattern   = '2 Short';
  String _themeChoice        = 'system'; // 'system' | 'light' | 'dark'
  String _langChoice         = 'system'; // 'system' | 'en'   | 'pt'

  static const List<String> _pulseOptions         = ['Short', 'Medium', 'Long'];
  static const List<String> _warningTripleOptions  = ['3 Short', '3 Medium', '3 Long'];
  static const List<String> _warningDoubleOptions  = ['2 Short', '2 Medium', '2 Long'];

  @override
  void initState() {
    super.initState();
    _logger.onScreenEnter('settings');
    _loadPrefs();
  }

  @override
  void dispose() {
    _logger.onScreenExit('settings');
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    String migratePulse(String? v) {
      switch (v) {
        case 'Light': return 'Short';
        case 'Heavy': return 'Long';
        default:
          if (v != null && _pulseOptions.contains(v)) return v;
          return 'Medium';
      }
    }

    String migrateWarningTriple(String? v) {
      if (v == null) return '3 Short';
      if (_warningTripleOptions.contains(v)) return v;
      if (v.contains(',')) return '3 Short';
      switch (v) {
        case 'Light':  return '3 Short';
        case 'Medium': return '3 Medium';
        case 'Heavy':  return '3 Long';
        default:       return '3 Short';
      }
    }

    String migrateWarningDouble(String? v) {
      if (v == null) return '2 Short';
      if (_warningDoubleOptions.contains(v)) return v;
      switch (v) {
        case 'Light':  return '2 Short';
        case 'Medium': return '2 Medium';
        case 'Heavy':  return '2 Long';
        default:       return '2 Short';
      }
    }

    setState(() {
      _showStats        = prefs.getBool('show_stats')          ?? true;
      _tremorFeedback   = prefs.getBool('tremor_feedback')     ?? true;
      _inhalePattern    = migratePulse(prefs.getString('inhalePattern'));
      _exhalePattern    = migratePulse(prefs.getString('exhalePattern'));
      _slowPattern      = migrateWarningTriple(prefs.getString('slowPattern'));
      _deepPattern      = migrateWarningTriple(prefs.getString('deepPattern'));
      _stabilizePattern = migrateWarningDouble(prefs.getString('stabilizePattern'));
      _themeChoice      = prefs.getString('theme_mode') ?? 'system';
      _langChoice       = prefs.getString('language')   ?? 'system';
    });
  }

  Future<void> _applyAndReturn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_stats',         _showStats);
    await prefs.setBool('tremor_feedback',    _tremorFeedback);
    await prefs.setString('inhalePattern',    _inhalePattern);
    await prefs.setString('exhalePattern',    _exhalePattern);
    await prefs.setString('slowPattern',      _slowPattern);
    await prefs.setString('deepPattern',      _deepPattern);
    await prefs.setString('stabilizePattern', _stabilizePattern);

    final modeMap = {
      'light':  ThemeMode.light,
      'dark':   ThemeMode.dark,
      'system': ThemeMode.system,
    };
    await appState.setThemeMode(modeMap[_themeChoice] ?? ThemeMode.system);
    await appState.setLanguage(_langChoice);

    _logger.onSettingsChanged('show_stats',       _showStats);
    _logger.onSettingsChanged('theme_mode',       _themeChoice);
    _logger.onSettingsChanged('language',         _langChoice);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(L10n.of(context, 'settings_saved')),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _return() => Navigator.of(context).pop();

  Future<void> _showExportDialog() async {
    final summary = await InteractionLogger().exportSummary();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.of(context, 'interaction_log')),
        content: SingleChildScrollView(
          child: Text(summary, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(L10n.of(context, 'close')),
          ),
        ],
      ),
    );
  }

  Future<void> _clearLog() async {
    await InteractionLogger().clearAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(L10n.of(context, 'log_cleared')),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String s(String key) => L10n.of(context, key);
    String optLabel(String opt) =>
        s('opt_${opt.toLowerCase().replaceAll(' ', '_')}');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s('settings'), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [

                    // appearance
                    _SectionHeader(s('theme'), context),
                    _DropdownRow<String>(
                      value: _themeChoice,
                      options: const ['system', 'light', 'dark'],
                      labels: [s('theme_system'), s('theme_light'), s('theme_dark')],
                      onChanged: (v) => setState(() => _themeChoice = v),
                    ),

                    const Divider(height: 24),

                    // language
                    _SectionHeader(s('language'), context),
                    _DropdownRow<String>(
                      value: _langChoice,
                      options: const ['system', 'en', 'pt'],
                      labels: [s('lang_system'), s('lang_en'), s('lang_pt')],
                      onChanged: (v) => setState(() => _langChoice = v),
                    ),

                    const Divider(height: 24),

                    // general
                    _SwitchRow(
                      label: s('show_stats'),
                      subtitle: s('show_stats_sub'),
                      value: _showStats,
                      onChanged: (v) => setState(() => _showStats = v),
                    ),
                    const Divider(height: 1),
                    _SwitchRow(
                      label: s('tremor_feedback'),
                      subtitle: s('tremor_feedback_sub'),
                      value: _tremorFeedback,
                      onChanged: (v) => setState(() => _tremorFeedback = v),
                    ),

                    // breath cues
                    const Divider(height: 1),
                    _SectionHeader(s('breath_cues'), context),
                    _PatternRow(
                      label: s('inhale'),
                      current: _inhalePattern,
                      options: _pulseOptions,
                      onChanged: (v) => setState(() => _inhalePattern = v!),
                      optionLabel: optLabel,
                    ),
                    _PatternRow(
                      label: s('exhale'),
                      current: _exhalePattern,
                      options: _pulseOptions,
                      onChanged: (v) => setState(() => _exhalePattern = v!),
                      optionLabel: optLabel,
                    ),

                    // warnings
                    const Divider(height: 1),
                    _SectionHeader(s('warning_patterns'), context),
                    _PatternRow(
                      label: s('breathe_slower'),
                      current: _slowPattern,
                      options: _warningTripleOptions,
                      onChanged: (v) => setState(() => _slowPattern = v!),
                      optionLabel: optLabel,
                    ),
                    _PatternRow(
                      label: s('breathe_deeper'),
                      current: _deepPattern,
                      options: _warningTripleOptions,
                      onChanged: (v) => setState(() => _deepPattern = v!),
                      optionLabel: optLabel,
                    ),
                    _PatternRow(
                      label: s('stabilize_hand'),
                      current: _stabilizePattern,
                      options: _warningDoubleOptions,
                      onChanged: (v) => setState(() => _stabilizePattern = v!),
                      optionLabel: optLabel,
                    ),

                    // dev tools
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    _SectionHeader(s('usability_tools'), context, small: true),
                    ListTile(
                      leading: const Icon(Icons.data_object, color: AppTheme.primary),
                      title: Text(s('export_log')),
                      onTap: _showExportDialog,
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      title: Text(s('clear_log')),
                      onTap: _clearLog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _applyAndReturn, child: Text(s('apply'))),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _return,
                child: Text(s('return'), style: const TextStyle(letterSpacing: 1.2)),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36, height: 4,
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

// helpers

// ignore: non_constant_identifier_names
Widget _SectionHeader(String title, BuildContext context, {bool small = false}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: small ? 13 : 14,
            color: AppTheme.subtle,
          ),
    ),
  );
}

class _DropdownRow<T> extends StatelessWidget {
  final T value;
  final List<T> options;
  final List<String> labels;
  final ValueChanged<T> onChanged;

  const _DropdownRow({
    required this.value,
    required this.options,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SegmentedButton<T>(
        segments: List.generate(
          options.length,
          (i) => ButtonSegment(value: options[i], label: Text(labels[i])),
        ),
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : AppTheme.primary,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppTheme.primary : Colors.transparent,
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.label, this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => SwitchListTile(
        title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        subtitle: subtitle != null ? Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium) : null,
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      );
}

class _PatternRow extends StatelessWidget {
  final String label;
  final String current;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String Function(String) optionLabel;

  const _PatternRow({
    required this.label,
    required this.current,
    required this.options,
    required this.onChanged,
    required this.optionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: current,
            items: options
                .map((opt) => DropdownMenuItem(
                      value: opt,
                      child: Text(optionLabel(opt)),
                    ))
                .toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
          ),
        ],
      ),
    );
  }
}