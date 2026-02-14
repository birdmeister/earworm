import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import '../models/note_event.dart';
import '../models/song.dart';
import '../providers/song_provider.dart';
import '../providers/playback_provider.dart';
import '../providers/midi_input_provider.dart';
import '../providers/score_provider.dart';
import '../services/playback_clock.dart';
import '../services/note_matcher.dart';
import '../widgets/falling_notes_painter.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/score_display.dart';
import '../widgets/difficulty_selector.dart';

class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen>
    with SingleTickerProviderStateMixin {
  late final PlaybackClock _clock;
  late final Ticker _ticker;
  NoteMatcher? _matcher;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _midiSub;
  final Set<int> _activeInputNotes = {};
  final Set<int> _hitInputNotes = {};

  @override
  void initState() {
    super.initState();
    _clock = ref.read(playbackClockProvider);
    _ticker = createTicker(_onTick);
    _ticker.start();
    _setupMidiInput();
  }

  void _setupMidiInput() {
    _midiSub = ref.read(midiInputProvider).noteStream.listen((note) {
      if (!_clock.isRunning) return;
      setState(() {
        if (note.isNoteOn) {
          _activeInputNotes.add(note.pitch);
          if (_matcher != null) {
            final wasHit = _matcher!.onNotePlayed(note.pitch, _clock.positionSeconds);
            if (wasHit) {
              _hitInputNotes.add(note.pitch);
              ref.read(scoreProvider.notifier).recordHit();
            } else {
              ref.read(scoreProvider.notifier).recordExtra();
            }
          }
        } else {
          _activeInputNotes.remove(note.pitch);
          _hitInputNotes.remove(note.pitch);
        }
      });
    });
  }

  void _onTick(Duration elapsed) {
    if (!_clock.isRunning) return;
    final pos = _clock.positionSeconds;
    ref.read(playbackPositionProvider.notifier).state = pos;
    _matcher?.updateMisses(pos);
    // Sync score provider with matcher
    if (_matcher != null) {
      final score = ref.read(scoreProvider);
      if (score.misses != _matcher!.misses) {
        ref.read(scoreProvider.notifier).recordMiss();
      }
    }
    setState(() {});
  }

  void _togglePlayPause() {
    if (_clock.isRunning) {
      _clock.pause();
      _audioPlayer.pause();
    } else {
      _clock.start();
      _tryPlayAudio();
    }
    ref.read(isPlayingProvider.notifier).state = _clock.isRunning;
    setState(() {});
  }

  void _reset() {
    _clock.reset();
    _audioPlayer.seek(Duration.zero);
    _audioPlayer.pause();
    _matcher?.reset();
    ref.read(scoreProvider.notifier).reset();
    ref.read(isPlayingProvider.notifier).state = false;
    ref.read(playbackPositionProvider.notifier).state = 0;
    setState(() {});
  }

  Future<void> _tryPlayAudio() async {
    final song = ref.read(selectedSongProvider);
    if (song == null) return;

    // Try stem first, then original audio
    final paths = [song.stemPath, song.audioPath].whereType<String>();
    for (final path in paths) {
      if (await File(path).exists()) {
        try {
          await _audioPlayer.setFilePath(path);
          await _audioPlayer.seek(Duration(
              milliseconds: (_clock.positionSeconds * 1000).round()));
          _audioPlayer.play();
          return;
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _midiSub?.cancel();
    _audioPlayer.dispose();
    _clock.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(selectedSongProvider);
    final notesAsync = ref.watch(notesProvider);
    final difficulty = ref.watch(difficultyProvider);
    final session = ref.watch(scoreProvider);
    final tempo = ref.watch(tempoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        title: Text(song?.title ?? 'Play Along',
            style: const TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF16213E),
        actions: [
          ScoreDisplay(session: session),
          const SizedBox(width: 8),
        ],
      ),
      body: notesAsync.when(
        data: (notes) {
          _matcher ??= NoteMatcher(notes);
          return Column(
            children: [
              // Difficulty selector
              Padding(
                padding: const EdgeInsets.all(8),
                child: DifficultySelector(
                  selected: difficulty,
                  onChanged: (level) {
                    ref.read(difficultyProvider.notifier).state = level;
                    _matcher = null; // Will be recreated on next build
                    _reset();
                  },
                ),
              ),
              // Falling notes
              Expanded(
                child: CustomPaint(
                  painter: FallingNotesPainter(
                    notes: notes,
                    currentTime: _clock.positionSeconds,
                  ),
                  size: Size.infinite,
                ),
              ),
              // Piano keyboard
              SizedBox(
                height: 80,
                child: PianoKeyboard(
                  activeNotes: _activeInputNotes,
                  hitNotes: _hitInputNotes,
                ),
              ),
              // Controls
              _controls(tempo),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading MIDI: $e',
              style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }

  Widget _controls(double tempo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF16213E),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.replay, color: Colors.white70),
            onPressed: _reset,
          ),
          IconButton(
            icon: Icon(
              _clock.isRunning ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
            onPressed: _togglePlayPause,
          ),
          const SizedBox(width: 16),
          const Text('Tempo', style: TextStyle(color: Colors.white54, fontSize: 12)),
          Expanded(
            child: Slider(
              value: tempo,
              min: 0.25,
              max: 1.5,
              divisions: 10,
              label: '${(tempo * 100).round()}%',
              onChanged: (v) {
                ref.read(tempoProvider.notifier).state = v;
                _clock.tempoMultiplier = v;
              },
            ),
          ),
          Text('${(tempo * 100).round()}%',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
