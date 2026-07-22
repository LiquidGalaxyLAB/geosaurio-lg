import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/dinosaur.dart';
import '../services/lg_service.dart';

class DinosaurMiniMap extends StatefulWidget {
  final List<Dinosaur> dinosaurs;
  final void Function(Dinosaur dinosaur) onDinosaurSelected;

  const DinosaurMiniMap({
    super.key,
    required this.dinosaurs,
    required this.onDinosaurSelected,
  });

  @override
  State<DinosaurMiniMap> createState() => _DinosaurMiniMapState();
}

class _DinosaurMiniMapState extends State<DinosaurMiniMap> {
  Timer? _syncTimer;

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  void _synchronizeWithLiquidGalaxy(MapCamera camera) {
    _syncTimer?.cancel();

    _syncTimer = Timer(
      const Duration(milliseconds: 200),
          () async {
        if (!mounted) return;

        final lgService = context.read<LgService>();

        if (!lgService.isConnected) {
          debugPrint('Map not synchronized: LG disconnected');
          return;
        }

        debugPrint(
          'Map gesture finished: '
              'lat=${camera.center.latitude}, '
              'lon=${camera.center.longitude}, '
              'zoom=${camera.zoom}',
        );

        final ok = await lgService.flyToMapPosition(
          latitude: camera.center.latitude,
          longitude: camera.center.longitude,
          zoom: camera.zoom,
          bearing: camera.rotation,
        );

        debugPrint(
          ok
              ? 'Map synchronized with Liquid Galaxy'
              : 'Could not synchronize map with Liquid Galaxy',
        );
      },
    );
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
        child: const Text('No coordinates available'),
      );
    }

    final firstCoords = validDinosaurs.first.getMarkerCoordinates();

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
            onMapEvent: (event) {
              final shouldSynchronize =
                  event is MapEventMoveEnd ||
                      event is MapEventFlingAnimationEnd ||
                      event is MapEventDoubleTapZoomEnd ||
                      event is MapEventScrollWheelZoom;

              if (!shouldSynchronize) return;

              _synchronizeWithLiquidGalaxy(event.camera);
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.geosaurio',
            ),
            MarkerLayer(
              markers: validDinosaurs.map((dinosaur) {
                final coords = dinosaur.getMarkerCoordinates();

                return Marker(
                  point: LatLng(
                    coords['latitude']!,
                    coords['longitude']!,
                  ),
                  width: 45,
                  height: 45,
                  child: GestureDetector(
                    onTap: () => widget.onDinosaurSelected(dinosaur),
                    child: Image.asset(
                      'assets/images/markers/dino_marker.png',
                      errorBuilder: (context, error, stackTrace) {
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