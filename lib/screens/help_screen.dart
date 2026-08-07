import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/lg_service.dart';
import '../widgets/drawer_menu.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme
                              .surfaceContainerHighest,
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
                          'Help',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 12,
                              color: lgService.isConnected
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
                                color:
                                colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  helpCard(
                    context: context,
                    icon: Icons.explore,
                    title: 'How to explore dinosaurs',
                    text:
                    'Select a geological period, then choose a continent, country and dinosaur. '
                        'GeoSaurio will move the Liquid Galaxy view and display the selected dinosaur information.',
                  ),

                  const SizedBox(height: 16),

                  helpCard(
                    context: context,
                    icon: Icons.settings,
                    title: 'LG Settings',
                    text:
                    'Use LG Settings to configure the Liquid Galaxy connection, including IP address, port, username, password and number of screens.',
                  ),

                  const SizedBox(height: 16),

                  helpCard(
                    context: context,
                    icon: Icons.handyman,
                    title: 'LG Tools',
                    text:
                    'Use LG Tools to reboot, relaunch or shut down the Liquid Galaxy system, manage logos and clean KML content.',
                  ),

                  const SizedBox(height: 16),

                  helpCard(
                    context: context,
                    icon: Icons.threesixty,
                    title: 'Orbit',
                    text:
                    'Use Orbit to move the camera around the selected dinosaur location. '
                        'Press Stop Orbit to stop the movement.',
                  ),

                  const SizedBox(height: 16),

                  helpCard(
                    context: context,
                    icon: Icons.view_in_ar,
                    title: 'Skeleton and Comparison',
                    text:
                    'Use Skeleton and See Comparison to display additional dinosaur visualizations across the Liquid Galaxy screens.',
                  ),

                  const SizedBox(height: 16),

                  helpCard(
                    context: context,
                    icon: Icons.volume_up,
                    title: 'Narration',
                    text:
                    'Press Narration to listen to the dinosaur audio description. '
                        'Use Stop Narration to stop the audio.',
                  ),

                  const SizedBox(height: 16),

                  helpCard(
                    context: context,
                    icon: Icons.circle,
                    title: 'Connection indicator',
                    text:
                    'A green indicator means GeoSaurio is connected to Liquid Galaxy. '
                        'A red indicator means the connection is not currently active.',
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

  Widget helpCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String text,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
        colorScheme.surfaceContainerHighest,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 34,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color:
              colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}