import 'package:flutter_test/flutter_test.dart';
import 'package:earworm_app/services/playback_clock.dart';

void main() {
  group('PlaybackClock', () {
    test('starts at zero', () {
      final clock = PlaybackClock();
      expect(clock.positionSeconds, 0.0);
      expect(clock.isRunning, false);
    });

    test('advances when running', () async {
      final clock = PlaybackClock();
      clock.start();
      await Future.delayed(const Duration(milliseconds: 100));
      clock.pause();
      expect(clock.positionSeconds, greaterThan(0.05));
      expect(clock.positionSeconds, lessThan(0.3));
    });

    test('pause stops advancing', () async {
      final clock = PlaybackClock();
      clock.start();
      await Future.delayed(const Duration(milliseconds: 50));
      clock.pause();
      final pos = clock.positionSeconds;
      await Future.delayed(const Duration(milliseconds: 50));
      expect(clock.positionSeconds, pos);
    });

    test('seek changes position', () {
      final clock = PlaybackClock();
      clock.seek(10.0);
      expect(clock.positionSeconds, closeTo(10.0, 0.01));
    });

    test('reset returns to zero', () async {
      final clock = PlaybackClock();
      clock.start();
      await Future.delayed(const Duration(milliseconds: 50));
      clock.reset();
      expect(clock.positionSeconds, 0.0);
    });

    test('tempo multiplier affects speed', () async {
      final clock = PlaybackClock();
      clock.tempoMultiplier = 0.5;
      clock.start();
      await Future.delayed(const Duration(milliseconds: 100));
      clock.pause();
      final halfPos = clock.positionSeconds;

      final clock2 = PlaybackClock();
      clock2.tempoMultiplier = 1.0;
      clock2.start();
      await Future.delayed(const Duration(milliseconds: 100));
      clock2.pause();
      final fullPos = clock2.positionSeconds;

      // Half-speed should be roughly half the position
      expect(halfPos, lessThan(fullPos * 0.8));
    });
  });
}
