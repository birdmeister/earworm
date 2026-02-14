import 'package:flutter/material.dart';
import '../models/note_event.dart';

class FallingNotesPainter extends CustomPainter {
  final List<NoteEvent> notes;
  final double currentTime;
  final double pixelsPerSecond;
  final double hitLineRatio;

  // Piano range: A0 (21) to C8 (108) = 88 keys
  static const int minPitch = 21;
  static const int maxPitch = 108;
  static const int pitchRange = maxPitch - minPitch + 1;

  FallingNotesPainter({
    required this.notes,
    required this.currentTime,
    this.pixelsPerSecond = 200,
    this.hitLineRatio = 0.75,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hitLineY = size.height * hitLineRatio;
    final noteWidth = size.width / pitchRange;

    // Draw hit line
    canvas.drawLine(
      Offset(0, hitLineY),
      Offset(size.width, hitLineY),
      Paint()
        ..color = Colors.white24
        ..strokeWidth = 2,
    );

    // Visible time window: ~3 seconds above and 1 second below hit line
    final visibleTop = currentTime - 1;
    final visibleBottom = currentTime + 4;

    for (final note in notes) {
      if (note.endTime < visibleTop || note.startTime > visibleBottom) continue;

      final x = (note.pitch - minPitch) * noteWidth;
      final topY = hitLineY - (note.startTime - currentTime) * pixelsPerSecond;
      final height = note.duration * pixelsPerSecond;
      final bottomY = topY + height;

      final color = switch (note.state) {
        NoteState.upcoming => note.isBlackKey ? const Color(0xFF4488CC) : const Color(0xFF5599DD),
        NoteState.active => const Color(0xFFFFAA00),
        NoteState.hit => const Color(0xFF44CC66),
        NoteState.missed => const Color(0xFFCC4444),
      };

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(x + 1, topY, x + noteWidth - 1, topY + height),
        const Radius.circular(4),
      );

      canvas.drawRRect(rect, Paint()..color = color);

      // Draw note name for wider notes
      if (noteWidth > 12 && height > 16) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: note.noteName,
            style: const TextStyle(color: Colors.white, fontSize: 9),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(x + 3, topY + 2));
      }
    }
  }

  @override
  bool shouldRepaint(FallingNotesPainter oldDelegate) =>
      oldDelegate.currentTime != currentTime;
}
