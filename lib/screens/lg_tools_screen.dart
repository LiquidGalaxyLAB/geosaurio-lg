import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/lg_service.dart';

class LgToolsScreen extends StatelessWidget {
  const LgToolsScreen({super.key});

  void showSnack(
    // Show the result of an action
    BuildContext context,
    String message, {
    bool success = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> confirmLgAction(
    // Ask for confirmation before important LG actions
    BuildContext context,
    String actionName,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            '$actionName Liquid Galaxy?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('Are you sure you want to $actionName Liquid Galaxy?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> runAction(
    // Run a Liquid Galaxy action
    BuildContext context,
    String actionName,
    Future<bool> Function(LgService lgService) action, {
    bool needsConfirmation = false,
  }) async {
    final lgService = context.read<LgService>();

    if (!lgService.isConnected) {
      // Check the Liquid Galaxy connection
      showSnack(context, 'Connect to Liquid Galaxy first.', success: false);
      return;
    }

    if (needsConfirmation) {
      // Ask for confirmation if needed
      final confirmed = await confirmLgAction(context, actionName);

      if (!confirmed) {
        return;
      }
    }

    showSnack(context, '$actionName command sent...', success: true);

    final ok = await action(lgService); // Execute the selected action

    if (!context.mounted) {
      return;
    }

    showSnack(
      context,
      ok ? '$actionName completed.' : '$actionName failed.',
      success: ok,
    );
  }

  Future<void> toggleLogos(
    // Show or hide the GeoSaurio logo
    BuildContext context,
  ) async {
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
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Hide'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Show'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) {
      return;
    }

    if (result == true) {
      final ok = await lgService.sendLogo();

      if (!context.mounted) {
        return;
      }

      showSnack(
        context,
        ok ? 'Logo shown.' : 'Error showing logo.',
        success: ok,
      );
    } else if (result == false) {
      await lgService.cleanLogos();

      if (!context.mounted) {
        return;
      }

      showSnack(context, 'Logo hidden.');
    }
  }

  // Build the LG tools screen

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
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),

                  const Expanded(
                    child: Text(
                      'LG Tools',
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

                    const Text(
                      'Manage the available Liquid Galaxy tools.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
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
                      onTap: () {
                        runAction(
                          context,
                          'Reboot',
                          (LgService lg) => lg.reboot(),
                          needsConfirmation: true,
                        );
                      },
                    ),

                    lgButton(
                      icon: Icons.refresh,
                      text: 'Relaunch',
                      color: Colors.blue,
                      onTap: () {
                        runAction(
                          context,
                          'Relaunch',
                          (LgService lg) => lg.relaunchLG(),
                          needsConfirmation: true,
                        );
                      },
                    ),

                    lgButton(
                      icon: Icons.power_settings_new,
                      text: 'Shutdown',
                      color: Colors.red,
                      onTap: () {
                        runAction(
                          context,
                          'Shutdown',
                          (LgService lg) => lg.shutdown(),
                          needsConfirmation: true,
                        );
                      },
                    ),

                    lgButton(
                      icon: Icons.visibility,
                      text: 'Show / Hide Logos',
                      color: Colors.purple,
                      onTap: () {
                        toggleLogos(context);
                      },
                    ),

                    lgButton(
                      icon: Icons.cleaning_services,
                      text: "Clean KML's",
                      color: Colors.cyan,
                      onTap: () {
                        runAction(
                          context,
                          "Clean KML's",
                          (LgService lg) => lg.cleanAll(),
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
          color: Colors.black.withValues(alpha: 0.08),
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
          shadowColor: color.withValues(alpha: 0.4),
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
