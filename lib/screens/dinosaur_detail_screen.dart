import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dinosaur.dart';
import '../services/lg_service.dart';
import '../services/audio_service.dart';

import 'lg_settings_screen.dart';
import 'about_screen.dart';

class DinosaurDetailScreen extends StatefulWidget {
  final Dinosaur dinosaur;

  const DinosaurDetailScreen({super.key, required this.dinosaur});

  @override
  State<DinosaurDetailScreen> createState() => _DinosaurDetailScreenState();
}

class _DinosaurDetailScreenState extends State<DinosaurDetailScreen> {
  bool isNarrationPlaying = false;

  Dinosaur get dinosaur => widget.dinosaur;

  void showSnack(BuildContext context, String message, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> sendToLg(BuildContext context, String action) async {
    final lgService = context.read<LgService>();

    if (!lgService.isConnected) {
      showSnack(context, 'Liquid Galaxy is not connected', success: false);
      return;
    }

    bool ok = false;

    await lgService.flyToDinosaur(dinosaur);

    if (action == 'About') {
      ok = await lgService.showDinosaurAboutColumn(dinosaur);
    } else if (action == 'Comparison') {
      ok = await lgService.showDinosaurComparisonImage(dinosaur);
    } else if (action == 'Skeleton') {
      ok = await lgService.showDinosaurSkeletonImage(dinosaur);
    }

    if (!context.mounted) return;

    showSnack(
      context,
      ok
          ? '$action sent to Liquid Galaxy'
          : 'Could not send $action to Liquid Galaxy',
      success: ok,
    );
  }

  Future<void> stopNarration() async {
    await AudioService().stop();

    if (!mounted) return;

    setState(() {
      isNarrationPlaying = false;
    });

    showSnack(context, 'Narration stopped', success: true);
  }

  @override
  void dispose() {
    AudioService().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLgConnected = context.watch<LgService>().isConnected;
    final lgService = context.read<LgService>();
    final cleanName = lgService.cleanDinosaurImageName(dinosaur.name);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      drawer: buildDrawer(context, isLgConnected),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, size: 32),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                      const Expanded(
                        child: Text(
                          'Dinosaur Information',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: cardDecoration(),
                    child: Column(
                      children: [
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E1D8),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: FutureBuilder<String?>(
                              future: lgService.getExistingImagePath(
                                'assets/images/dinosaurs/${cleanName}_normal',
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  return Image.asset(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  );
                                }

                                return const Icon(
                                  Icons.pets,
                                  size: 90,
                                  color: Color(0xFF3E2A1F),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          dinosaur.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          dinosaur.periodName,
                          style: const TextStyle(
                            fontSize: 17,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: infoCard(
                          icon: Icons.public,
                          title: 'Country',
                          value: dinosaur.country,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: infoCard(
                          icon: Icons.place,
                          title: 'Region',
                          value: dinosaur.region,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: infoCard(
                          icon: Icons.straighten,
                          title: 'Length',
                          value: dinosaur.length.isEmpty
                              ? 'Unknown'
                              : dinosaur.length,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: infoCard(
                          icon: Icons.monitor_weight,
                          title: 'Weight',
                          value: dinosaur.weight.isEmpty
                              ? 'Unknown'
                              : dinosaur.weight,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: infoCard(
                          icon: Icons.timeline,
                          title: 'Period',
                          value: dinosaur.periodName,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: infoCard(
                          icon: Icons.calendar_month,
                          title: 'Year',
                          value: dinosaur.year.isEmpty
                              ? 'Unknown'
                              : dinosaur.year,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  sectionCard(
                    title: 'Scientific Information',
                    text:
                        'Status: ${emptyText(dinosaur.status)}\n'
                        'Author: ${emptyText(dinosaur.author)}\n'
                        'Formation: ${emptyText(dinosaur.formation)}\n'
                        'Time: ${emptyText(dinosaur.time1)} - ${emptyText(dinosaur.time2)}',
                  ),

                  const SizedBox(height: 16),

                  sectionCard(
                    title: 'Fossil Material',
                    text: emptyText(dinosaur.material),
                  ),

                  const SizedBox(height: 24),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.45,
                    children: [
                      optionButton(
                        icon: Icons.info_outline,
                        text: 'About',
                        onTap: () => sendToLg(context, 'About'),
                      ),
                      optionButton(
                        icon: Icons.groups,
                        text: 'See Comparison',
                        onTap: () => sendToLg(context, 'Comparison'),
                      ),
                      optionButton(
                        icon: Icons.view_in_ar,
                        text: 'Skeleton',
                        onTap: () => sendToLg(context, 'Skeleton'),
                      ),
                      optionButton(
                        icon: Icons.volume_up,
                        text: 'Narration',
                        onTap: () async {
                          await AudioService().playDinosaurAudio(dinosaur.name);

                          if (!context.mounted) return;

                          setState(() {
                            isNarrationPlaying = true;
                          });

                          showSnack(
                            context,
                            'Narration started',
                            success: true,
                          );
                        },
                      ),
                    ],
                  ),

                  if (isNarrationPlaying) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: stopNarration,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop Narration'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final lgService = context.read<LgService>();

                        final ok = await lgService.closeChromiumOnAllScreens();

                        await AudioService().stop();

                        if (!context.mounted) return;

                        setState(() {
                          isNarrationPlaying = false;
                        });

                        showSnack(
                          context,
                          ok
                              ? 'Returned to Liquid Galaxy'
                              : 'Could not close Chromium',
                          success: ok,
                        );
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Return Back'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
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

  String emptyText(String value) {
    return value.trim().isEmpty ? 'Unknown' : value;
  }

  Widget sectionCard({required String title, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(fontSize: 16, height: 1.35)),
        ],
      ),
    );
  }

  Widget infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: Colors.brown, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            emptyText(value),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget optionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3E2A1F),
        foregroundColor: Colors.white,
        elevation: 5,
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget buildDrawer(BuildContext context, bool isLgConnected) {
    return Drawer(
      backgroundColor: const Color(0xFFF7F4EF),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            const CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFF3E2A1F),
              child: Icon(Icons.public, size: 42, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'GeoSaurio',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const Text(
              'For Liquid Galaxy',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 22),
            drawerTile(
              icon: Icons.home,
              title: 'Main Menu',
              onTap: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
            drawerTile(
              icon: Icons.info,
              title: 'Information',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
            drawerTile(
              icon: Icons.settings,
              title: 'LG Settings',
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
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: isLgConnected ? Colors.green : Colors.red,
                    size: 14,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isLgConnected ? 'LG connected' : 'LG disconnected',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          leading: Icon(icon, color: Colors.brown),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: onTap,
        ),
      ),
    );
  }
}
