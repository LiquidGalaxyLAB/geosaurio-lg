import 'package:flutter/material.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final TextEditingController ipController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController screensController = TextEditingController();

  bool isConnected = false;

  @override
  void dispose() {
    ipController.dispose();
    userController.dispose();
    passwordController.dispose();
    portController.dispose();
    screensController.dispose();
    super.dispose();
  }

  void connectToLg() {
    setState(() {
      isConnected = ipController.text.isNotEmpty &&
          userController.text.isNotEmpty &&
          passwordController.text.isNotEmpty &&
          portController.text.isNotEmpty &&
          screensController.text.isNotEmpty;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isConnected
              ? 'Connected to Liquid Galaxy'
              : 'Please fill all connection fields',
        ),
        backgroundColor: isConnected ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: SafeArea(
        child: SingleChildScrollView(
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
                      'Connection',
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
                      isConnected ? Icons.wifi : Icons.wifi_off,
                      size: 58,
                      color: isConnected ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isConnected ? 'LG Connected' : 'LG Disconnected',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Configure the Liquid Galaxy master machine connection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              configField(
                label: 'IP Address',
                icon: Icons.computer,
                controller: ipController,
                hint: '192.168.1.100',
              ),

              configField(
                label: 'Username',
                icon: Icons.person,
                controller: userController,
                hint: 'lg',
              ),

              configField(
                label: 'Password',
                icon: Icons.lock,
                controller: passwordController,
                hint: 'password',
                obscure: true,
              ),

              configField(
                label: 'Port',
                icon: Icons.settings_ethernet,
                controller: portController,
                hint: '22',
                keyboardType: TextInputType.number,
              ),

              configField(
                label: 'Number of Screens',
                icon: Icons.screenshot_monitor,
                controller: screensController,
                hint: '5',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: connectToLg,
                  icon: const Icon(Icons.link),
                  label: const Text(
                    'Connect',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget configField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 7),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: Colors.brown),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
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
}