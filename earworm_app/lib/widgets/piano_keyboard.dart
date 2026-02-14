import 'package:flutter/material.dart';
import '../models/note_event.dart';

class PianoKeyboard extends StatelessWidget {
  final Set<int> activeNotes;
  final Set<int> hitNotes;
  final int startPitch;
  final int endPitch;

  const PianoKeyboard({
    super.key,
    this.activeNotes = const {},
    this.hitNotes = const {},
    this.startPitch = 36, // C2
    this.endPitch = 84,   // C6
  });

  static const _blackKeyOffsets = {1, 3, 6, 8, 10};

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PianoKeyPainter(
        activeNotes: activeNotes,
        hitNotes: hitNotes,
        startPitch: startPitch,
        endPitch: endPitch,
      ),
    );
  }
}

class _PianoKeyPainter extends CustomPainter {
  final Set<int> activeNotes;
  final Set<int> hitNotes;
  final int startPitch;
  final int endPitch;

  _PianoKeyPainter({
    required this.activeNotes,
    required this.hitNotes,
    required this.startPitch,
    required this.endPitch,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Count white keys
    var whiteCount = 0;
    for (var p = startPitch; p <= endPitch; p++) {
      if (!PianoKeyboard._blackKeyOffsets.contains(p % 12)) whiteCount++;
    }
    if (whiteCount == 0) return;

    final whiteWidth = size.width / whiteCount;
    final blackWidth = whiteWidth * 0.6;
    final blackHeight = size.height * 0.6;

    // Draw white keys first
    var whiteIndex = 0;
    for (var p = startPitch; p <= endPitch; p++) {
      if (PianoKeyboard._blackKeyOffsets.contains(p % 12)) continue;
      final x = whiteIndex * whiteWidth;

      Color color = Colors.white;
      if (hitNotes.contains(p)) {
        color = const Color(0xFF44CC66);
      } else if (activeNotes.contains(p)) {
        color = const Color(0xFFFFAA00);
      }

      canvas.drawRect(
        Rect.fromLTWH(x, 0, whiteWidth - 1, size.height),
        Paint()..color = color,
      );
      canvas.drawRect(
        Rect.fromLTWH(x, 0, whiteWidth - 1, size.height),
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
      whiteIndex++;
    }

    // Draw black keys on top
    whiteIndex = 0;
    for (var p = startPitch; p <= endPitch; p++) {
      if (!PianoKeyboard._blackKeyOffsets.contains(p % 12)) {
        whiteIndex++;
        continue;
      }
      final x = (whiteIndex - 1) * whiteWidth + whiteWidth - blackWidth / 2;

      Color color = const Color(0xFF222222);
      if (hitNotes.contains(p)) {
        color = const Color(0xFF338844);
      } else if (activeNotes.contains(p)) {
        color = const Color(0xFFCC8800);
      }

      canvas.drawRect(
        Rect.fromLTWH(x, 0, blackWidth, blackHeight),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_PianoKeyPainter old) =>
      old.activeNotes != activeNotes || old.hitNotes != hitNotes;
}
