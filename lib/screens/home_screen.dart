// Imports the main Flutter widgets.
import 'package:flutter/material.dart';

// Imports the dinosaur detail screen.
import 'dinosaur_detail_screen.dart';

// Imports the Liquid Galaxy settings screen.
import 'lg_settings_screen.dart';

// Imports the application information screen.
import 'about_screen.dart';

// Main application screen.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // Creates the state associated with HomeScreen.
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Enum that defines the available geological periods.
enum GeologicalPeriod {
  triassic,
  jurassic,
  cretaceous,
}

// State class for the main screen.
class _HomeScreenState extends State<HomeScreen> {
  // Initially selected geological period.
  GeologicalPeriod selectedPeriod = GeologicalPeriod.jurassic;

  // Variables storing the current user selection.
  String? selectedContinent;
  String? selectedCountry;
  String? expandedRegion;
  String? selectedDinosaur;

  // Search field controller.
  final TextEditingController searchController = TextEditingController();

  // List of countries grouped by continent.
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

  // List of regions and dinosaurs available by country.
  final Map<String, Map<String, List<String>>> regionsByCountry = {
    'Spain': {
      'Aragón': ['Aragosaurus'],
      'Catalonia': ['Pararhabdodon', 'Tamarro'],
      'Asturias': ['Asturceratops'],
      'Castilla y León': ['Demandasaurus'],
      'La Rioja': [
        'Riojavenatrix',
        'Demandasaurus',
        'Turiasaurus',
        'Iguanodon',
      ],
      'Valencia': ['Morelladon'],
    },
  };

  // Maps each dinosaur to its geological period.
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

  // Returns the list of available continents.
  List<String> get continents => countriesByContinent.keys.toList();

  // Releases the search controller when the screen is destroyed.
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Converts the geological period enum into visible text.
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

  // Checks whether a dinosaur belongs to the selected period.
  bool dinosaurMatchesSelectedPeriod(String dinosaur) {
    return dinosaurPeriods[dinosaur] == selectedPeriod;
  }

  // Filters countries according to the search text.
  List<String> filteredCountries(List<String> countries) {
    final query = searchController.text.toLowerCase();

    if (query.isEmpty) return countries;

    return countries.where((country) {
      return country.toLowerCase().contains(query);
    }).toList();
  }

  // Filters regions according to the search text.
  Map<String, List<String>> filteredRegions(
      Map<String, List<String>> regions,
      ) {
    final query = searchController.text.toLowerCase();

    if (query.isEmpty) return regions;

    return Map.fromEntries(
      regions.entries.where((entry) {
        return entry.key.toLowerCase().contains(query);
      }),
    );
  }

  // Selects a country and clears previous selections.
  void selectCountry(String country) {
    setState(() {
      selectedCountry = country;
      expandedRegion = null;
      selectedDinosaur = null;
      searchController.clear();
    });
  }

  // Returns from the regions view to the countries list.
  void goBackToCountries() {
    setState(() {
      selectedCountry = null;
      expandedRegion = null;
      selectedDinosaur = null;
      searchController.clear();
    });
  }

  // Displays a message indicating something was sent to Liquid Galaxy.
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

  // Builds the main screen.
  @override
  Widget build(BuildContext context) {
    // Retrieves the countries for the selected continent.
    final List<String> countries = selectedContinent == null
        ? []
        : countriesByContinent[selectedContinent] ?? [];

    // Retrieves the regions for the selected country.
    final Map<String, List<String>> regions =
    selectedCountry == null
        ? {}
        : regionsByCountry[selectedCountry] ?? {};

    // Main screen structure.
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
                  // Top bar with menu and title.
                  buildTopBar(context),

                  const SizedBox(height: 18),

                  // Dynamic title depending on current selection.
                  Text(
                    selectedCountry ?? 'Select geological period',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 18),

                  // Geological period selector.
                  buildPeriodSelector(),

                  const SizedBox(height: 24),

                  // If no country is selected, show continents and countries.
                  // Otherwise, show regions and dinosaurs.
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

  // Builds the top bar of the screen.
  Widget buildTopBar(BuildContext context) {
    return Row(
      children: [
        // Button used to open the side drawer.
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

        // Application title.
        const Text(
          'GeoSaurio',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const Spacer(),

        // Space to visually balance the bar.
        const SizedBox(width: 48),
      ],
    );
  }

  // Builds the geological period selector buttons.
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

  // Builds the continent and country selection view.
  Widget buildContinentSelector(List<String> countries) {
    // Countries visible after applying the search filter.
    final visibleCountries = filteredCountries(countries);

    return Expanded(
      child: Column(
        children: [
          // Main section title.
          const Text(
            'Select a continent to explore',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Search box for continents or countries.
          searchBox(
            hintText: selectedContinent == null
                ? 'Search continent...'
                : 'Search country...',
          ),

          const SizedBox(height: 16),

          // Dropdown used to select a continent.
          continentDropdown(),

          const SizedBox(height: 18),

          // Container with the list of countries.
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: cardDecoration(),

              // Displays empty message, search message, or country list.
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
                    final country =
                    visibleCountries[index];

                    return niceListTile(
                      title: country,
                      icon: Icons.flag,
                      onTap: () =>
                          selectCountry(country),
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

  // Builds the regions and dinosaurs view for a country.
  Widget buildRegionSelector(
      Map<String, List<String>> regions,
      ) {
    // Regions visible after applying the search filter.
    final visibleRegions = filteredRegions(regions);

    return Expanded(
      child: Column(
        children: [
          // Region search box.
          searchBox(hintText: 'Search regions...'),

          const SizedBox(height: 18),

          // Container with the list of regions.
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: cardDecoration(),

              // Displays a message if no regions are available.
              child: visibleRegions.isEmpty
                  ? emptyMessage(
                icon: Icons.map_outlined,
                text:
                'No regions available\nfor this country yet',
              )
                  : Scrollbar(
                thumbVisibility: true,

                // List of available regions.
                child: ListView(
                  children: visibleRegions.entries.map((entry) {
                    final regionName = entry.key;

                    // Filters dinosaurs according to the selected period.
                    final dinosaurs = entry.value
                        .where(
                          (dinosaur) =>
                          dinosaurMatchesSelectedPeriod(
                            dinosaur,
                          ),
                    )
                        .toList();

                    // If no dinosaurs exist for the selected period,
                    // the region is not displayed.
                    if (dinosaurs.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    // Checks whether the region is expanded.
                    final isExpanded =
                        expandedRegion == regionName;

                    // Region card.
                    return Container(
                      margin:
                      const EdgeInsets.only(bottom: 10),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(16),

                        border: Border.all(
                          color: Colors.black12,
                        ),
                      ),

                      child: Column(
                        children: [
                          // Region header.
                          ListTile(
                            leading:
                            const Icon(Icons.place),

                            title: Text(
                              regionName,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),

                            trailing: Icon(
                              isExpanded
                                  ? Icons
                                  .keyboard_arrow_up
                                  : Icons
                                  .keyboard_arrow_down,
                            ),

                            onTap: () {
                              setState(() {
                                expandedRegion = isExpanded
                                    ? null
                                    : regionName;

                                selectedDinosaur = null;
                              });
                            },
                          ),

                          // If expanded, display the region dinosaurs.
                          if (isExpanded)
                            ...dinosaurs.map((dinosaur) {
                              final isSelected =
                                  selectedDinosaur ==
                                      dinosaur;

                              return Column(
                                children: [
                                  // Dinosaur item.
                                  ListTile(
                                    title: Text(
                                      dinosaur,
                                      textAlign:
                                      TextAlign.center,
                                      style:
                                      const TextStyle(
                                        fontSize: 20,
                                        fontWeight:
                                        FontWeight.w500,
                                      ),
                                    ),

                                    onTap: () {
                                      setState(() {
                                        selectedDinosaur =
                                            dinosaur;
                                      });
                                    },
                                  ),

                                  // If selected, display action buttons.
                                  if (isSelected)
                                    Padding(
                                      padding:
                                      const EdgeInsets.only(
                                        bottom: 14,
                                      ),

                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,

                                        children: [
                                          // Rotate action button.
                                          lgActionButton(
                                            icon: Icons
                                                .rotate_right,
                                            text: 'Rotate',
                                            onTap: () {
                                              showLgMessage();
                                            },
                                          ),

                                          const SizedBox(
                                            width: 12,
                                          ),

                                          // Opens the dinosaur detail screen.
                                          lgActionButton(
                                            icon:
                                            Icons.info,
                                            text: 'About',
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                      context,
                                                      ) =>
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

          // Button to return to the countries list.
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

  // Creates a reusable search box.
  Widget searchBox({required String hintText}) {
    return Container(
      height: 48,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),

      // Text field used for searching.
      child: TextField(
        controller: searchController,

        onChanged: (_) => setState(() {}),

        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search),

          // If text exists, show a clear button.
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

  // Creates the dropdown used to select a continent.
  Widget continentDropdown() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),

      // Hides the default underline of the DropdownButton.
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedContinent,
          isExpanded: true,

          hint: const Text(
            'Select Continent',
            style: TextStyle(
              fontSize: 17,
              color: Colors.black,
            ),
          ),

          icon: const Icon(Icons.keyboard_arrow_down),

          // Creates dropdown options from the continent list.
          items: continents.map((continent) {
            return DropdownMenuItem(
              value: continent,
              child: Text(continent),
            );
          }).toList(),

          // Updates the selected continent and clears previous selections.
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

  // Creates a reusable visual list tile.
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

  // Displays a centered message when no content is available.
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
            style: const TextStyle(
              fontSize: 19,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Shared decoration used for cards and main containers.
  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFE8E1D8),
      borderRadius: BorderRadius.circular(20),
    );
  }

  // Reusable button for Liquid Galaxy actions.
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

  // Creates a button for selecting a geological period.
  Widget periodButton(GeologicalPeriod period) {
    // Checks whether this period is currently selected.
    final bool isSelected = selectedPeriod == period;

    return GestureDetector(
      // Updates the selected period when tapped.
      onTap: () {
        setState(() {
          selectedPeriod = period;
          expandedRegion = null;
          selectedDinosaur = null;
        });
      },

      // Visual container for the button.
      child: Container(
        height: 45,
        alignment: Alignment.center,

        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3E2A1F)
              : Colors.white,

          borderRadius: BorderRadius.circular(22),

          border: Border.all(color: Colors.black12),
        ),

        // Geological period name.
        child: Text(
          getPeriodName(period),

          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Colors.black,

            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Builds the side navigation drawer.
  Widget buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFFF7F4EF),

      child: SafeArea(
        child: Column(
          children: [
            // Top spacing.
            const SizedBox(height: 28),

            // Main project icon.
            const CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFF3E2A1F),
              child: Icon(
                Icons.public,
                size: 42,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            // Application name.
            const Text(
              'GeoSaurio',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Application subtitle.
            const Text(
              'For Liquid Galaxy',
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 22),

            // Main menu option.
            drawerTile(
              icon: Icons.home,
              title: 'Main Menu',
              onTap: () => Navigator.pop(context),
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
                    builder: (context) =>
                    const AboutScreen(),
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
                    builder: (context) =>
                    const LgSettingsScreen(),
                  ),
                );
              },
            ),

            // Language option.
            // Currently only prints a message to the console.
            drawerTile(
              icon: Icons.language,
              title: 'Language',
              onTap: () {
                debugPrint('Language tapped');
              },
            ),

            // Pushes the connection indicator to the bottom.
            const Spacer(),

            // Visual Liquid Galaxy connection indicator.
            Container(
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),

              child: const Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: Colors.red,
                    size: 14,
                  ),

                  SizedBox(width: 10),

                  Text(
                    'LG disconnected',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
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

  // Creates a reusable drawer menu option.
  Widget drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),

      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),

        child: ListTile(
          leading: Icon(icon, color: Colors.brown),

          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          trailing: const Icon(
            Icons.chevron_right,
            size: 20,
          ),

          onTap: onTap,
        ),
      ),
    );
  }
}