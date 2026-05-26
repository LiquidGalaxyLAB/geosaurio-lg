// Imports the main Flutter widgets and Material Design tools.
import 'package:flutter/material.dart';

// Imports the initial application screen, in this case SplashScreen.
import 'package:geosaurio/screens/splash_screen.dart';

// Main function of the application.
// This is the first method executed when the app opens.
void main() {
  // Starts the application and loads the main GeoSaurioApp widget.
  runApp(const GeoSaurioApp());
}

// Main widget of the application.
// Defines the general configuration of GeoSaurio.
class GeoSaurioApp extends StatelessWidget {
  // Constant constructor for the main widget.
  const GeoSaurioApp({super.key});

  // Builds the main structure of the application.
  @override
  Widget build(BuildContext context) {
    // MaterialApp configures the whole app:
    // title, theme, initial screen, and general options.
    return MaterialApp(
      // Application name.
      title: 'GeoSaurio',

      // Hides the red "DEBUG" banner shown in the top corner.
      debugShowCheckedModeBanner: false,

      // Defines the general visual theme of the app.
      theme: ThemeData(
        // Enables Material Design 3 to use modern styles.
        useMaterial3: true,
      ),

      // Initial screen displayed when the application opens.
      home: const SplashScreen(),
    );
  }
}