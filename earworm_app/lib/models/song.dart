enum DifficultyLevel { beginner, intermediate, advanced }

class Song {
  final String id;
  final String title;
  final String basePath;
  final String? audioPath;
  final String? stemPath;

  const Song({
    required this.id,
    required this.title,
    required this.basePath,
    this.audioPath,
    this.stemPath,
  });

  String midiPathFor(DifficultyLevel level) =>
      '${basePath}_${level.name}.mid';

  String get originalMidiPath => '$basePath.mid';
}
