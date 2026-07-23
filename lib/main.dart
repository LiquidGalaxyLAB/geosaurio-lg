import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:geosaurio/services/lg_service.dart';
import 'package:geosaurio/services/theme_service.dart';
import 'package:geosaurio/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final lgService = LgService();
  await lgService.initializeConnection();

  final themeService = ThemeService.instance;
  await themeService.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LgService>.value(
          value: lgService,
        ),
        ChangeNotifierProvider<ThemeService>.value(
          value: themeService,
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
    final themeService = context.watch<ThemeService>();

    return MaterialApp(
      title: 'GeoSaurio LG',
      debugShowCheckedModeBanner: false,

      themeMode: themeService.themeMode,

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3E2A1F),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F4EF),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8D6E63),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),

      home: const SplashScreen(),
    );
  }
}