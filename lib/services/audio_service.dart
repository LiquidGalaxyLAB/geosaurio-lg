import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  AudioService._internal();

  static final AudioService _instance = AudioService._internal();

  factory AudioService() => _instance;

  final AudioPlayer _player = AudioPlayer();

  Future<void> playDinosaurAudio(String dinosaurName) async {
    try {
      await _player.stop();

      final fileName = dinosaurName
          .trim()
          .replaceAll(' ', '_')
          .replaceAll('.', '')
          .replaceAll('?', '')
          .replaceAll('(', '')
          .replaceAll(')', '')
          .replaceAll('-', '_');

      await _player.setAsset(
        'assets/audio/$fileName.mp3',
      );

      await _player.play();
    } catch (e) {
      debugPrint('Audio not found: $e');
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}