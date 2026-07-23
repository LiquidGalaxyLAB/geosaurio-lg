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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),

      drawer: buildDrawer(context),

      body: SafeArea(
        child: Builder(
          builder: (context) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, size: 32),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
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
                      const SizedBox(width: 48),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'GEOSAURIO',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'FOR LIQUID GALAXY',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Author',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Josep Miquel Sert Esteban',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Google Summer of Code 2026',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Project Description',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'GeoSaurio is an educational application developed for '
                        'the Liquid Galaxy platform during Google Summer of Code '
                        '2026. It allows users to explore dinosaurs through '
                        'interactive maps, geological periods and detailed '
                        'scientific information synchronized with Google Earth.',
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.4),
                  ),

                  const SizedBox(height: 30),

                  const Divider(
                    thickness: 1,
                    indent: 40,
                    endIndent: 40,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Developed in collaboration with',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Image.asset(
                    'assets/images/logos.png',
                    width: double.infinity,
                    height: 130,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 35),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Builds the side navigation drawer for this screen.
  Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 25),

            const Text(
              'GeoSaurio',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Main Menu'),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                      (route) => false,
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('LG Settings'),
              onTap: () {
                Navigator.pop(context);

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