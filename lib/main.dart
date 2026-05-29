import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:geosaurio/screens/splash_screen.dart';
import 'package:geosaurio/services/LGService.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LgService(),
      child: const GeoSaurioApp(),
    ),
  );
}

class GeoSaurioApp extends StatelessWidget {
  const GeoSaurioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoSaurio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}