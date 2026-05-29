import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/LGService.dart';
import 'connection_screen.dart';

class LgSettingsScreen extends StatelessWidget {
  const LgSettingsScreen({super.key});

  void showSnack(BuildContext context, String message, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> runAction(
      BuildContext context,
      String actionName,
      Future<bool> Function(LgService lgService) action,
      ) async {
    final lgService = context.read<LgService>();

    if (!lgService.isConnected) {
      showSnack(
        context,
        'Connect to Liquid Galaxy first.',
        success: false,
      );
      return;
    }

    final ok = await action(lgService);

    showSnack(
      context,
      ok ? '$actionName completed.' : '$actionName failed.',
      success: ok,
    );
  }

  Future<void> toggleLogos(BuildContext context) async {
    final lgService = context.read<LgService>();

    if (!lgService.isConnected) {
      showSnack(context, 'Connect to Liquid Galaxy first.', success: false);
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logos'),
          content: const Text('What do you want to do?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hide'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Show'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final ok = await lgService.sendLogo();
      showSnack(context, ok ? 'Logo shown.' : 'Error showing logo.', success: ok);
    } else if (result == false) {
      await lgService.cleanLogos();
      showSnack(context, 'Logo hidden.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = context.watch<LgService>().isConnected;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'LG Settings',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
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
                padding: const EdgeInsets.all(18),
                decoration: cardDecoration(),
                child: Column(
                  children: [
                    Icon(
                      isConnected ? Icons.public : Icons.public_off,
                      size: 60,
                      color: const Color(0xFF3E2A1F),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Liquid Galaxy Control Panel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isConnected
                          ? 'Connected. Manage system actions.'
                          : 'Disconnected. Open Connection first.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    lgButton(
                      icon: Icons.restart_alt,
                      text: 'Reboot',
                      color: Colors.green,
                      onTap: () => runAction(
                        context,
                        'Reboot',
                            (lg) => lg.reboot(),
                      ),
                    ),
                    lgButton(
                      icon: Icons.refresh,
                      text: 'Relaunch',
                      color: Colors.blue,
                      onTap: () => runAction(
                        context,
                        'Relaunch',
                            (lg) => lg.relaunchLG(),
                      ),
                    ),
                    lgButton(
                      icon: Icons.power_settings_new,
                      text: 'Shutdown',
                      color: Colors.red,
                      onTap: () => runAction(
                        context,
                        'Shutdown',
                            (lg) => lg.shutdown(),
                      ),
                    ),
                    lgButton(
                      icon: Icons.visibility,
                      text: 'Show / Hide Logos',
                      color: Colors.purple,
                      onTap: () => toggleLogos(context),
                    ),
                    lgButton(
                      icon: Icons.cleaning_services,
                      text: "Clean KML's",
                      color: Colors.cyan,
                      onTap: () => runAction(
                        context,
                        "Clean KML's",
                            (lg) => lg.cleanAll(),
                      ),
                    ),
                    lgButton(
                      icon: Icons.wifi,
                      text: 'Connection',
                      color: const Color(0xFF3E2A1F),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ConnectionScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static BoxDecoration cardDecoration() {
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

  Widget lgButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 62,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: color.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}