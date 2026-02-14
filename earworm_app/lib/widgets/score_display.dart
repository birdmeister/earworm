import 'package:flutter/material.dart';
import '../models/play_session.dart';

class ScoreDisplay extends StatelessWidget {
  final PlaySession session;

  const ScoreDisplay({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stat('Accuracy', '${session.accuracy.toStringAsFixed(0)}%'),
          const SizedBox(width: 16),
          _stat('Hits', '${session.hits}', color: const Color(0xFF44CC66)),
          const SizedBox(width: 16),
          _stat('Missed', '${session.misses}', color: const Color(0xFFCC4444)),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
