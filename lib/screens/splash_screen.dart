// Imports Dart async library.
// Used here to work with Timer and execute actions after a delay.
import 'dart:async';

// Imports the main Flutter Material Design widgets.
import 'package:flutter/material.dart';

// Imports the main screen displayed after the splash screen.
import 'home_screen.dart';

// Initial loading screen of the application.
class SplashScreen extends StatefulWidget {
  // Constant constructor for the splash screen.
  const SplashScreen({super.key});

  // Creates the state associated with this screen.
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// State class for SplashScreen.
class _SplashScreenState extends State<SplashScreen> {

  // Method executed once when the screen is created.
  @override
  void initState() {
    super.initState();

    // Waits 2 seconds and automatically navigates to HomeScreen.
    Timer(const Duration(seconds: 2), () {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    });
  }

  // Builds the visual interface of the splash screen.
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Center(

          child: Image.asset(
            'assets/images/logos.png',
            width: 340,
            fit: BoxFit.contain,
          ),

        ),
      ),
    );
  }
}