// Imports the main Flutter widgets.
import 'package:flutter/material.dart';

// Imports the Liquid Galaxy connection screen.
import 'connection_screen.dart';

// Liquid Galaxy settings screen.
class LgSettingsScreen extends StatelessWidget {
  // Constant constructor for the screen.
  const LgSettingsScreen({super.key});

  // Indicates whether Liquid Galaxy is connected.
  // Currently simulated and always returns false.
  // If changed to true, the actions will display success messages.
  bool get isLgConnected => false;

  // Handles Liquid Galaxy actions.
  // If not connected, shows an error alert.
  // If connected, shows a success alert.
  void handleLgAction(BuildContext context, String actionName) {
    // Stores the current connection status.
    final bool success = isLgConnected;

    // Displays a dialog with the result of the action.
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Alert title depending on the connection status.
          title: Text(
            success ? 'Action completed' : 'Action unavailable',
          ),

          // Alert message depending on the connection status.
          content: Text(
            success
                ? '$actionName completed successfully.'
                : 'Unable to perform this action. Liquid Galaxy is not connected.',
          ),

          // Button used to close the dialog.
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Builds the visual interface of the screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background color of the screen.
      backgroundColor: const Color(0xFFF7F4EF),

      // Main content protected by SafeArea.
      body: SafeArea(
        child: Padding(
          // Horizontal screen padding.
          padding: const EdgeInsets.symmetric(horizontal: 24),

          // Organizes elements vertically.
          child: Column(
            children: [
              // Top bar with back button and title.
              Row(
                children: [
                  // Button used to return to the previous screen.
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),

                  // Centered screen title.
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

                  // Space to visually balance the row.
                  const SizedBox(width: 48),
                ],
              ),

              // Space between the top bar and the main card.
              const SizedBox(height: 20),

              // Informational control panel card.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: cardDecoration(),

                child: const Column(
                  children: [
                    // Main Liquid Galaxy icon.
                    Icon(
                      Icons.public,
                      size: 60,
                      color: Color(0xFF3E2A1F),
                    ),

                    SizedBox(height: 10),

                    // Card title.
                    Text(
                      'Liquid Galaxy Control Panel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    // Short panel description.
                    Text(
                      'Manage system actions and connection settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),

              // Space between the card and the button list.
              const SizedBox(height: 24),

              // List of available Liquid Galaxy actions.
              Expanded(
                child: ListView(
                  children: [
                    // Button used to reboot Liquid Galaxy.
                    // Displays an error if disconnected.
                    // Displays success if connected.
                    lgButton(
                      icon: Icons.restart_alt,
                      text: 'Reboot',
                      color: Colors.green,
                      onTap: () {
                        handleLgAction(context, 'Reboot');
                      },
                    ),

                    // Button used to relaunch Liquid Galaxy.
                    lgButton(
                      icon: Icons.refresh,
                      text: 'Relaunch',
                      color: Colors.blue,
                      onTap: () {
                        handleLgAction(context, 'Relaunch');
                      },
                    ),

                    // Button used to shut down Liquid Galaxy.
                    lgButton(
                      icon: Icons.power_settings_new,
                      text: 'Shutdown',
                      color: Colors.red,
                      onTap: () {
                        handleLgAction(context, 'Shutdown');
                      },
                    ),

                    // Button used to show or hide logos.
                    lgButton(
                      icon: Icons.visibility,
                      text: 'Show / Hide Logos',
                      color: Colors.purple,
                      onTap: () {
                        handleLgAction(
                          context,
                          'Show / Hide Logos',
                        );
                      },
                    ),

                    // Button used to clean KML files.
                    lgButton(
                      icon: Icons.cleaning_services,
                      text: "Clean KML's",
                      color: Colors.cyan,
                      onTap: () {
                        handleLgAction(
                          context,
                          "Clean KML's",
                        );
                      },
                    ),

                    // Button used to open the connection screen.
                    // This button does not display alerts because
                    // it is used to configure the connection.
                    lgButton(
                      icon: Icons.wifi,
                      text: 'Connection',
                      color: const Color(0xFF3E2A1F),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const ConnectionScreen(),
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

  // Reusable decoration for cards.
  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      // White card background.
      color: Colors.white,

      // Rounded corners.
      borderRadius: BorderRadius.circular(22),

      // Soft shadow for depth effect.
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Creates a reusable button for Liquid Galaxy actions.
  Widget lgButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      // Bottom spacing between buttons.
      margin: const EdgeInsets.only(bottom: 14),

      // Fixed button height.
      height: 62,

      // Main button widget.
      child: ElevatedButton(
        onPressed: onTap,

        style: ElevatedButton.styleFrom(
          // Custom background color.
          backgroundColor: color,

          // Text and icon color.
          foregroundColor: Colors.white,

          // Button elevation.
          elevation: 5,

          // Shadow based on button color.
          shadowColor: color.withOpacity(0.4),

          // Rounded corners.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        // Internal button content.
        child: Row(
          children: [
            // Left button icon.
            Icon(icon, size: 26),

            // Space between icon and text.
            const SizedBox(width: 16),

            // Button text.
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Right icon indicating navigation or action.
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}