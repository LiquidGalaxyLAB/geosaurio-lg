// Importa los widgets principales de Flutter.
import 'package:flutter/material.dart';

// Importa la pantalla principal de la app.
import 'home_screen.dart';

// Importa la pantalla de configuración de Liquid Galaxy.
import 'lg_settings_screen.dart';

// Pantalla de información sobre el proyecto.
class AboutScreen extends StatelessWidget {
  // Constructor constante de la pantalla.
  const AboutScreen({super.key});

  // Construye la interfaz visual de la pantalla.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Color de fondo de la pantalla.
      backgroundColor: const Color(0xFFF7F4EF),

      // Menú lateral de navegación.
      drawer: buildDrawer(context),

      // Contenido principal protegido por SafeArea.
      body: SafeArea(
        child: Builder(
          builder: (context) {
            // Permite hacer scroll si el contenido no cabe en pantalla.
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Espacio superior.
                  const SizedBox(height: 10),

                  // Barra superior con botón de menú y título.
                  Row(
                    children: [
                      // Botón que abre el menú lateral.
                      IconButton(
                        icon: const Icon(Icons.menu, size: 32),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),

                      // Título centrado de la pantalla.
                      const Expanded(
                        child: Text(
                          'Information',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Espacio para equilibrar visualmente la fila.
                      const SizedBox(width: 48),
                    ],
                  ),

                  // Espacio entre la barra superior y el logo.
                  const SizedBox(height: 20),

                  // Logo de GeoSaurio cargado desde assets.
                  Image.asset(
                    'assets/images/GeoSaurio.png',
                    height: 140,
                  ),

                  // Espacio entre el logo y el título.
                  const SizedBox(height: 12),

                  // Nombre de la aplicación.
                  const Text(
                    'GEOSAURIO',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Espacio entre el título y el subtítulo.
                  const SizedBox(height: 6),

                  // Subtítulo de la aplicación.
                  const Text('FOR LIQUID GALAXY'),

                  // Espacio antes de la sección del autor.
                  const SizedBox(height: 30),

                  // Título de la sección Autor.
                  const Text(
                    'Author',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  // Espacio entre título y nombre del autor.
                  const SizedBox(height: 10),

                  // Nombre del autor del proyecto.
                  const Text(
                    'Josep Miquel Sert Esteban',
                    textAlign: TextAlign.center,
                  ),

                  // Espacio antes de la descripción del proyecto.
                  const SizedBox(height: 30),

                  // Título de la sección de descripción.
                  const Text(
                    'Project Description',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  // Espacio entre título y descripción.
                  const SizedBox(height: 12),

                  // Texto descriptivo del proyecto.
                  const Text(
                    'GeoSaurio allows users to explore dinosaurs using the Liquid Galaxy platform.',
                    textAlign: TextAlign.center,
                  ),

                  // Espacio inferior final.
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Construye el menú lateral de esta pantalla.
  Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Espacio superior del menú.
            const SizedBox(height: 25),

            // Título del menú.
            const Text(
              'GeoSaurio',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            // Espacio entre el título y las opciones.
            const SizedBox(height: 25),

            // Opción para volver al menú principal.
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Main Menu'),
              onTap: () {
                // Navega a HomeScreen y elimina las pantallas anteriores.
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                      (route) => false,
                );
              },
            ),

            // Opción para abrir la pantalla de configuración de Liquid Galaxy.
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('LG Settings'),
              onTap: () {
                // Cierra el drawer actual.
                Navigator.pop(context);

                // Abre la pantalla de configuración.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LgSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}