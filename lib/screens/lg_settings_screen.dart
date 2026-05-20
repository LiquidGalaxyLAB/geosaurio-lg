// Importa los widgets principales de Flutter.
import 'package:flutter/material.dart';

// Importa la pantalla de conexión con Liquid Galaxy.
import 'connection_screen.dart';

// Pantalla de configuración de Liquid Galaxy.
class LgSettingsScreen extends StatelessWidget {
  // Constructor constante de la pantalla.
  const LgSettingsScreen({super.key});

  // Indica si Liquid Galaxy está conectado o no.
  // Actualmente está simulado y siempre devuelve false.
  // Si lo cambias a true, las acciones mostrarán mensaje de éxito.
  bool get isLgConnected => false;

  // Gestiona las acciones de Liquid Galaxy.
  // Si no está conectado, muestra una alerta de error.
  // Si está conectado, muestra una alerta de éxito.
  void handleLgAction(BuildContext context, String actionName) {
    // Guarda el estado actual de conexión.
    final bool success = isLgConnected;

    // Muestra una ventana emergente con el resultado de la acción.
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Título de la alerta según el estado de conexión.
          title: Text(
            success ? 'Action completed' : 'Action unavailable',
          ),

          // Mensaje de la alerta según el estado de conexión.
          content: Text(
            success
                ? '$actionName completed successfully.'
                : 'Unable to perform this action. Liquid Galaxy is not connected.',
          ),

          // Botón para cerrar la alerta.
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

  // Construye la interfaz visual de la pantalla.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Color de fondo de la pantalla.
      backgroundColor: const Color(0xFFF7F4EF),

      // Contenido principal dentro de SafeArea.
      body: SafeArea(
        child: Padding(
          // Margen horizontal de la pantalla.
          padding: const EdgeInsets.symmetric(horizontal: 24),

          // Organiza los elementos verticalmente.
          child: Column(
            children: [
              // Barra superior con botón de volver y título.
              Row(
                children: [
                  // Botón para volver a la pantalla anterior.
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),

                  // Título centrado de la pantalla.
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

                  // Espacio para equilibrar visualmente la fila.
                  const SizedBox(width: 48),
                ],
              ),

              // Espacio entre la barra superior y la tarjeta principal.
              const SizedBox(height: 20),

              // Tarjeta informativa del panel de control.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: cardDecoration(),
                child: const Column(
                  children: [
                    // Icono principal de Liquid Galaxy.
                    Icon(
                      Icons.public,
                      size: 60,
                      color: Color(0xFF3E2A1F),
                    ),

                    SizedBox(height: 10),

                    // Título de la tarjeta.
                    Text(
                      'Liquid Galaxy Control Panel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    // Descripción breve del panel.
                    Text(
                      'Manage system actions and connection settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),

              // Espacio entre la tarjeta y la lista de botones.
              const SizedBox(height: 24),

              // Lista de acciones disponibles para Liquid Galaxy.
              Expanded(
                child: ListView(
                  children: [
                    // Botón para reiniciar Liquid Galaxy.
                    // Si no está conectado, muestra alerta de error.
                    // Si está conectado, muestra alerta de éxito.
                    lgButton(
                      icon: Icons.restart_alt,
                      text: 'Reboot',
                      color: Colors.green,
                      onTap: () {
                        handleLgAction(context, 'Reboot');
                      },
                    ),

                    // Botón para relanzar Liquid Galaxy.
                    lgButton(
                      icon: Icons.refresh,
                      text: 'Relaunch',
                      color: Colors.blue,
                      onTap: () {
                        handleLgAction(context, 'Relaunch');
                      },
                    ),

                    // Botón para apagar Liquid Galaxy.
                    lgButton(
                      icon: Icons.power_settings_new,
                      text: 'Shutdown',
                      color: Colors.red,
                      onTap: () {
                        handleLgAction(context, 'Shutdown');
                      },
                    ),

                    // Botón para mostrar u ocultar los logos.
                    lgButton(
                      icon: Icons.visibility,
                      text: 'Show / Hide Logos',
                      color: Colors.purple,
                      onTap: () {
                        handleLgAction(context, 'Show / Hide Logos');
                      },
                    ),

                    // Botón para limpiar archivos KML.
                    lgButton(
                      icon: Icons.cleaning_services,
                      text: "Clean KML's",
                      color: Colors.cyan,
                      onTap: () {
                        handleLgAction(context, "Clean KML's");
                      },
                    ),

                    // Botón para abrir la pantalla de conexión.
                    // Este botón no muestra alerta porque sirve para configurar la conexión.
                    lgButton(
                      icon: Icons.wifi,
                      text: 'Connection',
                      color: const Color(0xFF3E2A1F),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ConnectionScreen(),
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

  // Decoración reutilizable para tarjetas.
  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      // Fondo blanco de la tarjeta.
      color: Colors.white,

      // Bordes redondeados.
      borderRadius: BorderRadius.circular(22),

      // Sombra suave para dar profundidad.
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Crea un botón reutilizable para acciones de Liquid Galaxy.
  Widget lgButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      // Separación inferior entre botones.
      margin: const EdgeInsets.only(bottom: 14),

      // Altura fija del botón.
      height: 62,

      // Botón principal.
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          // Color de fondo personalizado.
          backgroundColor: color,

          // Color del texto e iconos.
          foregroundColor: Colors.white,

          // Elevación del botón.
          elevation: 5,

          // Sombra basada en el color del botón.
          shadowColor: color.withOpacity(0.4),

          // Bordes redondeados.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        // Contenido interno del botón.
        child: Row(
          children: [
            // Icono izquierdo del botón.
            Icon(icon, size: 26),

            // Espacio entre icono y texto.
            const SizedBox(width: 16),

            // Texto del botón.
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Icono derecho que indica navegación o acción.
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}