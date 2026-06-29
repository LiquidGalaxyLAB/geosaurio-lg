import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dinosaur.dart';
import '../services/dinosaur_service.dart';
import '../services/lg_service.dart';

import 'dinosaur_detail_screen.dart';
import 'lg_settings_screen.dart';
import 'about_screen.dart';
import '../widgets/dinosaur_mini_map.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DinosaurPeriod selectedPeriod = DinosaurPeriod.jurassic;

  String? selectedContinent;
  String? selectedCountry;
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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<String> get availableContinents {
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

  List<Dinosaur> get dinosaursInSelectedContinent {
    if (selectedContinent == null) return [];

    return dinosaurs.where((dinosaur) {
      return dinosaur.period == selectedPeriod &&
          dinosaur.area == selectedContinent;
    }).toList();
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
  }

  Future<void> selectContinent(String continent) async {
    setState(() {
      selectedContinent = continent;
      selectedCountry = null;
      selectedDinosaur = null;
      searchController.clear();
    });

    final lgService = context.read<LgService>();

    if (!lgService.isConnected) return;

    await lgService.flyToContinent(continent);
    await lgService.showCountryMarkers(dinosaursInSelectedContinent);
  }

  Future<void> selectCountry(String country) async {
    setState(() {
      selectedCountry = country;
      selectedDinosaur = null;
      searchController.clear();
    });

    final lgService = context.read<LgService>();

    if (!lgService.isConnected) return;

    final countryDinosaurs = availableDinosaurs;

    await lgService.showDinosaurMarkers(countryDinosaurs);
    await Future.delayed(const Duration(milliseconds: 700));
    await lgService.flyToCountry(country, countryDinosaurs);
  }

  Future<void> selectDinosaur(Dinosaur dinosaur) async {
    setState(() {
      selectedDinosaur = dinosaur.name;
    });

    final lgService = context.read<LgService>();

    if (lgService.isConnected) {
      final flyOk = await lgService.flyToDinosaur(dinosaur);

      if (flyOk) {
        await lgService.showDinosaurAboutKml(dinosaur);
      }
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DinosaurDetailScreen(dinosaur: dinosaur),
      ),
    );

    if (!mounted) return;

    if (lgService.isConnected && selectedContinent != null) {
      await lgService.flyToContinent(selectedContinent!);
      await lgService.showCountryMarkers(dinosaursInSelectedContinent);
    }
  }

  void goBackToContinents() {
    setState(() {
      selectedContinent = null;
      selectedCountry = null;
      selectedDinosaur = null;
      searchController.clear();
    });

    final lgService = context.read<LgService>();

    if (lgService.isConnected) {
      lgService.flyToEarth();
    }
  }

  void goBackToCountries() {
    setState(() {
      selectedCountry = null;
      selectedDinosaur = null;
      searchController.clear();
    });
  }

  List<String> filteredContinents() {
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
    return [
      getPeriodName(selectedPeriod),
      selectedContinent,
      selectedCountry,
      selectedDinosaur,
    ].whereType<String>().join(' ↓ ');
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
        subtitle: subtitle == null || subtitle.isEmpty ? null : Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget emptyMessage({required IconData icon, required String text}) {
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

  Widget periodButton(DinosaurPeriod period) {
    final bool isSelected = selectedPeriod == period;

    return GestureDetector(
      onTap: () => selectPeriod(period),
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
