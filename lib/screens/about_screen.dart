// Imports the main Flutter widgets.
import 'package:flutter/material.dart';

// Imports the main application screen.
import 'home_screen.dart';

// Imports the Liquid Galaxy settings screen.
import 'lg_settings_screen.dart';

// Information screen about the project.
class AboutScreen extends StatelessWidget {
  // Constant constructor for the screen.
  const AboutScreen({super.key});

  // Builds the visual interface of the screen.
  @override
  Widget build(BuildContext context) { //Declaration of what the user would see  background color, name of the application, etc
    return Scaffold(
      // Background color of the screen.
      backgroundColor: const Color(0xFFF7F4EF),

      // Side navigation drawer.
      drawer: buildDrawer(context),

      // Main content protected by SafeArea.
      body: SafeArea(
        child: Builder(
          builder: (context) {

            return SingleChildScrollView( // scrolling in case the content exceeds the screen size.
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Top spacing.
                  const SizedBox(height: 10),

                  // Top bar with menu button and title.
                  Row(
                    children: [
                      // Button that opens the side drawer.
                      IconButton(
                        icon: const Icon(Icons.menu, size: 32),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),

                      // Centered screen title.
                      const Expanded(
                        child: Text(
                          'Information',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Space to visually balance the row.
                      const SizedBox(width: 48),
                    ],
                  ),

                  // Space between top bar and logo.
                  const SizedBox(height: 20),

                  // GeoSaurio logo loaded from assets.
                  Image.asset('assets/images/GeoSaurio.png', height: 140),

                  // Space between logo and title.
                  const SizedBox(height: 12),

                  // Application name.
                  const Text(
                    'GEOSAURIO',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  // Space between title and subtitle.
                  const SizedBox(height: 6),

                  // Application subtitle.
                  const Text('FOR LIQUID GALAXY'),

                  // Space before author section.
                  const SizedBox(height: 30),

                  // Author section title.
                  const Text(
                    'Author',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  // Space between title and author name.
                  const SizedBox(height: 10),

                  // Project author name.
                  const Text(
                    'Josep Miquel Sert Esteban',
                    textAlign: TextAlign.center,
                  ),

                  // Space before project description section.
                  const SizedBox(height: 30),

                  // Project description section title.
                  const Text(
                    'Project Description',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  // Space between title and description.
                  const SizedBox(height: 12),

                  // Project description text.
                  const Text(
                    'GeoSaurio allows users to explore dinosaurs using the Liquid Galaxy platform.',
                    textAlign: TextAlign.center,
                  ),

                  // Final bottom spacing.
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  //Side menu that will allow the user to move between different screens
  Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Top spacing inside the drawer.
            const SizedBox(height: 25),

            // Drawer title.
            const Text(
              'GeoSaurio',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),


            const SizedBox(height: 25),

            // Option to return to the main menu.
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Main Menu'),
              onTap: () {
                // Go to HomeScreen and removes previous screens.
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              },
            ),


            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('LG Settings'),
              onTap: () {
                // Closes the current drawer.
                Navigator.pop(context);

                // Opens the settings screen.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LgSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
