import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'lg_settings_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
                  Image.asset('assets/images/GeoSaurio.png', height: 140),
                  const SizedBox(height: 12),
                  const Text(
                    'GEOSAURIO',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('FOR LIQUID GALAXY'),
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
                    'GeoSaurio is an educational Flutter application created '
                        'for Liquid Galaxy. The app allows users to explore '
                        'dinosaurs by geological period, continent, country and '
                        'species. When a dinosaur is selected, Liquid Galaxy flies '
                        'to its location and displays visual information, images, '
                        'facts and multimedia content to create an immersive '
                        'learning experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, height: 1.4),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    'Main Features',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Explore dinosaurs by period, continent and country\n'
                        '• Fly through Earth using Liquid Galaxy\n'
                        '• Display dinosaur images and information panels\n'
                        '• Use audio and visual resources for learning\n'
                        '• Designed for interactive educational demonstrations',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 25),
            const Text(
              'GeoSaurio',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Main Menu'),
              onTap: () {
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