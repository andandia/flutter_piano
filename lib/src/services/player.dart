import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_midi/flutter_midi.dart';

@lazySingleton
class PlayerService {
  final FlutterMidi _flutterMidi = FlutterMidi();
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
    // Unmute device (as per original app behavior)
    _flutterMidi.unmute();

    ByteData bytes = await rootBundle.load('assets/sounds/Piano.sf2');
    await _flutterMidi.prepare(sf2: bytes, name: 'Piano.sf2');

    _isInitialized = true;
  }

  Future<void> play(int midi, {bool sustain = false}) async {
    if (!_isInitialized) return;
    
    _sustainEnabled = sustain;
    _flutterMidi.playMidiNote(midi: midi);
  }

  Future<void> stop(int midi, {bool sustain = false}) async {
    if (!_isInitialized) return;

    _sustainEnabled = sustain;
    
    if (_sustainEnabled) {
      _sustainedNotes.add(midi);
    } else {
      _flutterMidi.stopMidiNote(midi: midi);
    }
  }

  Future<void> stopSustain() async {
    if (!_isInitialized) return;

    _sustainEnabled = false;

    for (int note in _sustainedNotes) {
      _flutterMidi.stopMidiNote(midi: note);
    }
    _sustainedNotes.clear();
  }
}
