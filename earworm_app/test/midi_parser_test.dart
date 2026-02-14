import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:earworm_app/services/midi_parser.dart';
import 'package:earworm_app/models/note_event.dart';

NoteEvent _makeNote(int pitch, {double startTime = 0, double duration = 0.5}) {
  return NoteEvent(pitch: pitch, velocity: 80, startTime: startTime, duration: duration);
}

void main() {
  group('MidiParser', () {
    test('parses Für Elise MIDI file', () async {
      final file = File('/Users/birdman/Documents/GitHub/earworm/output/midi/Beethoven_-_Für_Elise_Piano_Version.mid');
      if (!await file.exists()) return;

      final bytes = await file.readAsBytes();
      final notes = MidiParser().parse(Uint8List.fromList(bytes));

      expect(notes.length, greaterThan(100));

      for (final note in notes) {
        expect(note.pitch, inInclusiveRange(0, 127));
        expect(note.velocity, greaterThan(0));
        expect(note.duration, greaterThan(0));
        expect(note.startTime, greaterThanOrEqualTo(0));
      }

      // Sorted by start time
      for (var i = 1; i < notes.length; i++) {
        expect(notes[i].startTime, greaterThanOrEqualTo(notes[i - 1].startTime));
      }

      // Reasonable duration
      final totalDuration = notes.last.endTime;
      expect(totalDuration, greaterThan(60));
      expect(totalDuration, lessThan(300));
    });
  });

  group('NoteEvent', () {
    test('note names', () {
      expect(_makeNote(60).noteName, 'C4');
      expect(_makeNote(61).noteName, 'C#4');
      expect(_makeNote(69).noteName, 'A4');
      expect(_makeNote(21).noteName, 'A0');
    });

    test('black key detection', () {
      expect(_makeNote(60).isBlackKey, false);  // C
      expect(_makeNote(61).isBlackKey, true);   // C#
      expect(_makeNote(62).isBlackKey, false);  // D
      expect(_makeNote(63).isBlackKey, true);   // D#
      expect(_makeNote(64).isBlackKey, false);  // E
      expect(_makeNote(65).isBlackKey, false);  // F
      expect(_makeNote(66).isBlackKey, true);   // F#
    });

    test('endTime calculation', () {
      final note = _makeNote(60, startTime: 1.0, duration: 0.5);
      expect(note.endTime, 1.5);
    });
  });
}
