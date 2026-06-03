import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:geosaurio/services/lg_service.dart';
import 'package:geosaurio/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final lgService = LgService();
  await lgService.initializeConnection();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: lgService),
      ],
      child: const GeoSaurioApp(),
    ),
  );
}

class GeoSaurioApp extends StatelessWidget {
  const GeoSaurioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoSaurio LG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3E2A1F)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}