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
// Controls the temporary logic and visual interface.
class _SplashScreenState extends State<SplashScreen> {
  // Method executed once when the screen is created.
  @override
  void initState() {
    super.initState();

    // Waits 1 second and automatically navigates to HomeScreen.
    Timer(const Duration(seconds: 1), () {
      // Replaces the current screen with HomeScreen.
      // This prevents the user from returning to the splash screen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    });
  }

  // Reusable widget used to display boxes representing logos.
  // Receives the logo text and allows custom width and height.
  Widget logoBox(
      String text, {
        double width = 130,
        double height = 70,
      }) {
    // Visual logo container.
    return Container(
      width: width,
      height: height,

      // Logo box decoration.
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),

      // Centers the text inside the container.
      alignment: Alignment.center,

      // Text displayed inside the logo box.
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  // Builds the visual interface of the splash screen.
  @override
  Widget build(BuildContext context) {
    // Main screen structure.
    return Scaffold(
      // White background color.
      backgroundColor: Colors.white,

      // SafeArea prevents content overlap with system UI areas.
      body: SafeArea(
        // Padding adds horizontal spacing around the content.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),

          // Organizes all elements vertically.
          child: Column(
            children: [
              // Top flexible space used to visually center the content.
              const Spacer(flex: 2),

              // Main GeoSaurio logo.
              logoBox(
                'GeoSaurio\nLogo',
                width: 150,
                height: 150,
              ),

              // Space between logo and title.
              const SizedBox(height: 20),

              // Main application title.
              const Text(
                'GEOSAURIO',
                style: TextStyle(
                  fontSize: 22,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Space between title and subtitle.
              const SizedBox(height: 12),

              // Application subtitle.
              const Text(
                'FOR LIQUID GALAXY',
                style: TextStyle(
                  fontSize: 15,
                  letterSpacing: 1,
                ),
              ),

              // Flexible space between the main section and partner logos.
              const Spacer(flex: 2),

              // First row of collaborator logos.
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  // Google Summer of Code logo.
                  logoBox('GSoC\nLogo'),

                  // Liquid Galaxy logo.
                  logoBox('Liquid Galaxy\nLogo'),
                ],
              ),

              // Space between logo rows.
              const SizedBox(height: 35),

              // Second row of collaborator logos.
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  // Liquid Galaxy Europe logo.
                  logoBox('LG EU\nLogo'),

                  // Liquid Galaxy Lab logo.
                  logoBox('LG Lab\nLogo'),
                ],
              ),

              // Space between the second row and the last logo.
              const SizedBox(height: 35),

              // Bottom AOTIC logo.
              logoBox(
                'AOTIC\nLogo',
                width: 150,
                height: 70,
              ),

              // Bottom flexible space to balance the layout.
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}