import '../models/note_event.dart';

class MatchResult {
  final int hits;
  final int misses;
  final int extras;
  MatchResult({this.hits = 0, this.misses = 0, this.extras = 0});
}

class NoteMatcher {
  static const toleranceSeconds = 0.3;

  final List<NoteEvent> _notes;
  final Set<int> _matchedIndices = {};
  int _hits = 0;
  int _misses = 0;
  int _extras = 0;

  NoteMatcher(this._notes);

  int get hits => _hits;
  int get misses => _misses;
  int get extras => _extras;
  double get accuracy => (_hits + _misses) == 0 ? 0 : _hits / (_hits + _misses) * 100;

  bool onNotePlayed(int pitch, double currentTime) {
    for (var i = 0; i < _notes.length; i++) {
      if (_matchedIndices.contains(i)) continue;
      final note = _notes[i];
      if (note.pitch != pitch) continue;
      if ((note.startTime - currentTime).abs() <= toleranceSeconds) {
        _matchedIndices.add(i);
        _notes[i].state = NoteState.hit;
        _hits++;
        return true;
      }
    }
    _extras++;
    return false;
  }

  void updateMisses(double currentTime) {
    for (var i = 0; i < _notes.length; i++) {
      if (_matchedIndices.contains(i)) continue;
      final note = _notes[i];
      if (note.state == NoteState.missed) continue;
      if (currentTime > note.startTime + toleranceSeconds) {
        _notes[i].state = NoteState.missed;
        _misses++;
      }
    }
  }

  void reset() {
    _matchedIndices.clear();
    _hits = 0;
    _misses = 0;
    _extras = 0;
    for (final note in _notes) {
      note.state = NoteState.upcoming;
    }
  }
}
