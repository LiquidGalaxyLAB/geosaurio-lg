// Imports the main Flutter components used to build the visual interface.
import 'package:flutter/material.dart';

// Imports the Liquid Galaxy settings screen.
import 'lg_settings_screen.dart';

// Imports the application information/about screen.
import 'about_screen.dart';

// Screen that displays detailed information about a specific dinosaur.
class DinosaurDetailScreen extends StatelessWidget {
  // Name of the dinosaur displayed on this screen.
  final String dinosaurName;

  // Screen constructor.
  // Requires the dinosaur name.
  const DinosaurDetailScreen({
    super.key,
    required this.dinosaurName,
  });

  // Indicates whether Liquid Galaxy is connected.
  // Currently simulated and always returns false.
  bool get isLgConnected => false;

  // Returns dinosaur information based on its name.
  // If the dinosaur exists in the map, its data is returned.
  // Otherwise, generic information is returned.
  Map<String, String> getDinosaurInfo(String name) {
    // Local database containing basic dinosaur information.
    final data = {
      'Aragosaurus': {
        'period': 'Jurassic',
        'diet': 'Herbivore',
        'height': 'Around 4 meters',
        'weight': 'Around 15 tons',
        'description':
        'Aragosaurus was a large sauropod dinosaur discovered in Spain. It had a long neck, a long tail, and walked on four strong legs.',
      },
      'Turiasaurus': {
        'period': 'Jurassic',
        'diet': 'Herbivore',
        'height': 'Around 8 meters',
        'weight': 'Around 40 tons',
        'description':
        'Turiasaurus was one of the largest dinosaurs found in Europe. It lived during the Jurassic period and belonged to the sauropod group.',
      },
      'Iguanodon': {
        'period': 'Cretaceous',
        'diet': 'Herbivore',
        'height': 'Around 3 meters',
        'weight': 'Around 4 tons',
        'description':
        'Iguanodon was a plant-eating dinosaur known for its thumb spikes. It could walk on two or four legs.',
      },
      'Tamarro': {
        'period': 'Cretaceous',
        'diet': 'Carnivore',
        'height': 'Unknown',
        'weight': 'Small theropod',
        'description':
        'Tamarro was a small theropod dinosaur found in Catalonia. It is known from fossil remains and lived near the end of the Cretaceous period.',
      },
    };

    // Returns the selected dinosaur data.
    // If the dinosaur is not found, default values are returned.
    return data[name] ??
        {
          'period': 'Unknown',
          'diet': 'Unknown',
          'height': 'Unknown',
          'weight': 'Unknown',
          'description':
          '$name is part of the GeoSaurio dataset. More detailed information will be added later when the database is connected.',
        };
  }

  // Simulates sending an action to Liquid Galaxy.
  // Receives the Flutter context and the selected action name.
  void sendToLg(BuildContext context, String action) {
    // Checks whether Liquid Galaxy is connected.
    final success = isLgConnected;

    // Displays a floating message indicating success or failure.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // Visual content of the message.
        content: Row(
          children: [
            // Success or error icon depending on connection status.
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),

            // Horizontal spacing between icon and text.
            const SizedBox(width: 10),

            // Message text.
            Expanded(
              child: Text(
                success
                    ? '$action sent correctly to Liquid Galaxy'
                    : 'Failed to send: Liquid Galaxy is not connected',
              ),
            ),
          ],
        ),

        // SnackBar color: green for success, red for failure.
        backgroundColor: success ? Colors.green : Colors.red,

        // Makes the SnackBar float above the interface.
        behavior: SnackBarBehavior.floating,

        // Margin around the SnackBar.
        margin: const EdgeInsets.all(16),

        // Rounded corners for the SnackBar.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),

        // Duration of the SnackBar on screen.
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Builds the complete visual interface of the screen.
  @override
  Widget build(BuildContext context) {
    // Retrieves the dinosaur information based on the received name.
    final info = getDinosaurInfo(dinosaurName);

    // Main screen structure.
    return Scaffold(
      // Background color of the screen.
      backgroundColor: const Color(0xFFF7F4EF),

      // Side navigation drawer.
      drawer: buildDrawer(context),

      // Main content of the screen.
      body: SafeArea(
        // Builder provides a valid context to open the Drawer.
        child: Builder(
          builder: (context) {
            // Allows scrolling if the content exceeds screen size.
            return SingleChildScrollView(
              // Horizontal padding for the content.
              padding: const EdgeInsets.symmetric(horizontal: 24),

              // Organizes elements vertically.
              child: Column(
                children: [
                  // Top row with menu button and title.
                  Row(
                    children: [
                      // Button to open the side menu.
                      IconButton(
                        icon: const Icon(Icons.menu, size: 32),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),

                      // Centered screen title.
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

                      // Space to visually balance the row.
                      const SizedBox(width: 48),
                    ],
                  ),

                  // Vertical spacing between title and main card.
                  const SizedBox(height: 20),

                  // Main card with image/icon, name, and period.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: cardDecoration(),

                    // Main card content.
                    child: Column(
                      children: [
                        // Dinosaur icon container.
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E1D8),
                            borderRadius: BorderRadius.circular(18),
                          ),

                          // Temporary icon representing the dinosaur.
                          child: const Icon(
                            Icons.pets,
                            size: 90,
                            color: Color(0xFF3E2A1F),
                          ),
                        ),

                        // Spacing between icon and name.
                        const SizedBox(height: 18),

                        // Dinosaur name.
                        Text(
                          dinosaurName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Spacing between name and period.
                        const SizedBox(height: 10),

                        // Dinosaur period.
                        Text(
                          info['period']!,
                          style: const TextStyle(
                            fontSize: 17,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Space between main card and info cards.
                  const SizedBox(height: 20),

                  // First row of cards: diet and height.
                  Row(
                    children: [
                      // Diet card.
                      Expanded(
                        child: infoCard(
                          icon: Icons.restaurant,
                          title: 'Diet',
                          value: info['diet']!,
                        ),
                      ),

                      // Horizontal spacing between cards.
                      const SizedBox(width: 12),

                      // Height card.
                      Expanded(
                        child: infoCard(
                          icon: Icons.height,
                          title: 'Height',
                          value: info['height']!,
                        ),
                      ),
                    ],
                  ),

                  // Space between rows.
                  const SizedBox(height: 12),

                  // Second row of cards: weight and period.
                  Row(
                    children: [
                      // Weight card.
                      Expanded(
                        child: infoCard(
                          icon: Icons.monitor_weight,
                          title: 'Weight',
                          value: info['weight']!,
                        ),
                      ),

                      // Horizontal spacing between cards.
                      const SizedBox(width: 12),

                      // Period card.
                      Expanded(
                        child: infoCard(
                          icon: Icons.timeline,
                          title: 'Period',
                          value: info['period']!,
                        ),
                      ),
                    ],
                  ),

                  // Space before description section.
                  const SizedBox(height: 22),

                  // Card containing the dinosaur description.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: cardDecoration(),

                    // Description content.
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section title.
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Space between title and text.
                        const SizedBox(height: 12),

                        // Dinosaur description text.
                        Text(
                          info['description']!,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Space before action buttons.
                  const SizedBox(height: 24),

                  // Grid of Liquid Galaxy action buttons.
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.45,

                    // Available action buttons.
                    children: [
                      // AI narration action button.
                      optionButton(
                        icon: Icons.menu_book,
                        text: 'AI Narration',
                        onTap: () => sendToLg(context, 'AI Narration'),
                      ),

                      // Comparison action button.
                      optionButton(
                        icon: Icons.groups,
                        text: 'Comparison',
                        onTap: () => sendToLg(context, 'Comparison'),
                      ),

                      // Transformation action button.
                      optionButton(
                        icon: Icons.sync,
                        text: 'Transformation',
                        onTap: () => sendToLg(context, 'Transformation'),
                      ),

                      // 3D model action button.
                      optionButton(
                        icon: Icons.view_in_ar,
                        text: '3D Model',
                        onTap: () => sendToLg(context, '3D Model'),
                      ),
                    ],
                  ),

                  // Bottom spacing.
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Creates a small information card.
  // Used to display details such as diet, height, weight, or period.
  Widget infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    // Main card container.
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),

      // Vertical content layout.
      child: Column(
        children: [
          // Icon representing the information.
          Icon(icon, color: Colors.brown, size: 28),

          // Space between icon and title.
          const SizedBox(height: 8),

          // Information title.
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),

          // Space between title and value.
          const SizedBox(height: 6),

          // Information value.
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  // Creates an option button for Liquid Galaxy actions.
  Widget optionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    // Elevated button with custom styling.
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

      // Button content.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Button icon.
          Icon(icon, size: 30),

          // Space between icon and text.
          const SizedBox(height: 8),

          // Button text.
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
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

  // Builds the side navigation drawer.
  Widget buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF7F4EF),

      // Prevents content from overlapping device top areas.
      child: SafeArea(
        // Organizes drawer elements vertically.
        child: Column(
          children: [
            // Top spacing.
            const SizedBox(height: 28),

            // Main project icon.
            const CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFF3E2A1F),
              child: Icon(Icons.public, size: 42, color: Colors.white),
            ),

            // Space between icon and title.
            const SizedBox(height: 12),

            // Application name.
            const Text(
              'GeoSaurio',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),

            // Application subtitle.
            const Text(
              'For Liquid Galaxy',
              style: TextStyle(color: Colors.black54),
            ),

            // Space before menu options.
            const SizedBox(height: 22),

            // Main menu option.
            drawerTile(
              icon: Icons.home,
              title: 'Main Menu',
              onTap: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),

            // Information screen option.
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

            // Liquid Galaxy settings option.
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

            // Pushes connection status to the bottom.
            const Spacer(),

            // Container displaying Liquid Galaxy connection status.
            Container(
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),

              // Row with status icon and text.
              child: Row(
                children: [
                  // Green circle if connected, red if disconnected.
                  Icon(
                    Icons.circle,
                    color: isLgConnected ? Colors.green : Colors.red,
                    size: 14,
                  ),

                  // Space between icon and text.
                  const SizedBox(width: 10),

                  // Connection status text.
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

  // Creates a reusable drawer menu option.
  Widget drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    // Adds spacing around each menu item.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),

      // Material widget allows styling and visual effects.
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),

        // Drawer menu item.
        child: ListTile(
          // Left icon.
          leading: Icon(icon, color: Colors.brown),

          // Main option text.
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          // Right navigation icon.
          trailing: const Icon(Icons.chevron_right, size: 20),

          // Action when tapping the option.
          onTap: onTap,
        ),
      ),
    );
  }
}