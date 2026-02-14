import 'dart:io';
import 'dart:typed_data';
import '../models/note_event.dart';
import '../models/song.dart';
import '../services/midi_parser.dart';

abstract class SongRepository {
  Future<List<Song>> listSongs();
  Future<List<NoteEvent>> loadNotes(Song song, DifficultyLevel level);
  Future<List<NoteEvent>> loadNotesFromPath(String path);
}

class LocalSongRepository implements SongRepository {
  final String outputDir;
  final _parser = MidiFileParser();

  LocalSongRepository({required this.outputDir});

  @override
  Future<List<Song>> listSongs() async {
    final midiDir = Directory('$outputDir/midi');
    if (!await midiDir.exists()) return [];

    final songs = <Song>[];
    await for (final file in midiDir.list()) {
      if (file is File && file.path.endsWith('.mid')) {
        final name = file.uri.pathSegments.last;
        // Skip difficulty variants (e.g. _beginner.mid)
        if (name.contains('_beginner.mid') ||
            name.contains('_intermediate.mid') ||
            name.contains('_advanced.mid')) continue;

        final stem = name.replaceAll('.mid', '');
        final basePath = '${midiDir.path}/$stem';
        songs.add(Song(
          id: stem,
          title: stem.replaceAll('_', ' '),
          basePath: basePath,
          audioPath: '$outputDir/audio/$stem.wav',
          stemPath: '$outputDir/stems/htdemucs/$stem/other.wav',
        ));
      }
    }
    return songs;
  }

  @override
  Future<List<NoteEvent>> loadNotes(Song song, DifficultyLevel level) async {
    final path = song.midiPathFor(level);
    final file = File(path);
    if (!await file.exists()) {
      // Fall back to original MIDI if difficulty variant doesn't exist
      return loadNotesFromPath(song.originalMidiPath);
    }
    return loadNotesFromPath(path);
  }

  @override
  Future<List<NoteEvent>> loadNotesFromPath(String path) async {
    final bytes = await File(path).readAsBytes();
    return _parser.parse(Uint8List.fromList(bytes));
  }
}
