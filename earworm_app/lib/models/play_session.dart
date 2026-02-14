class PlaySession {
  final int hits;
  final int misses;
  final int extras;
  final double durationSeconds;

  const PlaySession({
    this.hits = 0,
    this.misses = 0,
    this.extras = 0,
    this.durationSeconds = 0,
  });

  double get accuracy =>
      (hits + misses) == 0 ? 0 : hits / (hits + misses) * 100;

  PlaySession copyWith({int? hits, int? misses, int? extras, double? durationSeconds}) =>
      PlaySession(
        hits: hits ?? this.hits,
        misses: misses ?? this.misses,
        extras: extras ?? this.extras,
        durationSeconds: durationSeconds ?? this.durationSeconds,
      );
}
