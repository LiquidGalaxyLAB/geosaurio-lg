import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dinosaur.dart';
import '../services/audio_service.dart';
import '../services/lg_service.dart';

class DinosaurDetailScreen extends StatefulWidget {
  // Dinosaur selected by the user
  final Dinosaur dinosaur;

  // Function to return to the dinosaur selection
  final Future<void> Function() onBackToDinosaurSelection;

  const DinosaurDetailScreen({
    super.key,
    required this.dinosaur,
    required this.onBackToDinosaurSelection,
  });

  @override
  State<DinosaurDetailScreen> createState() =>
      _DinosaurDetailScreenState();
}

class _DinosaurDetailScreenState
    extends State<DinosaurDetailScreen> {

  // Controls the narration state
  bool isNarrationPlaying = false;

  // Avoid returning to the selection twice
  bool isReturningToSelection = false;

  // Get the selected dinosaur
  Dinosaur get dinosaur => widget.dinosaur;

  // Show success or error messages
  void showSnack(
      BuildContext context,
      String message, {
        bool success = true,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Return to the dinosaur selection
  Future<void> backToDinosaurSelection() async {

    // Avoid executing the action more than once
    if (isReturningToSelection) {
      return;
    }

    setState(() {
      isReturningToSelection = true;
    });

    // Stop the narration before leaving
    await AudioService().stop();

    if (!mounted) {
      return;
    }

    // Close the dinosaur detail screen
    Navigator.pop(context);

    // Return to the previous dinosaur selection
    widget.onBackToDinosaurSelection();
  }

  // Send dinosaur actions to Liquid Galaxy
  Future<void> sendToLg(
      BuildContext context,
      String action,
      ) async {

    // Get the main Liquid Galaxy service
    final lgService =
    context.read<LgService>();

    // Check that Liquid Galaxy is connected
    if (!lgService.isConnected) {
      showSnack(
        context,
        'Liquid Galaxy is not connected',
        success: false,
      );

      return;
    }

    bool ok = false;

    await lgService.stopDinosaurOrbit();

    /*
     * Recover the dinosaur's normal sight
     * before opening Chromium.
     */
    await lgService.flyToDinosaur(
      dinosaur,
    );

    /*
     * Comparison and Skeleton stop first
     * any active orbit.
     */

    if (action == 'Comparison') {
      ok =
      await lgService
          .showDinosaurComparisonImage(
        dinosaur,
      );
    } else if (action == 'Skeleton') {
      ok =
      await lgService
          .showDinosaurSkeletonImage(
        dinosaur,
      );
    }

    if (!context.mounted) {
      return;
    }

    showSnack(
      context,
      ok
          ? '$action sent to Liquid Galaxy'
          : 'Could not send $action to Liquid Galaxy',
      success: ok,
    );
  }

  Future<void> startNarration() async {
    if (isNarrationPlaying) {
      return;
    }

    setState(() {
      isNarrationPlaying = true;
    });

    try {
      await AudioService()
          .playDinosaurAudio(
        dinosaur.name,
      );

      if (!mounted) {
        return;
      }

      showSnack(
        context,
        'Narration started',
        success: true,
      );
    } catch (e) {
      debugPrint(
        'Error starting narration: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isNarrationPlaying = false;
      });

      showSnack(
        context,
        'Could not start narration',
        success: false,
      );
    }
  }

  Future<void> stopNarration() async {
    if (!isNarrationPlaying) {
      return;
    }

    setState(() {
      isNarrationPlaying = false;
    });

    await AudioService().stop();

    if (!mounted) {
      return;
    }

    showSnack(
      context,
      'Narration stopped',
      success: true,
    );
  }

  Future<void> returnToGoogleEarth() async {
    final lgService =
    context.read<LgService>();

    await lgService.stopDinosaurOrbit();

    final ok =
    await lgService
        .closeChromiumOnAllScreens();

    await AudioService().stop();

    if (!mounted) {
      return;
    }

    setState(() {
      isNarrationPlaying = false;
    });

    showSnack(
      context,
      ok
          ? 'Returned to Google Earth'
          : 'Could not close Chromium',
      success: ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lgService =
    context.watch<LgService>();

    final colorScheme =
        Theme.of(context).colorScheme;

    final cleanName =
    lgService.cleanDinosaurImageName(
      dinosaur.name,
    );

    return Scaffold(
      backgroundColor:
      Theme.of(context)
          .scaffoldBackgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Column(
            children: [
              const SizedBox(height: 4),

              Row(
                children: [
                  Container(
                    decoration:
                    BoxDecoration(
                      color: colorScheme
                          .surfaceContainerHighest,
                      borderRadius:
                      BorderRadius
                          .circular(
                        14,
                      ),
                    ),
                    child: IconButton(
                      tooltip:
                      'Back to dinosaur selection',
                      icon:
                      isReturningToSelection
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2.5,
                        ),
                      )
                          : const Icon(
                        Icons
                            .arrow_back,
                        size: 30,
                      ),
                      onPressed:
                      isReturningToSelection
                          ? null
                          : backToDinosaurSelection,
                    ),
                  ),

                  const Expanded(
                    child: Text(
                      'Dinosaur Information',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),
                  ),

                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration:
                    BoxDecoration(
                      color: colorScheme
                          .surfaceContainerHighest,
                      borderRadius:
                      BorderRadius
                          .circular(
                        20,
                      ),
                    ),
                    child: Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: lgService
                              .isConnected
                              ? Colors.green
                              : Colors.red,
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        Text(
                          lgService
                              .isConnected
                              ? 'Connected'
                              : 'Disconnected',
                          style: TextStyle(
                            fontWeight:
                            FontWeight
                                .w600,
                            color:
                            colorScheme
                                .onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.all(
                  20,
                ),
                decoration:
                cardDecoration(),
                child: Column(
                  children: [
                    Container(
                      height: 180,
                      width:
                      double.infinity,
                      decoration:
                      BoxDecoration(
                        color: colorScheme
                            .surfaceContainer,
                        borderRadius:
                        BorderRadius
                            .circular(
                          18,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius:
                        BorderRadius
                            .circular(
                          18,
                        ),
                        child:
                        FutureBuilder<
                            String?>(
                          future: lgService
                              .getExistingImagePath(
                            'assets/images/dinosaurs/'
                                '${cleanName}_normal',
                          ),
                          builder: (
                              context,
                              snapshot,
                              ) {
                            if (snapshot
                                .hasData &&
                                snapshot
                                    .data !=
                                    null) {
                              return Image
                                  .asset(
                                snapshot
                                    .data!,
                                fit: BoxFit
                                    .cover,
                                width: double
                                    .infinity,
                              );
                            }

                            return Icon(
                              Icons.pets,
                              size: 90,
                              color:
                              colorScheme
                                  .primary,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    Text(
                      dinosaur.name,
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight:
                        FontWeight
                            .bold,
                        color: colorScheme
                            .onSurface,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      dinosaur.periodName,
                      style: TextStyle(
                        fontSize: 17,
                        color: colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),


              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics:
                const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.45,
                children: [

                  // Orbit button

                  optionButton(
                    icon: lgService.isDinosaurOrbiting
                        ? Icons.stop_circle_outlined
                        : Icons.threesixty,
                    text: lgService.isDinosaurOrbiting
                        ? 'Stop Orbit'
                        : 'Orbit',
                    onTap: () async {
                      if (!lgService.isConnected) {
                        showSnack(
                          context,
                          'Liquid Galaxy is not connected',
                          success: false,
                        );

                        return;
                      }

                      if (lgService.isDinosaurOrbiting) {
                        await lgService
                            .stopDinosaurOrbit();

                        if (!context.mounted) {
                          return;
                        }

                        showSnack(
                          context,
                          'Orbit stopped',
                          success: true,
                        );

                        return;
                      }

                      final ok =
                      await lgService
                          .startDinosaurOrbit(
                        dinosaur,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      showSnack(
                        context,
                        ok
                            ? 'Orbit started'
                            : 'Could not start the orbit',
                        success: ok,
                      );
                    },
                  ),

                  //Narration button

                  optionButton(
                    icon: Icons.volume_up,
                    text: 'Narration',
                    onTap: startNarration,
                  ),

                  // Skeleton button that send the skeleton image

                  optionButton(
                    icon: Icons.view_in_ar,
                    text: 'Skeleton',
                    onTap: () {
                      sendToLg(
                        context,
                        'Skeleton',
                      );
                    },
                  ),

                  //Comparison button

                  optionButton(
                    icon: Icons.groups,
                    text: 'See Comparison',
                    onTap: () {
                      sendToLg(
                        context,
                        'Comparison',
                      );
                    },
                  ),
                ],
              ),

              //Stop Narration button

              if (isNarrationPlaying) ...[
                const SizedBox(
                  height: 16,
                ),

                SizedBox(
                  width:
                  double.infinity,
                  child:
                  ElevatedButton.icon(
                    onPressed:
                    stopNarration,
                    icon: const Icon(
                      Icons.stop,
                    ),
                    label: const Text(
                      'Stop Narration',
                    ),
                    style:
                    ElevatedButton
                        .styleFrom(
                      backgroundColor:
                      Colors.orange,
                      foregroundColor:
                      Colors.white,
                      padding:
                      const EdgeInsets
                          .symmetric(
                        vertical: 16,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child:
                ElevatedButton.icon(
                  onPressed:
                  returnToGoogleEarth,
                  icon: const Icon(
                    Icons
                        .desktop_windows,
                  ),
                  label: const Text(
                    'Return to Google Earth',
                  ),
                  style:
                  ElevatedButton
                      .styleFrom(
                    backgroundColor:
                    Colors.red,
                    foregroundColor:
                    Colors.white,
                    padding:
                    const EdgeInsets
                        .symmetric(
                      vertical: 16,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius
                          .circular(
                        18,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Expanded(
                    child: infoCard(
                      icon:
                      Icons.public,
                      title: 'Country',
                      value:
                      dinosaur.country,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: infoCard(
                      icon: Icons.place,
                      title: 'Region',
                      value:
                      dinosaur.region,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: infoCard(
                      icon: Icons
                          .straighten,
                      title: 'Length',
                      value: dinosaur
                          .length
                          .isEmpty
                          ? 'Unknown'
                          : dinosaur
                          .length,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: infoCard(
                      icon: Icons
                          .monitor_weight,
                      title: 'Weight',
                      value: dinosaur
                          .weight
                          .isEmpty
                          ? 'Unknown'
                          : dinosaur
                          .weight,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: infoCard(
                      icon:
                      Icons.timeline,
                      title: 'Period',
                      value: dinosaur
                          .periodName,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: infoCard(
                      icon: Icons
                          .calendar_month,
                      title: 'Year',
                      value: dinosaur
                          .year
                          .isEmpty
                          ? 'Unknown'
                          : dinosaur
                          .year,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              sectionCard(
                title:
                'Scientific Information',
                text:
                'Status: ${emptyText(dinosaur.status)}\n'
                    'Author: ${emptyText(dinosaur.author)}\n'
                    'Formation: ${emptyText(dinosaur.formation)}\n'
                    'Time: ${emptyText(dinosaur.time1)}'
                    ' - ${emptyText(dinosaur.time2)}',
              ),

              const SizedBox(height: 16),

              sectionCard(
                title:
                'Fossil Material',
                text: emptyText(
                  dinosaur.material,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  String emptyText(
      String value,
      ) {
    return value.trim().isEmpty
        ? 'Unknown'
        : value;
  }

  Widget sectionCard({
    required String title,
    required String text,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight:
              FontWeight.bold,
              color:
              colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              height: 1.35,
              color: colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      padding:
      const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Icon(
            icon,
            color:
            colorScheme.primary,
            size: 28,
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
              color: colorScheme
                  .onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            emptyText(value),
            textAlign:
            TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: colorScheme
                  .onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget optionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return ElevatedButton(
      onPressed: onTap,
      style:
      ElevatedButton.styleFrom(
        backgroundColor:
        colorScheme.primary,
        foregroundColor:
        colorScheme.onPrimary,
        elevation: 5,
        padding:
        const EdgeInsets.all(12),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            18,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 30,
          ),

          const SizedBox(height: 8),

          Text(
            text,
            textAlign:
            TextAlign.center,
            style: const TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration cardDecoration() {
    final colorScheme =
        Theme.of(context).colorScheme;

    return BoxDecoration(
      color: colorScheme
          .surfaceContainerHighest,
      borderRadius:
      BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow
              .withValues(
            alpha: 0.12,
          ),
          blurRadius: 10,
          offset:
          const Offset(0, 4),
        ),
      ],
    );
  }
}