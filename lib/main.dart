import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:geosaurio/services/lg_service.dart';
import 'package:geosaurio/services/theme_service.dart';
import 'package:geosaurio/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final lgService = LgService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: lgService),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: const GeoSaurioApp(),
    ),
  );

  lgService.initializeConnection();
}

class GeoSaurioApp extends StatelessWidget {
  const GeoSaurioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    return MaterialApp(
      title: 'GeoSaurio LG',
      debugShowCheckedModeBanner: false,

      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3E2A1F),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F4EF),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),

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
