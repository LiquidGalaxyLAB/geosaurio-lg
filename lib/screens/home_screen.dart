import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/dinosaur_mini_map.dart';
import '../models/dinosaur.dart';
import '../services/dinosaur_service.dart';
import '../services/lg_service.dart';
import '../widgets/drawer_menu.dart';
import 'dinosaur_detail_screen.dart';
import 'lg_settings_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DinosaurPeriod selectedPeriod =
      DinosaurPeriod.jurassic; //Stores the user selection: period, continent...

  String? selectedContinent;
  String? selectedCountry;
  String? selectedDinosaur;

  bool isLoadingDinosaurs = true;

  List<Dinosaur> dinosaurs = [];

  final TextEditingController searchController = TextEditingController();

  //Loads all the dinosaurs data when the screen starts
  @override
  void initState() {
    super.initState();
    loadDinosaurData();
  }

  Future<void> loadDinosaurData() async {
    //loads the dinosaurs from the csv
    final data = await DinosaurService.loadDinosaurs();

    if (!mounted) return;

    setState(() {
      dinosaurs = data;
      isLoadingDinosaurs = false;
    });
  }

  @override
  void dispose() {
    //dispose the search controller
    searchController.dispose();
    super.dispose();
  }

  List<String> get availableContinents {
    //Gets the available continents for the selected geological period
    final list = dinosaurs
        .where((dinosaur) => dinosaur.period == selectedPeriod)
        .map((dinosaur) => dinosaur.area)
        .where((area) => area.isNotEmpty)
        .toSet()
        .toList();

    list.sort();
    return list;
  }

  List<String> get availableCountries {
    if (selectedContinent == null) return [];

    final list = dinosaurs
        .where(
          (dinosaur) =>
              dinosaur.period == selectedPeriod &&
              dinosaur.area == selectedContinent,
        )
        .map((dinosaur) => dinosaur.country)
        .where((country) => country.isNotEmpty)
        .toSet()
        .toList();

    list.sort();
    return list;
  }

  List<Dinosaur> get availableDinosaurs {
    if (selectedContinent == null || selectedCountry == null) return [];

    final list = dinosaurs.where((dinosaur) {
      return dinosaur.period == selectedPeriod &&
          dinosaur.area == selectedContinent &&
          dinosaur.country == selectedCountry;
    }).toList();

    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  String getPeriodName(DinosaurPeriod period) {
    switch (period) {
      case DinosaurPeriod.triassic:
        return 'Triassic';
      case DinosaurPeriod.jurassic:
        return 'Jurassic';
      case DinosaurPeriod.cretaceous:
        return 'Cretaceous';
      case DinosaurPeriod.unknown:
        return 'Unknown';
    }
  }

  Future<void> selectPeriod(DinosaurPeriod period) async {
    setState(() {
      selectedPeriod = period;
      selectedContinent = null;
      selectedCountry = null;
      selectedDinosaur = null;
      searchController.clear();
    });

    final lgService = context.read<LgService>();

    if (!lgService.isConnected) {
      return;
    }

    await lgService.cleanDinosaurMarkers();
  }

  Future<void> selectContinent(String continent) async {
    setState(() {
      selectedContinent = continent;
      selectedCountry = null;
      selectedDinosaur = null;
      searchController.clear();
    });

    final lgService = context.read<LgService>();

    if (!lgService.isConnected) {
      return;
    }

    await lgService.cleanDinosaurMarkers();

    await lgService.flyToContinent(continent);
  }

  Future<void> selectCountry(String country) async {
    setState(() {
      selectedCountry = country;
      selectedDinosaur = null;
      searchController.clear();
    });

    final lgService = context.read<LgService>();

    if (!lgService.isConnected) {
      return;
    }

    /*
   Clean markers before dinosaur selection
   */
    await lgService.cleanDinosaurSelectionMarkers();

    /*
   * Mover Google Earth al país
   * y mostrar la columna informativa.
   */
    if (selectedContinent != null) {
      await lgService.flyToCountry(
        country,
        selectedContinent!,
        availableDinosaurs,
      );
    }

    /*
   * Show all avaible countries
   */
    await lgService.showDinosaurSelectionMarkers(availableDinosaurs);
  }

  Future<void> selectDinosaur(Dinosaur dinosaur) async {
    setState(() {
      selectedDinosaur = dinosaur.name;
    });

    final lgService = context.read<LgService>();

    if (lgService.isConnected) {
      debugPrint(
        'Selected dinosaur: ${dinosaur.name} | '
        'Latitude: ${dinosaur.latitude} | '
        'Longitude: ${dinosaur.longitude}',
      );

      /*
     * Clean markers before going to the dinosaur
     */
      await lgService.cleanDinosaurSelectionMarkers();

      /*
     * Fly to dinosaur
     */
      final bool flyOk = await lgService.flyToDinosaur(dinosaur);

      debugPrint(
        flyOk
            ? 'FlyTo completed for ${dinosaur.name}'
            : 'FlyTo failed for ${dinosaur.name}',
      );

      if (flyOk) {
        /*
       * We wait a little before the camera moves
       */
        await Future.delayed(const Duration(milliseconds: 800));

        /*
       * Show cube
       */
        final bool cubeOk = await lgService.showSelectedDinosaurCube(dinosaur);

        debugPrint(
          cubeOk
              ? 'Cube displayed for ${dinosaur.name}'
              : 'Cube could not be displayed for ${dinosaur.name}',
        );

        /*
       * EWe wait before showing the column
       */
        await Future.delayed(const Duration(milliseconds: 500));

        /*
       * Show about
       */
        await lgService.showDinosaurAboutColumn(dinosaur);
      }
    } else {
      debugPrint('Liquid Galaxy is not connected');
    }

    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (detailContext) {
          return DinosaurDetailScreen(
            dinosaur: dinosaur,

            onBackToDinosaurSelection: () async {
              final lgService = context.read<LgService>();

              /*
             * Guardamos la selección actual
             * antes de hacer cambios.
             */
              final String? country = selectedCountry;

              final String? continent = selectedContinent;

              final List<Dinosaur> countryDinosaurs = List<Dinosaur>.from(
                availableDinosaurs,
              );

              /*
             * Stop orbit
             */
              await lgService.stopDinosaurOrbit();

              /*
             * Clean dinosaur markers (cube, about)
             */
              await lgService.cleanDinosaurMarkers();

              await lgService.cleanRightScreenKml();

              /*
             * Go back to country section
             */
              if (country != null && continent != null) {
                await lgService.flyToCountry(
                  country,
                  continent,
                  countryDinosaurs,
                );

                /*
               * We show the markers again
               */
                await lgService.showDinosaurSelectionMarkers(countryDinosaurs);
              }

              /*
             * Restore logo
             */
              await lgService.sendLogo();
            },
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      selectedDinosaur = null;
    });
  }

  Future<void> goBackToContinents() async {
    setState(() {
      selectedContinent = null;
      selectedCountry = null;
      selectedDinosaur = null;
      searchController.clear();
    });

    final lgService = context.read<LgService>();

    if (!lgService.isConnected) {
      return;
    }

    await lgService.cleanDinosaurSelectionMarkers();

    await lgService.cleanDinosaurMarkers();

    /*
   * Clean right column
   */
    await lgService.cleanRightScreenKml();
  }

  Future<void> goBackToCountries() async {
    /*
   * Save continent before erasing the country selection
   */
    final String? continent = selectedContinent;

    setState(() {
      selectedCountry = null;
      selectedDinosaur = null;
      searchController.clear();
    });

    final lgService = context.read<LgService>();

    if (!lgService.isConnected) {
      return;
    }

    /*
   * Remove markers
   */
    await lgService.cleanDinosaurSelectionMarkers();

    await lgService.cleanDinosaurMarkers();

    /*
   *Go back to continents
   */
    if (continent != null) {
      await lgService.flyToContinent(continent);
    }
  }

  List<String> filteredContinents() {
    //filters the continents using the search bar
    final query = searchController.text.toLowerCase();

    if (query.isEmpty) return availableContinents;

    return availableContinents.where((continent) {
      return continent.toLowerCase().contains(query);
    }).toList();
  }

  List<String> filteredCountries() {
    final query = searchController.text.toLowerCase();

    if (query.isEmpty) return availableCountries;

    return availableCountries.where((country) {
      return country.toLowerCase().contains(query);
    }).toList();
  }

  List<Dinosaur> filteredDinosaurs() {
    final query = searchController.text.toLowerCase();

    if (query.isEmpty) return availableDinosaurs;

    return availableDinosaurs.where((dinosaur) {
      return dinosaur.name.toLowerCase().contains(query) ||
          dinosaur.region.toLowerCase().contains(query);
    }).toList();
  }

  String get breadcrumbTitle {
    //Builds the current navigation path
    final parts = [
      getPeriodName(selectedPeriod),
      if (selectedContinent != null) selectedContinent!,
      if (selectedCountry != null) selectedCountry!,
      if (selectedDinosaur != null) selectedDinosaur!,
    ];

    return parts.join(' ↓ ');
  }

  @override
  Widget build(BuildContext context) {
    //Creates visual interface
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: AppDrawer(isLgConnected: context.watch<LgService>().isConnected),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  buildTopBar(context),
                  const SizedBox(height: 18),
                  if (isLoadingDinosaurs)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    Text(
                      breadcrumbTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    buildPeriodSelector(),
                    const SizedBox(height: 24),
                    if (selectedContinent == null)
                      buildContinentSelector()
                    else if (selectedCountry == null)
                      buildCountrySelector()
                    else
                      buildDinosaurSelector(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildTopBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isConnected = context.watch<LgService>().isConnected;

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            icon: const Icon(Icons.menu, size: 30),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),

        const Spacer(),

        const Text(
          'GeoSaurio',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const Spacer(),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                size: 12,
                color: isConnected ? Colors.green : Colors.red,
              ),

              const SizedBox(width: 8),

              Text(
                isConnected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildPeriodSelector() {
    return Row(
      children: [
        Expanded(child: periodButton(DinosaurPeriod.triassic)),
        const SizedBox(width: 8),
        Expanded(child: periodButton(DinosaurPeriod.jurassic)),
        const SizedBox(width: 8),
        Expanded(child: periodButton(DinosaurPeriod.cretaceous)),
      ],
    );
  }

  Widget buildContinentSelector() {
    final visibleContinents = filteredContinents();

    return Expanded(
      child: Column(
        children: [
          const Text(
            'Select a continent',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          searchBox(hintText: 'Search continent...'),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: cardDecoration(),
              child: visibleContinents.isEmpty
                  ? emptyMessage(
                      icon: Icons.public_off,
                      text: 'No continents available\nfor this period',
                    )
                  : Scrollbar(
                      thumbVisibility: true,
                      child: ListView.separated(
                        itemCount: visibleContinents.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final continent = visibleContinents[index];

                          final count = dinosaurs.where((dinosaur) {
                            return dinosaur.period == selectedPeriod &&
                                dinosaur.area == continent;
                          }).length;

                          return niceListTile(
                            title: continent,
                            subtitle: '$count dinosaurs',
                            icon: Icons.public,
                            onTap: () => selectContinent(continent),
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

  Widget buildCountrySelector() {
    final visibleCountries = filteredCountries();

    return Expanded(
      child: Column(
        children: [
          const Text(
            'Select a country',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          searchBox(hintText: 'Search country...'),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: cardDecoration(),
              child: visibleCountries.isEmpty
                  ? emptyMessage(
                      icon: Icons.flag,
                      text: 'No countries available\nfor this continent',
                    )
                  : Scrollbar(
                      thumbVisibility: true,
                      child: ListView.separated(
                        itemCount: visibleCountries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final country = visibleCountries[index];

                          final count = dinosaurs.where((dinosaur) {
                            //count the dinosaurs so it's showed as a subtitle
                            return dinosaur.period == selectedPeriod &&
                                dinosaur.area == selectedContinent &&
                                dinosaur.country == country;
                          }).length;

                          return niceListTile(
                            title: country,
                            subtitle: '$count dinosaurs',
                            icon: Icons.flag,
                            onTap: () => selectCountry(country),
                          );
                        },
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: goBackToContinents,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to continents'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget buildDinosaurSelector() {
    final visibleDinosaurs = filteredDinosaurs();

    return Expanded(
      child: Column(
        children: [
          const Text(
            'Select a dinosaur',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          searchBox(hintText: 'Search dinosaur...'),
          const SizedBox(height: 12),
          DinosaurMiniMap(
            dinosaurs: visibleDinosaurs,
            onDinosaurSelected: (dinosaur) {
              selectDinosaur(dinosaur);
            },
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: cardDecoration(),
              child: visibleDinosaurs.isEmpty
                  ? emptyMessage(
                      icon: Icons.search_off,
                      text: 'No dinosaurs found\nfor this country',
                    )
                  : Scrollbar(
                      thumbVisibility: true,
                      child: ListView.separated(
                        itemCount: visibleDinosaurs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final dinosaur = visibleDinosaurs[index];

                          return niceListTile(
                            title: dinosaur.name,
                            subtitle: dinosaur.region,
                            icon: Icons.pets,
                            onTap: () => selectDinosaur(dinosaur),
                          );
                        },
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
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

  Widget searchBox({required String hintText}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (_) => setState(() {}),

        style: TextStyle(color: colorScheme.onSurface),

        decoration: InputDecoration(
          hintText: hintText,

          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),

          border: InputBorder.none,

          prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          suffixIcon: searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
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

  Widget niceListTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: subtitle == null || subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget emptyMessage({required IconData icon, required String text}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 55, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
    );
  }

  Widget periodButton(DinosaurPeriod period) {
    final bool isSelected = selectedPeriod == period;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => selectPeriod(period),
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Text(
          getPeriodName(period),
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
