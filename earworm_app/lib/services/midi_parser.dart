import 'dart:typed_data';
import 'package:dart_midi_pro/dart_midi_pro.dart' as midi_lib;
import '../models/note_event.dart';

class MidiFileParser {
  List<NoteEvent> parse(Uint8List bytes) {
    final midi = midi_lib.MidiParser().parseMidiFromBuffer(bytes);
    final ticksPerBeat = midi.header.ticksPerBeat ?? 480;
    final tempoMap = _buildTempoMap(midi.tracks);
    final notes = <NoteEvent>[];

    for (final track in midi.tracks) {
      var absoluteTick = 0;
      final pending = <int, _PendingNote>{};

      for (final event in track) {
        absoluteTick += event.deltaTime.toInt();

        if (event is midi_lib.NoteOnEvent && event.velocity > 0) {
          pending[event.noteNumber] = _PendingNote(
            pitch: event.noteNumber,
            velocity: event.velocity,
            startTick: absoluteTick,
          );
        } else if (event is midi_lib.NoteOffEvent ||
            (event is midi_lib.NoteOnEvent && event.velocity == 0)) {
          final pitch = event is midi_lib.NoteOffEvent
              ? event.noteNumber
              : (event as midi_lib.NoteOnEvent).noteNumber;
          final p = pending.remove(pitch);
          if (p != null) {
            final startSec = _ticksToSeconds(p.startTick, ticksPerBeat, tempoMap);
            final endSec = _ticksToSeconds(absoluteTick, ticksPerBeat, tempoMap);
            notes.add(NoteEvent(
              pitch: p.pitch,
              velocity: p.velocity,
              startTime: startSec,
              duration: (endSec - startSec).clamp(0.01, double.infinity),
            ));
          }
        }
      }
    }

    notes.sort((a, b) => a.startTime.compareTo(b.startTime));
    return notes;
  }

  List<_TempoEntry> _buildTempoMap(List<List<midi_lib.MidiEvent>> tracks) {
    final entries = <_TempoEntry>[];
    for (final track in tracks) {
      var absoluteTick = 0;
      for (final event in track) {
        absoluteTick += event.deltaTime.toInt();
        if (event is midi_lib.SetTempoEvent) {
          entries.add(_TempoEntry(tick: absoluteTick, microsecondsPerBeat: event.microsecondsPerBeat));
        }
      }
    }
    entries.sort((a, b) => a.tick.compareTo(b.tick));
    if (entries.isEmpty || entries.first.tick > 0) {
      entries.insert(0, _TempoEntry(tick: 0, microsecondsPerBeat: 500000)); // 120 BPM default
    }
    return entries;
  }

  double _ticksToSeconds(int tick, int ticksPerBeat, List<_TempoEntry> tempoMap) {
    var seconds = 0.0;
    var prevTick = 0;
    var usPerBeat = tempoMap.first.microsecondsPerBeat;

    for (final entry in tempoMap) {
      if (entry.tick >= tick) break;
      final deltaTicks = entry.tick - prevTick;
      seconds += deltaTicks * usPerBeat / (ticksPerBeat * 1e6);
      prevTick = entry.tick;
      usPerBeat = entry.microsecondsPerBeat;
    }

    final remaining = tick - prevTick;
    seconds += remaining * usPerBeat / (ticksPerBeat * 1e6);
    return seconds;
  }
}

class _PendingNote {
  final int pitch;
  final int velocity;
  final int startTick;
  _PendingNote({required this.pitch, required this.velocity, required this.startTick});
}

class _TempoEntry {
  final int tick;
  final int microsecondsPerBeat;
  _TempoEntry({required this.tick, required this.microsecondsPerBeat});
}
