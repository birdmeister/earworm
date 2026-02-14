import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/midi_input.dart';

final midiInputProvider = Provider<MidiInput>((ref) {
  final input = MidiInput();
  ref.onDispose(() => input.dispose());
  return input;
});

final midiNoteStreamProvider = StreamProvider<MidiNote>((ref) {
  return ref.watch(midiInputProvider).noteStream;
});
