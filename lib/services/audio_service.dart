import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  AudioService._internal();

  // Use only one instance of the audio service
  static final AudioService _instance = AudioService._internal();

  factory AudioService() => _instance;

  // Audio player
  final AudioPlayer _player = AudioPlayer();

  // Play the narration of the selected dinosaur
  Future<void> playDinosaurAudio(String dinosaurName) async {
    try {
      // Stop the previous audio
      await _player.stop();

      // Adapt the dinosaur name to the audio file name
      final fileName = dinosaurName
          .trim()
          .replaceAll(' ', '_')
          .replaceAll('.', '')
          .replaceAll('?', '')
          .replaceAll('(', '')
          .replaceAll(')', '')
          .replaceAll('-', '_');

      // Load the audio from assets
      await _player.setAsset(
        'assets/audio/$fileName.mp3',
      );

      // Play the audio
      await _player.play();
    } catch (e) {
      debugPrint('Audio not found: $e');
    }
  }

  // Stop the narration
  Future<void> stop() async {
    await _player.stop();
  }

  // Pause the narration
  Future<void> pause() async {
    await _player.pause();
  }

  // Close the audio player
  Future<void> dispose() async {
    await _player.dispose();
  }
}