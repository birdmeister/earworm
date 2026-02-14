enum NoteState { upcoming, active, hit, missed }

class NoteEvent {
  final int pitch;
  final int velocity;
  final double startTime;
  final double duration;
  NoteState state;

  NoteEvent({
    required this.pitch,
    required this.velocity,
    required this.startTime,
    required this.duration,
    this.state = NoteState.upcoming,
  });

  double get endTime => startTime + duration;

  String get noteName {
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return '${names[pitch % 12]}${pitch ~/ 12 - 1}';
  }

  bool get isBlackKey {
    const black = {1, 3, 6, 8, 10};
    return black.contains(pitch % 12);
  }

  NoteEvent copyWith({NoteState? state}) => NoteEvent(
        pitch: pitch,
        velocity: velocity,
        startTime: startTime,
        duration: duration,
        state: state ?? this.state,
      );
}
