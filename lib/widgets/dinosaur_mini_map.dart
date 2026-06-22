import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/dinosaur.dart';

class DinosaurMiniMap extends StatelessWidget {
  final List<Dinosaur> dinosaurs;
  final void Function(Dinosaur dinosaur) onDinosaurSelected;

  const DinosaurMiniMap({
    super.key,
    required this.dinosaurs,
    required this.onDinosaurSelected,
  });

  @override
  Widget build(BuildContext context) {
    final validDinosaurs = dinosaurs.where((dinosaur) {
      return dinosaur.latitude != 0 && dinosaur.longitude != 0;
    }).toList();

    if (validDinosaurs.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text('No coordinates available'),
      );
    }

    final center = LatLng(
      validDinosaurs.first.latitude,
      validDinosaurs.first.longitude,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 4,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.geosaurio',
            ),
            MarkerLayer(
              markers: validDinosaurs.map((dinosaur) {
                return Marker(
                  point: LatLng(dinosaur.latitude, dinosaur.longitude),
                  width: 42,
                  height: 42,
                  child: GestureDetector(
                    onTap: () => onDinosaurSelected(dinosaur),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 38,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}