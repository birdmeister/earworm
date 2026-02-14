import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/play_session.dart';

final scoreProvider = StateNotifierProvider<ScoreNotifier, PlaySession>((ref) {
  return ScoreNotifier();
});

class ScoreNotifier extends StateNotifier<PlaySession> {
  ScoreNotifier() : super(const PlaySession());

  void recordHit() => state = state.copyWith(hits: state.hits + 1);
  void recordMiss() => state = state.copyWith(misses: state.misses + 1);
  void recordExtra() => state = state.copyWith(extras: state.extras + 1);
  void reset() => state = const PlaySession();
}
