// Importa la librería async de Dart.
// Se usa aquí para utilizar Timer y ejecutar una acción después de un tiempo.
import 'dart:async';

// Importa los widgets principales de Flutter con Material Design.
import 'package:flutter/material.dart';

// Importa la pantalla principal a la que se navegará después del splash.
import 'home_screen.dart';

// Pantalla de carga inicial de la aplicación.
class SplashScreen extends StatefulWidget {
  // Constructor constante de la pantalla splash.
  const SplashScreen({super.key});

  // Crea el estado asociado a esta pantalla.
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Estado de la pantalla SplashScreen.
// Aquí se controla la lógica temporal y la interfaz.
class _SplashScreenState extends State<SplashScreen> {
  // Método que se ejecuta una sola vez cuando la pantalla se crea.
  @override
  void initState() {
    super.initState();

    // Espera 1 segundo y después cambia automáticamente a la pantalla HomeScreen.
    Timer(const Duration(seconds: 1), () {
      // Reemplaza la pantalla actual por HomeScreen.
      // Así el usuario no puede volver al splash con el botón atrás.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    });
  }

  // Widget reutilizable para mostrar cajas que representan logos.
  // Recibe el texto del logo y permite personalizar ancho y alto.
  Widget logoBox(String text, {double width = 130, double height = 70}) {
    // Contenedor visual del logo.
    return Container(
      width: width,
      height: height,

      // Decoración de la caja del logo.
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),

      // Centra el texto dentro del contenedor.
      alignment: Alignment.center,

      // Texto que aparece dentro de la caja del logo.
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  // Construye la interfaz visual de la pantalla splash.
  @override
  Widget build(BuildContext context) {
    // Estructura principal de la pantalla.
    return Scaffold(
      // Fondo blanco de la pantalla.
      backgroundColor: Colors.white,

      // SafeArea evita que el contenido se solape con la barra de estado o zonas del sistema.
      body: SafeArea(
        // Padding añade margen horizontal al contenido.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),

          // Organiza todos los elementos verticalmente.
          child: Column(
            children: [
              // Espacio flexible superior para centrar visualmente el contenido principal.
              const Spacer(flex: 2),

              // Logo principal de GeoSaurio.
              logoBox(
                'GeoSaurio\nLogo',
                width: 150,
                height: 150,
              ),

              // Espacio entre el logo principal y el título.
              const SizedBox(height: 20),

              // Nombre principal de la aplicación.
              const Text(
                'GEOSAURIO',
                style: TextStyle(
                  fontSize: 22,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Espacio entre el título y el subtítulo.
              const SizedBox(height: 12),

              // Subtítulo de la aplicación.
              const Text(
                'FOR LIQUID GALAXY',
                style: TextStyle(
                  fontSize: 15,
                  letterSpacing: 1,
                ),
              ),

              // Espacio flexible entre el bloque principal y los logos inferiores.
              const Spacer(flex: 2),

              // Primera fila de logos colaboradores.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo de Google Summer of Code.
                  logoBox('GSoC\nLogo'),

                  // Logo de Liquid Galaxy.
                  logoBox('Liquid Galaxy\nLogo'),
                ],
              ),

              // Espacio entre filas de logos.
              const SizedBox(height: 35),

              // Segunda fila de logos colaboradores.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo de Liquid Galaxy Europe.
                  logoBox('LG EU\nLogo'),

                  // Logo del laboratorio de Liquid Galaxy.
                  logoBox('LG Lab\nLogo'),
                ],
              ),

              // Espacio entre la segunda fila y el último logo.
              const SizedBox(height: 35),

              // Logo inferior de AOTIC.
              logoBox('AOTIC\nLogo', width: 150, height: 70),

              // Espacio flexible inferior para equilibrar la pantalla.
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}