import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/song.dart';
import '../providers/song_provider.dart';
import 'play_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Earworm'),
        backgroundColor: const Color(0xFF16213E),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: songsAsync.when(
              data: (songs) {
                if (songs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No songs found.\nRun the earworm pipeline first, or open a MIDI file.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, i) => _songTile(context, ref, songs[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Open MIDI File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5599DD),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () => _pickMidiFile(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _songTile(BuildContext context, WidgetRef ref, Song song) {
    return ListTile(
      leading: const Icon(Icons.music_note, color: Color(0xFF5599DD)),
      title: Text(song.title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(song.basePath, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      onTap: () {
        ref.read(selectedSongProvider.notifier).state = song;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlayScreen()),
        );
      },
    );
  }

  Future<void> _pickMidiFile(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mid', 'midi'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.first.path!;
    final name = result.files.first.name.replaceAll(RegExp(r'\.(mid|midi)$'), '');
    final basePath = path.replaceAll(RegExp(r'\.(mid|midi)$'), '');

    final song = Song(id: name, title: name.replaceAll('_', ' '), basePath: basePath);
    ref.read(selectedSongProvider.notifier).state = song;

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlayScreen()),
      );
    }
  }
}
