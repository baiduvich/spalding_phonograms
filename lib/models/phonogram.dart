class Phonogram {
  final int id;
  final String letters;
  final List<String> sounds;
  final List<String> soundLabels;
  final List<String> keywords;

  const Phonogram({
    required this.id,
    required this.letters,
    required this.sounds,
    required this.soundLabels,
    required this.keywords,
  });
}
