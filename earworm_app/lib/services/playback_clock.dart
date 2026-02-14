import 'package:flutter/scheduler.dart';

class PlaybackClock {
  final Stopwatch _stopwatch = Stopwatch();
  double _offsetSeconds = 0;
  double _tempoMultiplier = 1.0;

  double get positionSeconds =>
      _offsetSeconds + _stopwatch.elapsedMilliseconds / 1000 * _tempoMultiplier;

  bool get isRunning => _stopwatch.isRunning;

  double get tempoMultiplier => _tempoMultiplier;
  set tempoMultiplier(double value) {
    if (value == _tempoMultiplier) return;
    _offsetSeconds = positionSeconds;
    _stopwatch.reset();
    _tempoMultiplier = value;
    if (isRunning) _stopwatch.start();
  }

  void start() => _stopwatch.start();

  void pause() => _stopwatch.stop();

  void reset() {
    _stopwatch.reset();
    _offsetSeconds = 0;
  }

  void seek(double seconds) {
    _offsetSeconds = seconds;
    _stopwatch.reset();
    if (isRunning) _stopwatch.start();
  }
}

class ClockTicker {
  Ticker? _ticker;
  final void Function(double positionSeconds) onTick;
  final PlaybackClock clock;

  ClockTicker({required this.clock, required this.onTick});

  void start(TickerProvider vsync) {
    _ticker?.dispose();
    _ticker = vsync.createTicker((_) {
      onTick(clock.positionSeconds);
    });
    _ticker!.start();
  }

  void dispose() {
    _ticker?.dispose();
    _ticker = null;
  }
}
