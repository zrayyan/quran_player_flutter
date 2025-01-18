class Ayah {
  final int number;
  final int surahNumber;
  final String text;
  final String? audio;
  final List<String>? secondaryAudio;
  final int numberInSurah;
  final int juz;
  final int page;
  final Duration? duration;

  Ayah({
    required this.number,
    required this.surahNumber,
    required this.text,
    this.audio,
    this.secondaryAudio,
    required this.numberInSurah,
    required this.juz,
    required this.page,
    this.duration,
  });

  factory Ayah.fromMap(Map<String, dynamic> map) {
    return Ayah(
      number: map['number'],
      surahNumber: map['surah_number'],
      text: map['text'],
      audio: map['audio'],
      secondaryAudio: map['secondary_audio_urls']?.split(','),
      numberInSurah: map['numberInSurah'],
      juz: map['juz'],
      page: map['page'],
    );
  }
}
