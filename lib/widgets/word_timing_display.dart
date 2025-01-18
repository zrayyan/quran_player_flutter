import 'package:flutter/material.dart';
import '../models/word_timing.dart';

class WordTimingDisplay extends StatelessWidget {
  final List<WordTiming> wordTimings;

  const WordTimingDisplay({
    super.key,
    required this.wordTimings,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: wordTimings.length,
      itemBuilder: (context, index) {
        final timing = wordTimings[index];
        return Card(
          child: ListTile(
            title: Text(
              timing.word,
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 24),
            ),
            subtitle: Text(
              timing.transliteration ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            trailing: Text(
              '${timing.startTime.inMilliseconds}ms - ${timing.endTime.inMilliseconds}ms',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
