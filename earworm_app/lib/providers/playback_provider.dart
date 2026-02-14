import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/playback_clock.dart';

final playbackClockProvider = Provider<PlaybackClock>((ref) {
  return PlaybackClock();
});

final isPlayingProvider = StateProvider<bool>((ref) => false);

final tempoProvider = StateProvider<double>((ref) => 1.0);

final playbackPositionProvider = StateProvider<double>((ref) => 0.0);
