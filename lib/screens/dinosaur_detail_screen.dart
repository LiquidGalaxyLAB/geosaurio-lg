// Importa los componentes principales de Flutter para construir la interfaz visual.
import 'package:flutter/material.dart';

// Importa la pantalla de configuración de Liquid Galaxy.
import 'lg_settings_screen.dart';

// Importa la pantalla de información/acerca de la aplicación.
import 'about_screen.dart';

// Pantalla que muestra la información detallada de un dinosaurio concreto.
class DinosaurDetailScreen extends StatelessWidget {
  // Nombre del dinosaurio que se mostrará en esta pantalla.
  final String dinosaurName;

  // Constructor de la pantalla.
  // Recibe obligatoriamente el nombre del dinosaurio.
  const DinosaurDetailScreen({
    super.key,
    required this.dinosaurName,
  });

  // Indica si Liquid Galaxy está conectado.
  // Actualmente está simulado y siempre devuelve false.
  bool get isLgConnected => false;

  // Devuelve la información del dinosaurio según su nombre.
  // Si el dinosaurio existe en el mapa, devuelve sus datos.
  // Si no existe, devuelve información genérica.
  Map<String, String> getDinosaurInfo(String name) {
    // Base de datos local con información básica de varios dinosaurios.
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

    // Devuelve los datos del dinosaurio seleccionado.
    // Si no encuentra el nombre, devuelve valores por defecto.
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

  // Simula el envío de una acción a Liquid Galaxy.
  // Recibe el contexto de Flutter y el nombre de la acción seleccionada.
  void sendToLg(BuildContext context, String action) {
    // Comprueba si Liquid Galaxy está conectado.
    final success = isLgConnected;

    // Muestra un mensaje flotante indicando si el envío fue correcto o falló.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // Contenido visual del mensaje.
        content: Row(
          children: [
            // Icono de éxito o error según el estado de conexión.
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),

            // Espacio horizontal entre el icono y el texto.
            const SizedBox(width: 10),

            // Texto del mensaje.
            Expanded(
              child: Text(
                success
                    ? '$action sent correctly to Liquid Galaxy'
                    : 'Failed to send: Liquid Galaxy is not connected',
              ),
            ),
          ],
        ),

        // Color del mensaje: verde si hay éxito, rojo si falla.
        backgroundColor: success ? Colors.green : Colors.red,

        // Hace que el SnackBar aparezca flotante.
        behavior: SnackBarBehavior.floating,

        // Margen alrededor del SnackBar.
        margin: const EdgeInsets.all(16),

        // Bordes redondeados del SnackBar.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),

        // Duración del mensaje en pantalla.
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Construye toda la interfaz visual de la pantalla.
  @override
  Widget build(BuildContext context) {
    // Obtiene la información correspondiente al dinosaurio recibido.
    final info = getDinosaurInfo(dinosaurName);

    // Estructura principal de la pantalla.
    return Scaffold(
      // Color de fondo de la pantalla.
      backgroundColor: const Color(0xFFF7F4EF),

      // Menú lateral de navegación.
      drawer: buildDrawer(context),

      // Contenido principal de la pantalla.
      body: SafeArea(
        // Builder permite usar un contexto válido para abrir el Drawer.
        child: Builder(
          builder: (context) {
            // Permite hacer scroll si el contenido no cabe en pantalla.
            return SingleChildScrollView(
              // Margen horizontal del contenido.
              padding: const EdgeInsets.symmetric(horizontal: 24),

              // Organiza los elementos verticalmente.
              child: Column(
                children: [
                  // Fila superior con botón de menú y título.
                  Row(
                    children: [
                      // Botón para abrir el menú lateral.
                      IconButton(
                        icon: const Icon(Icons.menu, size: 32),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),

                      // Título centrado de la pantalla.
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

                      // Espacio para equilibrar visualmente la fila.
                      const SizedBox(width: 48),
                    ],
                  ),

                  // Espacio vertical entre el título y la tarjeta principal.
                  const SizedBox(height: 20),

                  // Tarjeta principal con imagen/icono, nombre y periodo.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: cardDecoration(),

                    // Contenido de la tarjeta principal.
                    child: Column(
                      children: [
                        // Contenedor del icono del dinosaurio.
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E1D8),
                            borderRadius: BorderRadius.circular(18),
                          ),

                          // Icono temporal que representa al dinosaurio.
                          child: const Icon(
                            Icons.pets,
                            size: 90,
                            color: Color(0xFF3E2A1F),
                          ),
                        ),

                        // Espacio entre el icono y el nombre.
                        const SizedBox(height: 18),

                        // Nombre del dinosaurio.
                        Text(
                          dinosaurName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Espacio entre el nombre y el periodo.
                        const SizedBox(height: 10),

                        // Periodo del dinosaurio.
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

                  // Espacio entre la tarjeta principal y las tarjetas de datos.
                  const SizedBox(height: 20),

                  // Primera fila de tarjetas: dieta y altura.
                  Row(
                    children: [
                      // Tarjeta de dieta.
                      Expanded(
                        child: infoCard(
                          icon: Icons.restaurant,
                          title: 'Diet',
                          value: info['diet']!,
                        ),
                      ),

                      // Espacio horizontal entre tarjetas.
                      const SizedBox(width: 12),

                      // Tarjeta de altura.
                      Expanded(
                        child: infoCard(
                          icon: Icons.height,
                          title: 'Height',
                          value: info['height']!,
                        ),
                      ),
                    ],
                  ),

                  // Espacio entre filas de tarjetas.
                  const SizedBox(height: 12),

                  // Segunda fila de tarjetas: peso y periodo.
                  Row(
                    children: [
                      // Tarjeta de peso.
                      Expanded(
                        child: infoCard(
                          icon: Icons.monitor_weight,
                          title: 'Weight',
                          value: info['weight']!,
                        ),
                      ),

                      // Espacio horizontal entre tarjetas.
                      const SizedBox(width: 12),

                      // Tarjeta de periodo.
                      Expanded(
                        child: infoCard(
                          icon: Icons.timeline,
                          title: 'Period',
                          value: info['period']!,
                        ),
                      ),
                    ],
                  ),

                  // Espacio antes de la descripción.
                  const SizedBox(height: 22),

                  // Tarjeta con la descripción del dinosaurio.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: cardDecoration(),

                    // Contenido de la descripción.
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título de la sección.
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Espacio entre el título y el texto.
                        const SizedBox(height: 12),

                        // Texto descriptivo del dinosaurio.
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

                  // Espacio antes de los botones de opciones.
                  const SizedBox(height: 24),

                  // Cuadrícula de botones con acciones para Liquid Galaxy.
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.45,

                    // Botones disponibles.
                    children: [
                      // Botón para enviar la acción de narración con IA.
                      optionButton(
                        icon: Icons.menu_book,
                        text: 'AI Narration',
                        onTap: () => sendToLg(context, 'AI Narration'),
                      ),

                      // Botón para enviar la acción de comparación.
                      optionButton(
                        icon: Icons.groups,
                        text: 'Comparison',
                        onTap: () => sendToLg(context, 'Comparison'),
                      ),

                      // Botón para enviar la acción de transformación.
                      optionButton(
                        icon: Icons.sync,
                        text: 'Transformation',
                        onTap: () => sendToLg(context, 'Transformation'),
                      ),

                      // Botón para enviar la acción del modelo 3D.
                      optionButton(
                        icon: Icons.view_in_ar,
                        text: '3D Model',
                        onTap: () => sendToLg(context, '3D Model'),
                      ),
                    ],
                  ),

                  // Espacio final inferior.
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Crea una tarjeta pequeña de información.
  // Se usa para mostrar datos como dieta, altura, peso o periodo.
  Widget infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    // Contenedor principal de la tarjeta.
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),

      // Contenido vertical de la tarjeta.
      child: Column(
        children: [
          // Icono representativo del dato.
          Icon(icon, color: Colors.brown, size: 28),

          // Espacio entre el icono y el título.
          const SizedBox(height: 8),

          // Título del dato.
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),

          // Espacio entre el título y el valor.
          const SizedBox(height: 6),

          // Valor del dato.
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  // Crea un botón de opción para ejecutar acciones relacionadas con Liquid Galaxy.
  Widget optionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    // Botón elevado con estilo personalizado.
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

      // Contenido del botón.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono del botón.
          Icon(icon, size: 30),

          // Espacio entre icono y texto.
          const SizedBox(height: 8),

          // Texto del botón.
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Devuelve una decoración común para las tarjetas de la pantalla.
  BoxDecoration cardDecoration() {
    return BoxDecoration(
      // Color de fondo de las tarjetas.
      color: Colors.white,

      // Bordes redondeados.
      borderRadius: BorderRadius.circular(22),

      // Sombra suave para dar efecto de elevación.
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Construye el menú lateral de navegación.
  Widget buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF7F4EF),

      // Evita que el contenido del menú choque con la barra superior del dispositivo.
      child: SafeArea(
        // Organiza los elementos del menú verticalmente.
        child: Column(
          children: [
            // Espacio superior del menú.
            const SizedBox(height: 28),

            // Icono principal del proyecto.
            const CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFF3E2A1F),
              child: Icon(Icons.public, size: 42, color: Colors.white),
            ),

            // Espacio entre el icono y el nombre.
            const SizedBox(height: 12),

            // Nombre de la aplicación.
            const Text(
              'GeoSaurio',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),

            // Subtítulo de la aplicación.
            const Text(
              'For Liquid Galaxy',
              style: TextStyle(color: Colors.black54),
            ),

            // Espacio antes de las opciones del menú.
            const SizedBox(height: 22),

            // Opción para volver al menú principal.
            drawerTile(
              icon: Icons.home,
              title: 'Main Menu',
              onTap: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),

            // Opción para abrir la pantalla de información.
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

            // Opción para abrir la pantalla de configuración de Liquid Galaxy.
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

            // Empuja el estado de conexión hacia la parte inferior del menú.
            const Spacer(),

            // Contenedor que muestra el estado de conexión con Liquid Galaxy.
            Container(
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),

              // Fila con icono de estado y texto.
              child: Row(
                children: [
                  // Círculo verde si está conectado, rojo si está desconectado.
                  Icon(
                    Icons.circle,
                    color: isLgConnected ? Colors.green : Colors.red,
                    size: 14,
                  ),

                  // Espacio entre el círculo y el texto.
                  const SizedBox(width: 10),

                  // Texto del estado de conexión.
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

  // Crea una opción reutilizable del menú lateral.
  Widget drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    // Añade margen alrededor de cada opción del menú.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),

      // Material permite aplicar color, bordes y efecto visual al ListTile.
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),

        // Elemento de lista del menú.
        child: ListTile(
          // Icono izquierdo.
          leading: Icon(icon, color: Colors.brown),

          // Texto principal de la opción.
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          // Icono derecho indicando navegación.
          trailing: const Icon(Icons.chevron_right, size: 20),

          // Acción al pulsar la opción.
          onTap: onTap,
        ),
      ),
    );
  }
}