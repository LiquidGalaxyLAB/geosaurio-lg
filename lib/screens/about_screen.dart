import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/lg_service.dart';
import '../widgets/drawer_menu.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lgService = context.watch<LgService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,

      drawer: AppDrawer(
        isLgConnected: lgService.isConnected,
      ),

      body: SafeArea(
        child: Builder(
          builder: (context) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 10,
              ),
              child: Column(
                children: [
                  // --------------------------------------------------
                  // TOP BAR
                  // --------------------------------------------------

                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                          colorScheme.surfaceContainerHighest,
                          borderRadius:
                          BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.menu,
                            size: 30,
                          ),
                          onPressed: () {
                            Scaffold.of(context)
                                .openDrawer();
                          },
                        ),
                      ),

                      const Expanded(
                        child: Text(
                          'Information',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),

                      // --------------------------------------------------
                      // CONNECTION INDICATOR
                      // --------------------------------------------------

                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme
                              .surfaceContainerHighest,
                          borderRadius:
                          BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize:
                          MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 12,
                              color:
                              lgService.isConnected
                                  ? Colors.green
                                  : Colors.red,
                            ),

                            const SizedBox(width: 6),

                            Text(
                              lgService.isConnected
                                  ? 'Connected'
                                  : 'Disconnected',
                              style: TextStyle(
                                fontWeight:
                                FontWeight.w600,
                                color: colorScheme
                                    .onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --------------------------------------------------
                  // GEOSAURIO LOGO
                  // --------------------------------------------------

                  Image.asset(
                    'assets/images/Geosaurio.png',
                    height: 170,
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'GEOSAURIO',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'FOR LIQUID GALAXY',
                    style: TextStyle(
                      color:
                      colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --------------------------------------------------
                  // ABOUT GEOSAURIO
                  // --------------------------------------------------

                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme
                          .surfaceContainerHighest,
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 35,
                          color: colorScheme.primary,
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'About GeoSaurio',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          'GeoSaurio is an educational application developed for the Liquid Galaxy platform as part of Google Summer of Code.\n\n'
                              'The application allows users to explore dinosaurs by geological period, continent and country while visualizing their locations in Google Earth. '
                              'It also provides scientific information, narration, skeleton visualizations and comparison images to create an interactive educational experience.',
                          textAlign:
                          TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --------------------------------------------------
                  // AUTHOR
                  // --------------------------------------------------

                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme
                          .surfaceContainerHighest,
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person,
                          size: 35,
                          color: colorScheme.primary,
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Author',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Josep Miquel Sert Esteban',
                          textAlign:
                          TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --------------------------------------------------
                  // ACKNOWLEDGEMENTS
                  // --------------------------------------------------

                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme
                          .surfaceContainerHighest,
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.handshake,
                          size: 35,
                          color: colorScheme.primary,
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Acknowledgements',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          'I would like to express my sincere gratitude to Andreu, my mentors Victor and Gabriel and the Liquid Galaxy LAB team who contributed to the development of GeoSaurio. '
                              'Their assistance, support and valuable feedback played an important role in making this project possible.\n\n'
                              'Special thanks to:\n\n'
                              '• Alex Moix — for creating the complete dinosaur database, providing all the images used in the application, and generating the AI-narrated audio for every dinosaur.\n\n'
                              '• Paula Torné — GeoSaurio logo design.\n\n',
                          textAlign:
                          TextAlign.left,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
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
}