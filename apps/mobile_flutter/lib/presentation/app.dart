import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/auth_provider.dart';
import 'router.dart';

class BeefactoryApp extends StatefulWidget {
  const BeefactoryApp({super.key});

  @override
  State<BeefactoryApp> createState() => _BeefactoryAppState();
}

class _BeefactoryAppState extends State<BeefactoryApp> {
  AppRouter? _appRouter;
  bool _initialized = false;

  Future<void> _init() async {
    final authProvider = context.read<AuthProvider>();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    final initialLocation = onboardingComplete ? '/home' : '/onboarding';
    setState(() {
      _appRouter = AppRouter(
        authProvider: authProvider,
        initialLocation: initialLocation,
      );
      _initialized = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _init();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return MaterialApp.router(
      title: 'Beefactory',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: _appRouter!.router,
    );
  }

  ThemeData _buildTheme() {
    // Beefactory Industrial Organic Design Tokens
    const voidBlack = Color(0xFF0A0A0A);
    const machinedCharcoal = Color(0xFF1C1C1E);
    const rawAmber = Color(0xFFFFB400);
    const burntGold = Color(0xFFCC9000);
    const titaniumWhite = Color(0xFFF5F5F7);
    const steelGray = Color(0xFF8E8E93);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: voidBlack,
      colorScheme: const ColorScheme.dark(
        primary: rawAmber,
        secondary: burntGold,
        surface: machinedCharcoal,
        error: Color(0xFFFF453A), // Hazard Red
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: machinedCharcoal,
        foregroundColor: titaniumWhite,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: rawAmber,
        foregroundColor: voidBlack,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: rawAmber,
          foregroundColor: voidBlack,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // Sharp machinery corners
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: titaniumWhite,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: titaniumWhite, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: machinedCharcoal,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: rawAmber, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: steelGray),
      ),
      cardTheme: CardThemeData(
        color: machinedCharcoal,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: machinedCharcoal,
        selectedItemColor: rawAmber,
        unselectedItemColor: steelGray,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: titaniumWhite, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: titaniumWhite, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: titaniumWhite),
        bodyMedium: TextStyle(color: titaniumWhite),
        titleMedium: TextStyle(color: titaniumWhite, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: steelGray),
      ),
    );
  }
}
