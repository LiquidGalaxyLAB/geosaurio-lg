import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/lg_service.dart';

class LgSettingsScreen extends StatefulWidget {
  const LgSettingsScreen({super.key});

  @override
  State<LgSettingsScreen> createState() => _LgSettingsScreenState();
}

class _LgSettingsScreenState extends State<LgSettingsScreen> {
  final TextEditingController ipController = TextEditingController();
  final TextEditingController userController = TextEditingController(
    text: 'lg',
  );
  final TextEditingController passwordController = TextEditingController(
    text: 'lqgalaxy',
  );
  final TextEditingController portController = TextEditingController(
    text: '22',
  );
  final TextEditingController screensController = TextEditingController(
    text: '5',
  );

  bool isConnecting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings(); // Load the saved connection settings
  }

  Future<void> _loadSavedSettings() async {
    final model = await LgConnectionModel.loadFromPreferences();

    if (!mounted) return;

    setState(() {
      ipController.text = model.ip;
      userController.text = model.username;
      passwordController.text = model.password;
      portController.text = model.port.toString();
      screensController.text = model.screens.toString();
    });

    context.read<LgService>().updateConnectionSettings(
      ip: model.ip,
      port: model.port,
      username: model.username,
      password: model.password,
      screens: model.screens,
    );
  }

  @override
  void dispose() {
    ipController.dispose();
    userController.dispose();
    passwordController.dispose();
    portController.dispose();
    screensController.dispose();
    super.dispose();
  }

  void snack(String message, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int parseInt(String value, int fallback) {
    return int.tryParse(value.trim()) ?? fallback;
  }

  LgConnectionModel buildModel() {
    return LgConnectionModel(
      ip: ipController.text.trim(),
      username: userController.text.trim(),
      password: passwordController.text,
      port: parseInt(portController.text, 22),
      screens: parseInt(screensController.text, 5),
    );
  }

  Future<void> applySettings() async {
    // Save and apply the connection settings
    final model = buildModel();
    await model.saveToPreferences();

    if (!mounted) return;

    context.read<LgService>().updateConnectionSettings(
      ip: model.ip,
      port: model.port,
      username: model.username,
      password: model.password,
      screens: model.screens,
    );
  }

  Future<void> connectToLg() async {
    //connect to lg
    if (ipController.text.trim().isEmpty ||
        userController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        portController.text.trim().isEmpty ||
        screensController.text.trim().isEmpty) {
      snack('Please fill all connection fields', success: false);
      return;
    }

    setState(() => isConnecting = true);

    await applySettings();

    if (!mounted) return;

    final lgService = context.read<LgService>();
    final connected = await lgService.connectToLG() ?? false;

    if (connected) {
      await lgService.sendLogo();
    }

    if (!mounted) return;

    setState(() => isConnecting = false);

    snack(
      connected ? 'Connected to Liquid Galaxy' : 'Could not connect to LG',
      success: connected,
    );

    if (connected) {
      Navigator.pop(context, true);
    }
  }

  Future<void> disconnectLg() async {
    //Disconnect from lg
    context.read<LgService>().disconnect();
    snack('Disconnected from Liquid Galaxy');
  }

  @override
  Widget build(BuildContext context) {
    final lgService = context.watch<LgService>();
    final isConnected = lgService.isConnected;

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
                hint: 'lqgalaxy',
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
              mainButton(
                label: isConnecting
                    ? 'Connecting...'
                    : isConnected
                    ? 'Reconnect'
                    : 'Connect',
                icon: Icons.link,
                onPressed: isConnecting ? null : connectToLg,
              ),
              const SizedBox(height: 12),
              mainButton(
                label: 'Disconnect',
                icon: Icons.link_off,
                onPressed: isConnected ? disconnectLg : null,
                isSecondary: true,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget mainButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isSecondary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary
              ? Colors.grey.shade300
              : const Color(0xFF3E2A1F),
          foregroundColor: isSecondary ? Colors.grey.shade700 : Colors.white,
          elevation: isSecondary ? 0 : 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
