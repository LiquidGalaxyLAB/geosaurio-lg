import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:geosaurio/services/lg_service.dart';
import 'package:geosaurio/services/theme_service.dart';
import 'package:geosaurio/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Liquid Galaxy service.
  final lgService = LgService();
  await lgService.initializeConnection();

  runApp(
    MultiProvider(
      providers: [
        // Liquid Galaxy service.
        ChangeNotifierProvider.value(
          value: lgService,
        ),

        // Application theme service.
        ChangeNotifierProvider(
          create: (_) => ThemeService(),
        ),
      ],
      child: const GeoSaurioApp(),
    ),
  );
}

class GeoSaurioApp extends StatelessWidget {
  const GeoSaurioApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen for light/dark mode changes.
    final themeService = context.watch<ThemeService>();

    return MaterialApp(
      title: 'GeoSaurio LG',
      debugShowCheckedModeBanner: false,

      // Select the current theme.
      themeMode: themeService.isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light,

      // Light theme.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3E2A1F),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F4EF),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),

      // Dark theme.
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3E2A1F),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),

      home: const SplashScreen(),
    );
  }
}