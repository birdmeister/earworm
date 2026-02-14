import 'dart:async';
import 'package:flutter_midi_command/flutter_midi_command.dart';

class MidiNote {
  final int pitch;
  final int velocity;
  final bool isNoteOn;
  MidiNote({required this.pitch, required this.velocity, required this.isNoteOn});
}

class MidiInput {
  final _midiCommand = MidiCommand();
  StreamSubscription? _subscription;
  final _controller = StreamController<MidiNote>.broadcast();

  Stream<MidiNote> get noteStream => _controller.stream;

  Future<List<MidiDevice>> getDevices() async =>
      await _midiCommand.devices ?? [];

  Future<void> connect(MidiDevice device) async {
    _midiCommand.connectToDevice(device);
    _subscription?.cancel();
    _subscription = _midiCommand.onMidiDataReceived?.listen(_handleData);
  }

  void _handleData(MidiPacket packet) {
    final data = packet.data;
    if (data.length < 3) return;

    final status = data[0] & 0xF0;
    final pitch = data[1];
    final velocity = data[2];

    if (status == 0x90 && velocity > 0) {
      _controller.add(MidiNote(pitch: pitch, velocity: velocity, isNoteOn: true));
    } else if (status == 0x80 || (status == 0x90 && velocity == 0)) {
      _controller.add(MidiNote(pitch: pitch, velocity: 0, isNoteOn: false));
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
