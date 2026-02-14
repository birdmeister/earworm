import 'package:flutter_test/flutter_test.dart';
import 'package:earworm_app/services/note_matcher.dart';
import 'package:earworm_app/models/note_event.dart';

NoteEvent _note(int pitch, double startTime) => NoteEvent(
      pitch: pitch, velocity: 80, startTime: startTime, duration: 0.5);

void main() {
  group('NoteMatcher', () {
    test('exact hit', () {
      final notes = [_note(60, 1.0)];
      final matcher = NoteMatcher(notes);
      expect(matcher.onNotePlayed(60, 1.0), true);
      expect(matcher.hits, 1);
      expect(notes[0].state, NoteState.hit);
    });

    test('hit within tolerance window', () {
      final notes = [_note(60, 1.0)];
      final matcher = NoteMatcher(notes);
      expect(matcher.onNotePlayed(60, 1.2), true); // 200ms late, within 300ms
      expect(matcher.hits, 1);
    });

    test('miss when too late', () {
      final notes = [_note(60, 1.0)];
      final matcher = NoteMatcher(notes);
      matcher.updateMisses(1.5); // 500ms past note, beyond tolerance
      expect(matcher.misses, 1);
      expect(notes[0].state, NoteState.missed);
    });

    test('wrong pitch counts as extra', () {
      final notes = [_note(60, 1.0)];
      final matcher = NoteMatcher(notes);
      expect(matcher.onNotePlayed(62, 1.0), false); // D instead of C
      expect(matcher.extras, 1);
      expect(matcher.hits, 0);
    });

    test('chord matching — each note individually', () {
      final notes = [_note(60, 1.0), _note(64, 1.0), _note(67, 1.0)];
      final matcher = NoteMatcher(notes);
      expect(matcher.onNotePlayed(60, 1.0), true);
      expect(matcher.onNotePlayed(64, 1.0), true);
      expect(matcher.onNotePlayed(67, 1.0), true);
      expect(matcher.hits, 3);
    });

    test('accuracy calculation', () {
      final notes = [_note(60, 1.0), _note(62, 2.0)];
      final matcher = NoteMatcher(notes);
      matcher.onNotePlayed(60, 1.0); // hit
      matcher.updateMisses(2.5);     // miss note at 2.0
      expect(matcher.accuracy, 50.0);
    });

    test('reset clears state', () {
      final notes = [_note(60, 1.0)];
      final matcher = NoteMatcher(notes);
      matcher.onNotePlayed(60, 1.0);
      expect(matcher.hits, 1);
      matcher.reset();
      expect(matcher.hits, 0);
      expect(notes[0].state, NoteState.upcoming);
    });
  });
}
