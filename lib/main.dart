import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'app_state.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

final appState = AppState();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await appState.load(); // restore saved theme + language

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const BreathinApp());
}

class BreathinApp extends StatefulWidget {
  const BreathinApp({super.key});

  @override
  State<BreathinApp> createState() => _BreathinAppState();
}

class _BreathinAppState extends State<BreathinApp> {
  @override
  void initState() {
    super.initState();
    appState.addListener(_onStateChanged);
  }

  void _onStateChanged() => setState(() {});

  @override
  void dispose() {
    appState.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Breathin'",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.themeMode,
      locale: appState.locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('pt')],
      home: const HomeScreen(),
    );
  }
}
