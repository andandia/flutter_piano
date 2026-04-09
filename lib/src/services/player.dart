import 'dart:io';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_midi_16kb/flutter_midi_16kb.dart';
import 'package:path_provider/path_provider.dart';

@lazySingleton
class PlayerService {
  bool _isInitialized = false;

  // We keep track of played notes manually because flutter_midi doesn't
  // expose CC (Sustain) natively, so we might need to simulate sustain if needed.
  // Actually, since the user wants low latency and the plugin handles basic noteOn/Off,
  // we'll just pass noteOn and noteOff. If sustain is true, we might just not send noteOff until stopSustain.
  final Set<int> _sustainedNotes = {};
  bool _sustainEnabled = false;

  PlayerService() {
    _init();
  }

  Future<void> _init() async {
    await FlutterMidi16kb.initialize();

    ByteData bytes = await rootBundle.load('assets/sounds/Piano.sf2');
    final buffer = bytes.buffer;

    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    File file = File('$tempPath/Piano.sf2');
    await file.writeAsBytes(buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));

    await FlutterMidi16kb.loadSoundfont(file.path);

    _isInitialized = true;
  }

  Future<void> play(int midi, {bool sustain = false}) async {
    if (!_isInitialized) return;
    
    _sustainEnabled = sustain;
    FlutterMidi16kb.playNote(key: midi);
  }

  Future<void> stop(int midi, {bool sustain = false}) async {
    if (!_isInitialized) return;

    _sustainEnabled = sustain;
    
    if (_sustainEnabled) {
      _sustainedNotes.add(midi);
    } else {
      FlutterMidi16kb.stopNote(key: midi);
    }
  }

  Future<void> stopSustain() async {
    if (!_isInitialized) return;

    _sustainEnabled = false;

    for (int note in _sustainedNotes) {
      FlutterMidi16kb.stopNote(key: note);
    }
    _sustainedNotes.clear();
  }
}
