import 'ayah.dart';

import 'dart:convert';
import 'package:intl/intl.dart';

/// Represents the timing information for a word in the Quran
class WordTiming {
  /// The word text in Arabic
  final String word;

  /// The word text transliteration (if available)
  final String? transliteration;

  /// Starting time of the word in the audio (in milliseconds from the start of the ayah)
  final Duration startTime;

  /// Ending time of the word in the audio (in milliseconds from the start of the ayah)
  final Duration endTime;

  /// The position of the word in the ayah (1-based index)
  final int position;

  /// The verse (ayah) number this word belongs to
  final int ayahNumber;

  /// The surah number this word belongs to
  final int surahNumber;

  /// Optional timestamp when this timing was last verified
  final DateTime? verifiedAt;

  /// Additional metadata for the word (like pause marks, tajweed rules, etc.)
  final Map<String, dynamic>? metadata;

  WordTiming({
    required this.word,
    required this.startTime,
    required this.endTime,
    required this.position,
    required this.ayahNumber,
    required this.surahNumber,
    this.transliteration,
    this.verifiedAt,
    this.metadata,
  }) {
    // Validate the timing values
    if (endTime <= startTime) {
      throw ArgumentError('End time must be greater than start time');
    }
    if (position < 1) {
      throw ArgumentError('Position must be greater than 0');
    }
    if (ayahNumber < 1) {
      throw ArgumentError('Ayah number must be greater than 0');
    }
    if (surahNumber < 1 || surahNumber > 114) {
      throw ArgumentError('Surah number must be between 1 and 114');
    }
  }

  /// Duration of the word
  Duration get duration => endTime - startTime;

  /// Converts the timing to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'transliteration': transliteration,
      'start_time': startTime.inMilliseconds,
      'end_time': endTime.inMilliseconds,
      'position': position,
      'ayah_number': ayahNumber,
      'surah_number': surahNumber,
      'verified_at': verifiedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Creates a WordTiming instance from a JSON map
  factory WordTiming.fromJson(Map<String, dynamic> json) {
    return WordTiming(
      word: json['word'] as String,
      transliteration: json['transliteration'] as String?,
      startTime: Duration(milliseconds: json['start_time'] as int),
      endTime: Duration(milliseconds: json['end_time'] as int),
      position: json['position'] as int,
      ayahNumber: json['ayah_number'] as int,
      surahNumber: json['surah_number'] as int,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Creates a copy of this WordTiming with optional parameter updates
  WordTiming copyWith({
    String? word,
    String? transliteration,
    Duration? startTime,
    Duration? endTime,
    int? position,
    int? ayahNumber,
    int? surahNumber,
    DateTime? verifiedAt,
    Map<String, dynamic>? metadata,
  }) {
    return WordTiming(
      word: word ?? this.word,
      transliteration: transliteration ?? this.transliteration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      position: position ?? this.position,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      surahNumber: surahNumber ?? this.surahNumber,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Returns true if this timing is currently active based on the given position in the audio
  bool isActiveAt(Duration position) {
    return position >= startTime && position < endTime;
  }

  /// Formats the timing information as a human-readable string
  @override
  String toString() {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    return '''
Word Timing Information:
-----------------------
Word: $word
${transliteration != null ? 'Transliteration: $transliteration' : ''}
Position: $position
Surah: $surahNumber, Ayah: $ayahNumber
Start Time: ${startTime.toString().split('.').first}
End Time: ${endTime.toString().split('.').first}
Duration: ${duration.toString().split('.').first}
${verifiedAt != null ? 'Verified At (UTC): ${formatter.format(verifiedAt!)}' : ''}
${metadata != null ? 'Metadata: ${jsonEncode(metadata)}' : ''}
''';
  }

  /// Compares two WordTiming objects for equality
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WordTiming &&
        other.word == word &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.position == position &&
        other.ayahNumber == ayahNumber &&
        other.surahNumber == surahNumber;
  }

  @override
  int get hashCode {
    return Object.hash(
      word,
      startTime,
      endTime,
      position,
      ayahNumber,
      surahNumber,
    );
  }

  /// Creates a list of WordTiming objects from a JSON array
  static List<WordTiming> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => WordTiming.fromJson(json)).toList();
  }

  /// Converts a list of WordTiming objects to a JSON array
  static List<Map<String, dynamic>> listToJson(List<WordTiming> timings) {
    return timings.map((timing) => timing.toJson()).toList();
  }

  /// Validates a list of WordTiming objects for consistency
  static bool validateTimingList(List<WordTiming> timings) {
    if (timings.isEmpty) return true;

    // Sort timings by position
    final sortedTimings = List<WordTiming>.from(timings)
      ..sort((a, b) => a.position.compareTo(b.position));

    // Check for overlapping times and sequential positions
    for (var i = 0; i < sortedTimings.length - 1; i++) {
      if (sortedTimings[i].endTime > sortedTimings[i + 1].startTime) {
        return false; // Overlapping times
      }
      if (sortedTimings[i].position + 1 != sortedTimings[i + 1].position) {
        return false; // Non-sequential positions
      }
    }

    return true;
  }
}

// Example usage:
void main() {
  // Create sample word timings
  final wordTimings = [
    WordTiming(
      word: 'بِسْمِ',
      transliteration: 'Bismi',
      startTime: Duration(milliseconds: 0),
      endTime: Duration(milliseconds: 750),
      position: 1,
      ayahNumber: 1,
      surahNumber: 1,
      verifiedAt: DateTime.now().toUtc(),
      metadata: {
        'pauseMark': 'none',
        'tajweedRule': 'idgham',
      },
    ),
    WordTiming(
      word: 'ٱللَّهِ',
      transliteration: 'Allah',
      startTime: Duration(milliseconds: 750),
      endTime: Duration(milliseconds: 1500),
      position: 2,
      ayahNumber: 1,
      surahNumber: 1,
      verifiedAt: DateTime.now().toUtc(),
      metadata: {
        'pauseMark': 'none',
        'tajweedRule': 'qalqalah',
      },
    ),
  ];

  // Print word timings
  print('Word Timings for Bismillah:');
  print('==========================');
  for (var timing in wordTimings) {
    print(timing);
  }

  // Validate timings
  print('Timings are valid: ${WordTiming.validateTimingList(wordTimings)}');

  // Convert to JSON
  final jsonData = WordTiming.listToJson(wordTimings);
  print('\nJSON representation:');
  print(JsonEncoder.withIndent('  ').convert(jsonData));
}
