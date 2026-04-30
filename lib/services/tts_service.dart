import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    debugPrint('[TTS] Initializing...');

    if (Platform.isIOS) {
      debugPrint('[TTS] iOS detected — setting audio session to playback');
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
      debugPrint('[TTS] iOS audio session set');
    }

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() => debugPrint('[TTS] Speaking started'));
    _tts.setCompletionHandler(() => debugPrint('[TTS] Speaking completed'));
    _tts.setErrorHandler((msg) => debugPrint('[TTS] ERROR: $msg'));
    _tts.setCancelHandler(() => debugPrint('[TTS] Speaking cancelled'));

    _initialized = true;
    debugPrint('[TTS] Initialization complete');
  }

  Future<void> speak(String text) async {
    debugPrint('[TTS] speak() called with: "$text"');
    await _init();
    await _tts.stop();
    final result = await _tts.speak(text);
    debugPrint('[TTS] speak() result code: $result');
  }

  Future<void> stop() async {
    debugPrint('[TTS] stop() called');
    await _tts.stop();
  }
}
