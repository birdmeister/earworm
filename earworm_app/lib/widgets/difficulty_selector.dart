import 'package:flutter/material.dart';
import '../models/song.dart';

class DifficultySelector extends StatelessWidget {
  final DifficultyLevel selected;
  final ValueChanged<DifficultyLevel> onChanged;

  const DifficultySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<DifficultyLevel>(
      segments: const [
        ButtonSegment(
          value: DifficultyLevel.beginner,
          label: Text('Beginner'),
          icon: Icon(Icons.looks_one),
        ),
        ButtonSegment(
          value: DifficultyLevel.intermediate,
          label: Text('Intermediate'),
          icon: Icon(Icons.looks_two),
        ),
        ButtonSegment(
          value: DifficultyLevel.advanced,
          label: Text('Advanced'),
          icon: Icon(Icons.looks_3),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF5599DD);
          }
          return Colors.transparent;
        }),
      ),
    );
  }
}
