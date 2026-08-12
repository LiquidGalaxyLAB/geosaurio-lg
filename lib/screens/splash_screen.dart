import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _startSplash();
  }

  Future<void> _startSplash() async {
    try {
      await _audioPlayer.setAsset(
        'assets/audio/start.mp3',
      );

      await _audioPlayer.play();

      // Wait audio to finish
      await _audioPlayer.playerStateStream.firstWhere(
            (state) =>
        state.processingState ==
            ProcessingState.completed,
      );
    } catch (e) {
      debugPrint(
        'Error playing splash audio: $e',
      );

      //If the audio fails,
      //also show the splash for 5 seconds.
      await Future.delayed(
        const Duration(seconds: 5),
      );
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Image.asset(
            'assets/images/logos.png',
            width:
            MediaQuery.of(context).size.width *
                1.10,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}