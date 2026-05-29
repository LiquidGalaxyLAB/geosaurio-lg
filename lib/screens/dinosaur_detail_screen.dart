import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dinosaur.dart';
import '../services/LGService.dart';

import 'lg_settings_screen.dart';
import 'about_screen.dart';

class DinosaurDetailScreen extends StatelessWidget {
  final Dinosaur dinosaur;

  const DinosaurDetailScreen({
    super.key,
    required this.dinosaur,
  });

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

    final ok = await lgService.flyTo(
      '<LookAt>'
          '<longitude>0.6224</longitude>'
          '<latitude>41.6170</latitude>'
          '<range>8000</range>'
          '<tilt>45</tilt>'
          '<heading>0</heading>'
          '<altitudeMode>relativeToGround</altitudeMode>'
          '</LookAt>',
    );

    showSnack(
      context,
      ok ? '$action sent to Liquid Galaxy' : 'Error sending $action',
      success: ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLgConnected = context.watch<LgService>().isConnected;

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
                          child: const Icon(
                            Icons.pets,
                            size: 90,
                            color: Color(0xFF3E2A1F),
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
                          value:
                          dinosaur.year.isEmpty ? 'Unknown' : dinosaur.year,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  sectionCard(
                    title: 'Scientific Information',
                    text: 'Status: ${emptyText(dinosaur.status)}\n'
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
                        icon: Icons.menu_book,
                        text: 'AI Narration',
                        onTap: () => sendToLg(context, 'AI Narration'),
                      ),
                      optionButton(
                        icon: Icons.groups,
                        text: 'Comparison',
                        onTap: () => sendToLg(context, 'Comparison'),
                      ),
                      optionButton(
                        icon: Icons.sync,
                        text: 'Transformation',
                        onTap: () => sendToLg(context, 'Transformation'),
                      ),
                      optionButton(
                        icon: Icons.view_in_ar,
                        text: '3D Model',
                        onTap: () => sendToLg(context, '3D Model'),
                      ),
                    ],
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

  Widget sectionCard({
    required String title,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              height: 1.35,
            ),
          ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
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
          color: Colors.black.withOpacity(0.08),
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
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  ),
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