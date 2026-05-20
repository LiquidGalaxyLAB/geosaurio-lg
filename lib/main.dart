// Importa los widgets y herramientas principales de Flutter con Material Design.
import 'package:flutter/material.dart';

// Importa la pantalla inicial de la aplicación, en este caso la SplashScreen.
import 'package:geosaurio/screens/splash_screen.dart';

// Función principal de la aplicación.
// Es el primer método que se ejecuta cuando se abre la app.
void main() {
  // Inicia la aplicación y carga el widget principal GeoSaurioApp.
  runApp(const GeoSaurioApp());
}

// Widget principal de la aplicación.
// Define la configuración general de GeoSaurio.
class GeoSaurioApp extends StatelessWidget {
  // Constructor constante del widget principal.
  const GeoSaurioApp({super.key});

  // Construye la estructura principal de la aplicación.
  @override
  Widget build(BuildContext context) {
    // MaterialApp configura la app completa:
    // título, tema, pantalla inicial y opciones generales.
    return MaterialApp(
      // Nombre de la aplicación.
      title: 'GeoSaurio',

      // Oculta la etiqueta roja de "DEBUG" que aparece en la esquina superior.
      debugShowCheckedModeBanner: false,

      // Define el tema visual general de la app.
      theme: ThemeData(
        // Activa Material Design 3 para usar estilos modernos.
        useMaterial3: true,
      ),

      // Pantalla inicial que se muestra al abrir la aplicación.
      home: const SplashScreen(),
    );
  }
}