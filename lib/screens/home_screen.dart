import 'package:flutter/material.dart';

import '../models/dinosaur.dart';
import '../services/dinosaur_service.dart';

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
  String? selectedCountry;
  String? expandedRegion;
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

  Map<String, List<String>> get countriesByContinent {
    return DinosaurService.buildCountriesByContinent(
      dinosaurs,
      selectedPeriod,
    );
  }

  Map<String, Map<String, List<String>>> get regionsByCountry {
    return DinosaurService.buildRegionsByCountry(
      dinosaurs,
      selectedPeriod,
    );
  }

  List<String> get continents {
    final list = countriesByContinent.keys.toList();
    list.sort();
    return list;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

  Dinosaur getDinosaurByName(String name) {
    return dinosaurs.firstWhere(
          (dinosaur) => dinosaur.name == name,
    );
  }

  List<String> filteredCountries(List<String> countries) {
    final query = searchController.text.toLowerCase();

    if (query.isEmpty) return countries;

    return countries.where((country) {
      return country.toLowerCase().contains(query);
    }).toList();
  }

  Map<String, List<String>> filteredRegions(
      Map<String, List<String>> regions,
      ) {
    final query = searchController.text.toLowerCase();

    if (query.isEmpty) return regions;

    return Map.fromEntries(
      regions.entries.where((entry) {
        final region = entry.key.toLowerCase();
        final dinosaurNames = entry.value.join(' ').toLowerCase();

        return region.contains(query) || dinosaurNames.contains(query);
      }),
    );
  }

  void selectCountry(String country) {
    setState(() {
      selectedCountry = country;
      expandedRegion = null;
      selectedDinosaur = null;
      searchController.clear();
    });
  }

  void goBackToCountries() {
    setState(() {
      selectedCountry = null;
      expandedRegion = null;
      selectedDinosaur = null;
      searchController.clear();
    });
  }

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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> countries = selectedContinent == null
        ? []
        : countriesByContinent[selectedContinent] ?? [];

    final Map<String, List<String>> regions = selectedCountry == null
        ? {}
        : regionsByCountry[selectedCountry] ?? {};

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
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    Text(
                      selectedCountry ?? 'Select geological period',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    buildPeriodSelector(),
                    const SizedBox(height: 24),
                    if (selectedCountry == null)
                      buildContinentSelector(countries)
                    else
                      buildRegionSelector(regions),
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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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

  Widget buildContinentSelector(List<String> countries) {
    final visibleCountries = filteredCountries(countries);

    return Expanded(
      child: Column(
        children: [
          const Text(
            'Select a continent to explore',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          searchBox(
            hintText: selectedContinent == null
                ? 'Search continent...'
                : 'Search country...',
          ),
          const SizedBox(height: 16),
          continentDropdown(),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: cardDecoration(),
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

  Widget buildRegionSelector(
      Map<String, List<String>> regions,
      ) {
    final visibleRegions = filteredRegions(regions);

    return Expanded(
      child: Column(
        children: [
          searchBox(hintText: 'Search regions or dinosaurs...'),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: cardDecoration(),
              child: visibleRegions.isEmpty
                  ? emptyMessage(
                icon: Icons.map_outlined,
                text: 'No regions available\nfor this country yet',
              )
                  : Scrollbar(
                thumbVisibility: true,
                child: ListView(
                  children: visibleRegions.entries.map((entry) {
                    final regionName = entry.key;
                    final dinosaursInRegion = entry.value;
                    final isExpanded = expandedRegion == regionName;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        children: [
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
                          if (isExpanded)
                            ...dinosaursInRegion.map((dinosaur) {
                              final isSelected =
                                  selectedDinosaur == dinosaur;

                              return Column(
                                children: [
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
                                  if (isSelected)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          lgActionButton(
                                            icon: Icons.rotate_right,
                                            text: 'Rotate',
                                            onTap: () {
                                              showLgMessage();
                                            },
                                          ),
                                          const SizedBox(width: 12),
                                          lgActionButton(
                                            icon: Icons.info,
                                            text: 'About',
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      DinosaurDetailScreen(
                                                        dinosaur: getDinosaurByName(dinosaur),
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
            style: TextStyle(
              fontSize: 17,
              color: Colors.black,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down),
          items: continents.map((continent) {
            return DropdownMenuItem(
              value: continent,
              child: Text(continent),
            );
          }).toList(),
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
      onTap: () {
        setState(() {
          selectedPeriod = period;
          selectedContinent = null;
          selectedCountry = null;
          expandedRegion = null;
          selectedDinosaur = null;
          searchController.clear();
        });
      },
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
    return Drawer(
      backgroundColor: const Color(0xFFF7F4EF),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
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
            const Text(
              'GeoSaurio',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
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
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  ),
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