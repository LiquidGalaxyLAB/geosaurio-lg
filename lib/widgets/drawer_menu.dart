import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../screens/home_screen.dart';
import '../../screens/about_screen.dart';
import '../../screens/lg_settings_screen.dart';
import '../../services/theme_service.dart';

class AppDrawer extends StatelessWidget {
  final bool isLgConnected;

  const AppDrawer({
    super.key,
    required this.isLgConnected,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),

            CircleAvatar(
              radius: 38,
              backgroundColor: colorScheme.primary,
              child: Icon(
                Icons.public,
                size: 42,
                color: colorScheme.onPrimary,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'GeoSaurio',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),

            Text(
              'For Liquid Galaxy',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 22),

            drawerTile(
              context: context,
              icon: Icons.home,
              title: 'Main Menu',
              onTap: () {
                Navigator.pop(context);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                      (route) => false,
                );
              },
            ),

            drawerTile(
              context: context,
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
              context: context,
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

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              child: Material(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                child: SwitchListTile(
                  secondary: Icon(
                    themeService.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: colorScheme.primary,
                  ),
                  title: const Text(
                    'Dark mode',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    themeService.isDarkMode
                        ? 'Dark theme enabled'
                        : 'Light theme enabled',
                  ),
                  value: themeService.isDarkMode,
                  activeThumbColor: colorScheme.primary,
                  onChanged: (value) {
                    themeService.setDarkMode(value);
                  },
                ),
              ),
            ),

            const Spacer(),

            Container(
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
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
                    isLgConnected
                        ? 'LG connected'
                        : 'LG disconnected',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          leading: Icon(
            icon,
            color: colorScheme.primary,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}