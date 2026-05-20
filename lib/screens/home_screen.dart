// Importa los widgets principales de Flutter.
import 'package:flutter/material.dart';

// Importa la pantalla de detalle del dinosaurio.
import 'dinosaur_detail_screen.dart';

// Importa la pantalla de configuración de Liquid Galaxy.
import 'lg_settings_screen.dart';

// Importa la pantalla de información de la app.
import 'about_screen.dart';

// Pantalla principal de la aplicación.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // Crea el estado asociado a HomeScreen.
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Enum que define los periodos geológicos disponibles.
enum GeologicalPeriod {
  triassic,
  jurassic,
  cretaceous,
}

// Estado de la pantalla principal.
class _HomeScreenState extends State<HomeScreen> {
  // Periodo geológico seleccionado inicialmente.
  GeologicalPeriod selectedPeriod = GeologicalPeriod.jurassic;

  // Variables que guardan la selección actual del usuario.
  String? selectedContinent;
  String? selectedCountry;
  String? expandedRegion;
  String? selectedDinosaur;

  // Controlador del campo de búsqueda.
  final TextEditingController searchController = TextEditingController();

  // Lista de países agrupados por continente.
  final Map<String, List<String>> countriesByContinent = {
    'Africa': ['Algeria', 'Egypt', 'Morocco', 'South Africa', 'Tunisia'],
    'Antarctica': ['Antarctica'],
    'Asia': ['China', 'India', 'Japan', 'Mongolia', 'Russia', 'Turkey'],
    'Europe': [
      'Spain',
      'France',
      'Germany',
      'Italy',
      'United Kingdom',
      'Portugal',
      'Netherlands',
      'Belgium',
    ],
    'North America': ['Canada', 'United States', 'Mexico'],
    'Oceania': ['Australia', 'New Zealand'],
    'South America': ['Argentina', 'Brazil', 'Chile', 'Colombia', 'Peru'],
  };

  // Lista de regiones y dinosaurios disponibles por país.
  final Map<String, Map<String, List<String>>> regionsByCountry = {
    'Spain': {
      'Aragón': ['Aragosaurus'],
      'Catalonia': ['Pararhabdodon', 'Tamarro'],
      'Asturias': ['Asturceratops'],
      'Castilla y León': ['Demandasaurus'],
      'La Rioja': ['Riojavenatrix', 'Demandasaurus', 'Turiasaurus', 'Iguanodon'],
      'Valencia': ['Morelladon'],
    },
  };

  // Relaciona cada dinosaurio con su periodo geológico.
  final Map<String, GeologicalPeriod> dinosaurPeriods = {
    'Aragosaurus': GeologicalPeriod.jurassic,
    'Turiasaurus': GeologicalPeriod.jurassic,
    'Pararhabdodon': GeologicalPeriod.cretaceous,
    'Tamarro': GeologicalPeriod.cretaceous,
    'Asturceratops': GeologicalPeriod.cretaceous,
    'Demandasaurus': GeologicalPeriod.cretaceous,
    'Riojavenatrix': GeologicalPeriod.cretaceous,
    'Iguanodon': GeologicalPeriod.cretaceous,
    'Morelladon': GeologicalPeriod.cretaceous,
  };

  // Devuelve la lista de continentes disponibles.
  List<String> get continents => countriesByContinent.keys.toList();

  // Libera el controlador de búsqueda cuando la pantalla se destruye.
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Convierte el enum del periodo geológico en texto visible.
  String getPeriodName(GeologicalPeriod period) {
    switch (period) {
      case GeologicalPeriod.triassic:
        return 'Triassic';
      case GeologicalPeriod.jurassic:
        return 'Jurassic';
      case GeologicalPeriod.cretaceous:
        return 'Cretaceous';
    }
  }

  // Comprueba si un dinosaurio pertenece al periodo seleccionado.
  bool dinosaurMatchesSelectedPeriod(String dinosaur) {
    return dinosaurPeriods[dinosaur] == selectedPeriod;
  }

  // Filtra países según el texto introducido en el buscador.
  List<String> filteredCountries(List<String> countries) {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) return countries;

    return countries.where((country) {
      return country.toLowerCase().contains(query);
    }).toList();
  }

  // Filtra regiones según el texto introducido en el buscador.
  Map<String, List<String>> filteredRegions(Map<String, List<String>> regions) {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) return regions;

    return Map.fromEntries(
      regions.entries.where((entry) {
        return entry.key.toLowerCase().contains(query);
      }),
    );
  }

  // Selecciona un país y limpia selecciones anteriores.
  void selectCountry(String country) {
    setState(() {
      selectedCountry = country;
      expandedRegion = null;
      selectedDinosaur = null;
      searchController.clear();
    });
  }

  // Vuelve desde la vista de regiones a la lista de países.
  void goBackToCountries() {
    setState(() {
      selectedCountry = null;
      expandedRegion = null;
      selectedDinosaur = null;
      searchController.clear();
    });
  }

  // Muestra un mensaje indicando que se ha enviado algo a Liquid Galaxy.
  void showLgMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text('Sent correctly to Liquid Galaxy'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Construye la pantalla principal.
  @override
  Widget build(BuildContext context) {
    // Obtiene los países del continente seleccionado.
    final List<String> countries = selectedContinent == null
        ? []
        : countriesByContinent[selectedContinent] ?? [];

    // Obtiene las regiones del país seleccionado.
    final Map<String, List<String>> regions =
    selectedCountry == null ? {} : regionsByCountry[selectedCountry] ?? {};

    // Estructura principal de la pantalla.
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      drawer: buildDrawer(),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  // Barra superior con menú y título.
                  buildTopBar(context),

                  const SizedBox(height: 18),

                  // Título que cambia según la selección actual.
                  Text(
                    selectedCountry ?? 'Select geological period',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 18),

                  // Selector de periodo geológico.
                  buildPeriodSelector(),

                  const SizedBox(height: 24),

                  // Si no hay país seleccionado, muestra continentes y países.
                  // Si hay país seleccionado, muestra regiones y dinosaurios.
                  if (selectedCountry == null)
                    buildContinentSelector(countries)
                  else
                    buildRegionSelector(regions),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Construye la barra superior de la pantalla.
  Widget buildTopBar(BuildContext context) {
    return Row(
      children: [
        // Botón para abrir el menú lateral.
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            icon: const Icon(Icons.menu, size: 30),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),

        const Spacer(),

        // Título de la aplicación.
        const Text(
          'GeoSaurio',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const Spacer(),

        // Espacio para equilibrar visualmente la barra.
        const SizedBox(width: 48),
      ],
    );
  }

  // Construye los tres botones de periodos geológicos.
  Widget buildPeriodSelector() {
    return Row(
      children: [
        Expanded(child: periodButton(GeologicalPeriod.triassic)),
        const SizedBox(width: 8),
        Expanded(child: periodButton(GeologicalPeriod.jurassic)),
        const SizedBox(width: 8),
        Expanded(child: periodButton(GeologicalPeriod.cretaceous)),
      ],
    );
  }

  // Construye la vista para seleccionar continente y país.
  Widget buildContinentSelector(List<String> countries) {
    // Países visibles después de aplicar el filtro de búsqueda.
    final visibleCountries = filteredCountries(countries);

    return Expanded(
      child: Column(
        children: [
          // Texto principal de la sección.
          const Text(
            'Select a continent to explore',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // Caja de búsqueda para continentes o países.
          searchBox(
            hintText: selectedContinent == null
                ? 'Search continent...'
                : 'Search country...',
          ),

          const SizedBox(height: 16),

          // Dropdown para elegir continente.
          continentDropdown(),

          const SizedBox(height: 18),

          // Contenedor con la lista de países.
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: cardDecoration(),

              // Muestra mensaje vacío, mensaje de búsqueda o lista de países.
              child: selectedContinent == null
                  ? emptyMessage(
                icon: Icons.public,
                text: 'Select a continent\nto see countries',
              )
                  : visibleCountries.isEmpty
                  ? emptyMessage(
                icon: Icons.search_off,
                text: 'No countries found',
              )
                  : Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  itemCount: visibleCountries.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final country = visibleCountries[index];

                    return niceListTile(
                      title: country,
                      icon: Icons.flag,
                      onTap: () => selectCountry(country),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Construye la vista de regiones y dinosaurios de un país.
  Widget buildRegionSelector(Map<String, List<String>> regions) {
    // Regiones visibles después de aplicar el filtro de búsqueda.
    final visibleRegions = filteredRegions(regions);

    return Expanded(
      child: Column(
        children: [
          // Buscador de regiones.
          searchBox(hintText: 'Search regions...'),

          const SizedBox(height: 18),

          // Contenedor con la lista de regiones.
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: cardDecoration(),

              // Si no hay regiones, muestra un mensaje.
              child: visibleRegions.isEmpty
                  ? emptyMessage(
                icon: Icons.map_outlined,
                text: 'No regions available\nfor this country yet',
              )
                  : Scrollbar(
                thumbVisibility: true,

                // Lista de regiones disponibles.
                child: ListView(
                  children: visibleRegions.entries.map((entry) {
                    final regionName = entry.key;

                    // Filtra los dinosaurios de la región según el periodo seleccionado.
                    final dinosaurs = entry.value
                        .where((dinosaur) =>
                        dinosaurMatchesSelectedPeriod(dinosaur))
                        .toList();

                    // Si no hay dinosaurios para ese periodo, no muestra la región.
                    if (dinosaurs.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    // Comprueba si la región está desplegada.
                    final isExpanded = expandedRegion == regionName;

                    // Tarjeta de región.
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        children: [
                          // Cabecera de la región.
                          ListTile(
                            leading: const Icon(Icons.place),
                            title: Text(
                              regionName,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                            ),
                            onTap: () {
                              setState(() {
                                expandedRegion =
                                isExpanded ? null : regionName;
                                selectedDinosaur = null;
                              });
                            },
                          ),

                          // Si la región está desplegada, muestra sus dinosaurios.
                          if (isExpanded)
                            ...dinosaurs.map((dinosaur) {
                              final isSelected =
                                  selectedDinosaur == dinosaur;

                              return Column(
                                children: [
                                  // Dinosaurio dentro de la región.
                                  ListTile(
                                    title: Text(
                                      dinosaur,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        selectedDinosaur = dinosaur;
                                      });
                                    },
                                  ),

                                  // Si el dinosaurio está seleccionado, muestra botones de acción.
                                  if (isSelected)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          // Botón para enviar acción de rotación a LG.
                                          lgActionButton(
                                            icon: Icons.rotate_right,
                                            text: 'Rotate',
                                            onTap: () {
                                              showLgMessage();
                                            },
                                          ),

                                          const SizedBox(width: 12),

                                          // Botón para abrir la pantalla de detalle del dinosaurio.
                                          lgActionButton(
                                            icon: Icons.info,
                                            text: 'About',
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      DinosaurDetailScreen(
                                                        dinosaurName:
                                                        dinosaur,
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            }),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Botón para volver a la lista de países.
          ElevatedButton.icon(
            onPressed: goBackToCountries,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to countries'),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Crea una caja de búsqueda reutilizable.
  Widget searchBox({required String hintText}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),

      // Campo de texto para buscar.
      child: TextField(
        controller: searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search),

          // Si hay texto escrito, muestra botón para limpiar.
          suffixIcon: searchController.text.isEmpty
              ? null
              : IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                searchController.clear();
              });
            },
          ),
        ),
      ),
    );
  }

  // Crea el desplegable para seleccionar continente.
  Widget continentDropdown() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),

      // Oculta la línea inferior por defecto del DropdownButton.
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedContinent,
          isExpanded: true,
          hint: const Text(
            'Select Continent',
            style: TextStyle(fontSize: 17, color: Colors.black),
          ),
          icon: const Icon(Icons.keyboard_arrow_down),

          // Crea las opciones del desplegable a partir de la lista de continentes.
          items: continents.map((continent) {
            return DropdownMenuItem(
              value: continent,
              child: Text(continent),
            );
          }).toList(),

          // Cambia el continente seleccionado y limpia selecciones anteriores.
          onChanged: (value) {
            setState(() {
              selectedContinent = value;
              selectedCountry = null;
              expandedRegion = null;
              selectedDinosaur = null;
              searchController.clear();
            });
          },
        ),
      ),
    );
  }

  // Crea una fila visual reutilizable para listas.
  Widget niceListTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        leading: Icon(icon, color: Colors.brown),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // Muestra un mensaje centrado cuando no hay contenido disponible.
  Widget emptyMessage({
    required IconData icon,
    required String text,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 55, color: Colors.black38),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // Decoración reutilizable para tarjetas y contenedores principales.
  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFE8E1D8),
      borderRadius: BorderRadius.circular(20),
    );
  }

  // Botón reutilizable para acciones relacionadas con Liquid Galaxy.
  Widget lgActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3E2A1F),
        foregroundColor: Colors.white,
      ),
    );
  }

  // Crea un botón para seleccionar un periodo geológico.
  Widget periodButton(GeologicalPeriod period) {
    // Comprueba si este periodo es el que está seleccionado.
    final bool isSelected = selectedPeriod == period;

    return GestureDetector(
      // Cambia el periodo seleccionado al pulsar.
      onTap: () {
        setState(() {
          selectedPeriod = period;
          expandedRegion = null;
          selectedDinosaur = null;
        });
      },

      // Contenedor visual del botón.
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3E2A1F) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black12),
        ),

        // Nombre del periodo.
        child: Text(
          getPeriodName(period),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Construye el menú lateral de la aplicación.
  Widget buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFFF7F4EF),
      child: SafeArea(
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

            const SizedBox(height: 22),

            // Opción para volver/cerrar el menú principal.
            drawerTile(
              icon: Icons.home,
              title: 'Main Menu',
              onTap: () => Navigator.pop(context),
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

            // Opción para abrir la configuración de Liquid Galaxy.
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

            // Opción de idioma.
            // Actualmente solo imprime un mensaje en consola.
            drawerTile(
              icon: Icons.language,
              title: 'Language',
              onTap: () {
                debugPrint('Language tapped');
              },
            ),

            // Empuja el estado de conexión hacia abajo.
            const Spacer(),

            // Indicador visual de conexión con Liquid Galaxy.
            Container(
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, color: Colors.red, size: 14),
                  SizedBox(width: 10),
                  Text(
                    'LG disconnected',
                    style: TextStyle(fontWeight: FontWeight.w500),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          leading: Icon(icon, color: Colors.brown),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: onTap,
        ),
      ),
    );
  }
}