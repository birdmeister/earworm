import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/note_event.dart';
import '../repositories/song_repository.dart';

final songRepositoryProvider = Provider<SongRepository>((ref) {
  return LocalSongRepository(outputDir: '/Users/birdman/Documents/GitHub/earworm/output');
});

final songListProvider = FutureProvider<List<Song>>((ref) {
  return ref.watch(songRepositoryProvider).listSongs();
});

final selectedSongProvider = StateProvider<Song?>((ref) => null);

final difficultyProvider = StateProvider<DifficultyLevel>(
    (ref) => DifficultyLevel.advanced);

final notesProvider = FutureProvider<List<NoteEvent>>((ref) {
  final song = ref.watch(selectedSongProvider);
  final level = ref.watch(difficultyProvider);
  if (song == null) return [];
  return ref.watch(songRepositoryProvider).loadNotes(song, level);
});
