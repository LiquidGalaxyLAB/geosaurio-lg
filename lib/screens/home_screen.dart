import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dinosaur.dart';
import '../services/dinosaur_service.dart';
import '../services/lg_service.dart';

import 'dinosaur_detail_screen.dart';
import 'lg_settings_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DinosaurPeriod selectedPeriod = DinosaurPeriod.jurassic;

  String? selectedContinent;
  String? selectedDinosaur;

  bool isLoadingDinosaurs = true;

  List<Dinosaur> dinosaurs = [];

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDinosaurData();
  }

  Future<void> loadDinosaurData() async {
    final data = await DinosaurService.loadDinosaurs();

    if (!mounted) return;

    setState(() {
      dinosaurs = data;
      isLoadingDinosaurs = false;
    });
  }

<<<<<<< Updated upstream
=======
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Map<String, List<String>> get countriesByContinent {
    return DinosaurService.buildCountriesByContinent(dinosaurs, selectedPeriod);
  }

  Map<String, Map<String, List<String>>> get regionsByCountry {
    return DinosaurService.buildRegionsByCountry(dinosaurs, selectedPeriod);
  }

>>>>>>> Stashed changes
  List<String> get continents {
    final list = dinosaurs
        .where((dinosaur) => dinosaur.period == selectedPeriod)
        .map((dinosaur) => dinosaur.area)
        .where((area) => area.isNotEmpty)
        .toSet()
        .toList();

    list.sort();
    return list;
  }

<<<<<<< Updated upstream
  List<Dinosaur> get dinosaursBySelectedContinent {
    if (selectedContinent == null) return [];

    final filtered = dinosaurs.where((dinosaur) {
      return dinosaur.period == selectedPeriod &&
          dinosaur.area == selectedContinent;
    }).toList();

    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
=======
  List<Dinosaur> get dinosaursInSelectedContinent {
    if (selectedContinent == null) return [];

    return dinosaurs.where((dinosaur) {
      return dinosaur.period == selectedPeriod &&
          dinosaur.area == selectedContinent;
    }).toList();
  }

  List<Dinosaur> get dinosaursInSelectedCountry {
    if (selectedContinent == null || selectedCountry == null) return [];

    return dinosaurs.where((dinosaur) {
      return dinosaur.period == selectedPeriod &&
          dinosaur.area == selectedContinent &&
          dinosaur.country == selectedCountry;
    }).toList();
>>>>>>> Stashed changes
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

  List<String> filteredContinents() {
    final query = searchController.text.toLowerCase();

    if (query.isEmpty) return continents;

    return continents.where((continent) {
      return continent.toLowerCase().contains(query);
    }).toList();
  }

  List<Dinosaur> filteredDinosaurs() {
    final query = searchController.text.toLowerCase();

    if (query.isEmpty) return dinosaursBySelectedContinent;

    return dinosaursBySelectedContinent.where((dinosaur) {
      return dinosaur.name.toLowerCase().contains(query) ||
          dinosaur.country.toLowerCase().contains(query) ||
          dinosaur.region.toLowerCase().contains(query);
    }).toList();
  }

<<<<<<< Updated upstream
  Future<void> selectContinent(String continent) async {
    final lgService = context.read<LgService>();

    if (lgService.isConnected) {
      await lgService.flyToContinent(continent);
    }

    if (!mounted) return;

=======
  Future<void> selectPeriod(DinosaurPeriod period) async {
    setState(() {
      selectedPeriod = period;
      selectedContinent = null;
      selectedCountry = null;
      expandedRegion = null;
      selectedDinosaur = null;
      searchController.clear();
    });
  }

  Future<void> selectContinent(String? continent) async {
    if (continent == null) return;

    setState(() {
      selectedContinent = continent;
      selectedCountry = null;
      expandedRegion = null;
      selectedDinosaur = null;
      searchController.clear();
    });

    final lgService = context.read<LgService>();

    if (!lgService.isConnected) return;

    final continentDinosaurs = dinosaursInSelectedContinent;

    final flyOk = await lgService.flyToContinent(continent);
    await lgService.showCountryMarkers(continentDinosaurs);

    if (!mounted) return;

    showLgSnackBar(
      flyOk
          ? 'Flying to $continent and showing countries'
          : 'Could not fly to $continent',
      flyOk,
    );
  }

  Future<void> selectCountry(String country) async {
>>>>>>> Stashed changes
    setState(() {
      selectedContinent = continent;
      selectedDinosaur = null;
      searchController.clear();
    });

    final lgService = context.read<LgService>();

    if (!lgService.isConnected) return;

    final countryDinosaurs = dinosaursInSelectedCountry;

    final flyOk = await lgService.flyToCountry(country, countryDinosaurs);
    await lgService.showDinosaurMarkers(countryDinosaurs);

    if (!mounted) return;

    showLgSnackBar(
      flyOk
          ? 'Flying to $country and showing dinosaur markers'
          : 'Could not fly to $country',
      flyOk,
    );
  }

  void goBackToContinents() {
    setState(() {
      selectedContinent = null;
      selectedDinosaur = null;
      searchController.clear();
    });
  }

  void showLgSnackBar(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> openDinosaurAbout(Dinosaur dinosaur) async {
    final lgService = context.read<LgService>();

    if (lgService.isConnected) {
      final flyOk = await lgService.flyToDinosaur(dinosaur);

      if (flyOk) {
        await lgService.showDinosaurAboutKml(
          dinosaur,
          allDinosaurs: dinosaurs,
        );
      }

      if (!mounted) return;

      showLgSnackBar(
        flyOk
            ? 'Flying to ${selectedDino.name} and showing information'
            : 'Could not fly to ${selectedDino.name}',
        flyOk,
      );
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DinosaurDetailScreen(dinosaur: dinosaur),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  buildTopBar(context),
                  const SizedBox(height: 18),
                  if (isLoadingDinosaurs)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    Text(
<<<<<<< Updated upstream
                      selectedContinent ?? 'Select geological period',
=======
                      buildHeaderTitle(),
>>>>>>> Stashed changes
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    buildPeriodSelector(),
                    const SizedBox(height: 24),
<<<<<<< Updated upstream
                    if (selectedContinent == null)
                      buildContinentSelector()
=======
                    if (selectedCountry == null)
                      buildContinentAndCountrySelector(countries)
>>>>>>> Stashed changes
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

  String buildHeaderTitle() {
    if (selectedCountry != null) return selectedCountry!;
    if (selectedContinent != null) return selectedContinent!;
    return 'Select geological period';
  }

  Widget buildTopBar(BuildContext context) {
    return Row(
      children: [
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
        const Text(
          'GeoSaurio',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        const SizedBox(width: 48),
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

<<<<<<< Updated upstream
  Widget buildContinentSelector() {
    final visibleContinents = filteredContinents();
=======
  Widget buildContinentAndCountrySelector(List<String> countries) {
    final visibleCountries = filteredCountries(countries);
>>>>>>> Stashed changes

    return Expanded(
      child: Column(
        children: [
          const Text(
            'Explore by continent and country',
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
<<<<<<< Updated upstream
                icon: Icons.public_off,
                text: 'No continents available\nfor this period',
=======
                icon: Icons.public,
                text: 'Select a continent\nto see available countries',
              )
                  : visibleCountries.isEmpty
                  ? emptyMessage(
                icon: Icons.search_off,
                text: 'No countries found',
>>>>>>> Stashed changes
              )
                  : Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  itemCount: visibleContinents.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final continent = visibleContinents[index];

                    return niceListTile(
                      title: continent,
                      subtitle:
                      '${dinosaurs.where((d) => d.period == selectedPeriod && d.area == continent).length} dinosaurs',
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

  Widget buildDinosaurSelector() {
    final visibleDinosaurs = filteredDinosaurs();

    return Expanded(
      child: Column(
        children: [
          searchBox(hintText: 'Search dinosaurs, countries or regions...'),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: cardDecoration(),
              child: visibleDinosaurs.isEmpty
                  ? emptyMessage(
                icon: Icons.search_off,
                text: 'No dinosaurs found\nfor this continent',
              )
                  : Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  itemCount: visibleDinosaurs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final dinosaur = visibleDinosaurs[index];
                    final isSelected =
                        selectedDinosaur == dinosaur.name;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.pets,
                              color: Colors.brown,
                            ),
                            title: Text(
                              dinosaur.name,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${dinosaur.country} • ${dinosaur.region}',
                            ),
                            trailing: Icon(
                              isSelected
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                            ),
                            onTap: () {
                              setState(() {
<<<<<<< Updated upstream
                                selectedDinosaur =
                                isSelected ? null : dinosaur.name;
=======
                                expandedRegion =
                                isExpanded ? null : regionName;
                                selectedDinosaur = null;
>>>>>>> Stashed changes
                              });
                            },
                          ),
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 14,
                                left: 12,
                                right: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
<<<<<<< Updated upstream
                                  lgActionButton(
                                    icon: Icons.rotate_right,
                                    text: 'Rotate',
                                    onTap: showLgMessage,
                                  ),
                                  const SizedBox(width: 12),
                                  lgActionButton(
                                    icon: Icons.info,
                                    text: 'About',
                                    onTap: () =>
                                        openDinosaurAbout(dinosaur),
                                  ),
=======
                                  ListTile(
                                    title: Text(
                                      dinosaur,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        selectedDinosaur = dinosaur;
                                      });

                                      openDinosaurAbout(dinosaur);
                                    },
                                  ),
                                  if (isSelected)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: lgActionButton(
                                        icon: Icons.info,
                                        text: 'About',
                                        onTap: () =>
                                            openDinosaurAbout(dinosaur),
                                      ),
                                    ),
>>>>>>> Stashed changes
                                ],
                              ),
                            ),
                        ],
                      ),
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

  Widget searchBox({required String hintText}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search),
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

<<<<<<< Updated upstream
=======
  Widget continentDropdown() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedContinent,
          isExpanded: true,
          hint: const Text(
            'Select Continent',
            style: TextStyle(fontSize: 17, color: Colors.black),
          ),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: continents.map((continent) {
            return DropdownMenuItem(
              value: continent,
              child: Text(continent),
            );
          }).toList(),
          onChanged: selectContinent,
        ),
      ),
    );
  }

>>>>>>> Stashed changes
  Widget niceListTile({
    required String title,
    String? subtitle,
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
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

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

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFE8E1D8),
      borderRadius: BorderRadius.circular(20),
    );
  }

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

  Widget periodButton(DinosaurPeriod period) {
    final bool isSelected = selectedPeriod == period;

    return GestureDetector(
<<<<<<< Updated upstream
      onTap: () {
        setState(() {
          selectedPeriod = period;
          selectedContinent = null;
          selectedDinosaur = null;
          searchController.clear();
        });
      },
=======
      onTap: () => selectPeriod(period),
>>>>>>> Stashed changes
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3E2A1F) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black12),
        ),
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

  Widget buildDrawer() {
    final lgService = context.watch<LgService>();

    return Drawer(
      backgroundColor: const Color(0xFFF7F4EF),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            const CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFF3E2A1F),
              child: Icon(Icons.public, size: 42, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'GeoSaurio',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const Text(
              'For Liquid Galaxy',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 22),
            drawerTile(
              icon: Icons.home,
              title: 'Main Menu',
              onTap: () => Navigator.pop(context),
            ),
            drawerTile(
              icon: Icons.info,
              title: 'Information',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
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
            drawerTile(
              icon: Icons.language,
              title: 'Language',
              onTap: () {
                debugPrint('Language tapped');
              },
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: lgService.isConnected ? Colors.green : Colors.red,
                    size: 14,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    lgService.isConnected ? 'LG connected' : 'LG disconnected',
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