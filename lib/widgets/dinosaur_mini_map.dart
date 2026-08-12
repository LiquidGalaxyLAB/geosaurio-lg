import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/dinosaur.dart';
import '../services/lg_service.dart';

class DinosaurMiniMap extends StatefulWidget { // Dinosaurs shown on the mini map
  final List<Dinosaur> dinosaurs;
  final void Function(Dinosaur dinosaur) onDinosaurSelected; // Called when the user selects a dinosaur marker

  const DinosaurMiniMap({
    super.key,
    required this.dinosaurs,
    required this.onDinosaurSelected,
  });

  @override
  State<DinosaurMiniMap> createState() => _DinosaurMiniMapState();
}

class _DinosaurMiniMapState extends State<DinosaurMiniMap> { // Timer used to avoid sending too many movements to Liquid Galaxy
  Timer? _syncTimer;

  void _synchronizeWithLiquidGalaxy(MapCamera camera) {   // Synchronize the mini map camera with Liquid Galaxy
    // Cancel the previous pending synchronization.
    _syncTimer?.cancel();

    // Wait until the user has practically stopped moving the map.
    _syncTimer = Timer(
      const Duration(milliseconds: 500),
          () async {
        if (!mounted) return;

        final lgService = context.read<LgService>();

        if (!lgService.isConnected) return;

        await lgService.flyToMapPosition(
          latitude: camera.center.latitude,
          longitude: camera.center.longitude,
          zoom: camera.zoom,
          bearing: camera.rotation,
        );
      },
    );
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final validDinosaurs = widget.dinosaurs.where((dinosaur) {
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
        child: const Text(
          'No coordinates available',
        ),
      );
    }

    // Initial position of the minimap.
    final firstCoords =
    validDinosaurs.first.getMarkerCoordinates();

    final center = LatLng(
      firstCoords['latitude']!,
      firstCoords['longitude']!,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 4,

            // Called whenever the map position changes.
            onPositionChanged: (camera, hasGesture) {
              // Only synchronize when the user moves the map.
              if (!hasGesture) return;

              _synchronizeWithLiquidGalaxy(camera);
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName:
              'com.example.geosaurio',
            ),

            MarkerLayer(
              markers: validDinosaurs.map((dinosaur) {
                final coords =
                dinosaur.getMarkerCoordinates();

                return Marker(
                  point: LatLng(
                    coords['latitude']!,
                    coords['longitude']!,
                  ),
                  width: 45,
                  height: 45,
                  child: GestureDetector(
                    onTap: () {
                      widget.onDinosaurSelected(
                        dinosaur,
                      );
                    },
                    child: Image.asset(
                      'assets/images/markers/dino_marker.png',
                      errorBuilder: (
                          context,
                          error,
                          stackTrace,
                          ) {
                        return const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 38,
                        );
                      },
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