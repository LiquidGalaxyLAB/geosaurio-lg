// Imports the main Flutter material components.
import 'package:flutter/material.dart';

// Screen used to configure and manage the Liquid Galaxy connection.
class ConnectionScreen extends StatefulWidget {
  // Constant constructor for the screen.
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

// State class for the ConnectionScreen.
class _ConnectionScreenState extends State<ConnectionScreen> {
  // Controller for the IP address input field.
  final TextEditingController ipController = TextEditingController();

  // Controller for the username input field.
  final TextEditingController userController = TextEditingController();

  // Controller for the password input field.
  final TextEditingController passwordController =
  TextEditingController();

  // Controller for the port input field.
  final TextEditingController portController = TextEditingController();

  // Controller for the number of screens input field.
  final TextEditingController screensController =
  TextEditingController();

  // Indicates whether the connection to Liquid Galaxy is active.
  bool isConnected = false;

  // Releases all controllers when the screen is destroyed.
  @override
  void dispose() {
    ipController.dispose();
    userController.dispose();
    passwordController.dispose();
    portController.dispose();
    screensController.dispose();
    super.dispose();
  }

  // Simulates the connection process to Liquid Galaxy.
  void connectToLg() {
    // Updates the connection state based on whether all fields are filled.
    setState(() {
      isConnected = ipController.text.isNotEmpty &&
          userController.text.isNotEmpty &&
          passwordController.text.isNotEmpty &&
          portController.text.isNotEmpty &&
          screensController.text.isNotEmpty;
    });

    // Displays a SnackBar with the connection result.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isConnected
              ? 'Connected to Liquid Galaxy'
              : 'Please fill all connection fields',
        ),

        // Green if connected, red otherwise.
        backgroundColor: isConnected ? Colors.green : Colors.red,

        // Floating style for the SnackBar.
        behavior: SnackBarBehavior.floating,
      ),
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
        child: SingleChildScrollView(
          // Horizontal padding around the content.
          padding: const EdgeInsets.symmetric(horizontal: 24),

          // Organizes the content vertically.
          child: Column(
            children: [
              // Top row with back button and title.
              Row(
                children: [
                  // Back navigation button.
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),

                  // Centered screen title.
                  const Expanded(
                    child: Text(
                      'Connection',
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

              // Space below the top bar.
              const SizedBox(height: 20),

              // Connection status card.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: cardDecoration(),

                // Card content.
                child: Column(
                  children: [
                    // Connection status icon.
                    Icon(
                      isConnected ? Icons.wifi : Icons.wifi_off,
                      size: 58,
                      color: isConnected ? Colors.green : Colors.red,
                    ),

                    // Space between icon and text.
                    const SizedBox(height: 10),

                    // Connection status text.
                    Text(
                      isConnected
                          ? 'LG Connected'
                          : 'LG Disconnected',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Space between title and description.
                    const SizedBox(height: 6),

                    // Connection description text.
                    const Text(
                      'Configure the Liquid Galaxy master machine connection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),

              // Space before the configuration fields.
              const SizedBox(height: 24),

              // IP address configuration field.
              configField(
                label: 'IP Address',
                icon: Icons.computer,
                controller: ipController,
                hint: '192.168.1.100',
              ),

              // Username configuration field.
              configField(
                label: 'Username',
                icon: Icons.person,
                controller: userController,
                hint: 'lg',
              ),

              // Password configuration field.
              configField(
                label: 'Password',
                icon: Icons.lock,
                controller: passwordController,
                hint: 'password',
                obscure: true,
              ),

              // Port configuration field.
              configField(
                label: 'Port',
                icon: Icons.settings_ethernet,
                controller: portController,
                hint: '22',
                keyboardType: TextInputType.number,
              ),

              // Number of screens configuration field.
              configField(
                label: 'Number of Screens',
                icon: Icons.screenshot_monitor,
                controller: screensController,
                hint: '5',
                keyboardType: TextInputType.number,
              ),

              // Space before the connect button.
              const SizedBox(height: 18),

              // Connect button container.
              SizedBox(
                width: double.infinity,
                height: 58,

                // Button used to connect to Liquid Galaxy.
                child: ElevatedButton.icon(
                  onPressed: connectToLg,

                  // Button icon.
                  icon: const Icon(Icons.link),

                  // Button label.
                  label: const Text(
                    'Connect',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Button styling.
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E2A1F),
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),

              // Bottom spacing.
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Creates a reusable configuration input field.
  Widget configField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,

    // Indicates whether the field hides the text.
    bool obscure = false,

    // Keyboard type used for the input field.
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      // Organizes label and text field vertically.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field label.
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          // Space between label and text field.
          const SizedBox(height: 7),

          // Text input field.
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,

            // Input field decoration.
            decoration: InputDecoration(
              hintText: hint,

              // Leading icon inside the field.
              prefixIcon: Icon(icon, color: Colors.brown),

              // Background styling.
              filled: true,
              fillColor: Colors.white,

              // Internal padding.
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),

              // Rounded border style.
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Returns a shared decoration style for cards.
  BoxDecoration cardDecoration() {
    return BoxDecoration(
      // Background color.
      color: Colors.white,

      // Rounded corners.
      borderRadius: BorderRadius.circular(22),

      // Soft shadow effect.
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}