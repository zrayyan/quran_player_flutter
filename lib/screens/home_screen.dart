import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../widgets/player_controls.dart';
import '../widgets/word_timing_display.dart';
import '../models/word_timing.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _surahController = TextEditingController();
  List<WordTiming> _wordTimings = [];

  @override
  void initState() {
    super.initState();
    _initializeWordTimings();
  }

  void _initializeWordTimings() {
    _wordTimings = [
      WordTiming(
        word: 'بِسْمِ',
        startTime: const Duration(milliseconds: 0),
        endTime: const Duration(milliseconds: 750),
        position: 1,
        ayahNumber: 1,
        surahNumber: 1,
        metadata: {'pauseMark': 'none'},
      ),
      WordTiming(
        word: 'ٱللَّهِ',
        transliteration: 'Allah',
        startTime: const Duration(milliseconds: 750),
        endTime: const Duration(milliseconds: 1500),
        position: 2,
        ayahNumber: 1,
        surahNumber: 1,
        metadata: {'pauseMark': 'none', 'tajweedRule': 'qalqalah'},
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _surahController,
              decoration: const InputDecoration(
                labelText: 'Enter Surah Number (1-114)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const PlayerControls(),
            const SizedBox(height: 16),
            Expanded(
              child: WordTimingDisplay(wordTimings: _wordTimings),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _playSurah,
        child: const Icon(Icons.play_arrow),
      ),
    );
  }

  void _playSurah() {
    final surahNumber = int.tryParse(_surahController.text);
    if (surahNumber != null && surahNumber > 0 && surahNumber <= 114) {
      context.read<AudioService>().playSurah(surahNumber);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid surah number (1-114)')),
      );
    }
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Quran Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Date and Time (UTC): ${DateTime.now().toUtc()}'),
            const Text('User: zrayyan'),
            const SizedBox(height: 8),
            const Text(
                'A Quran audio player with word timing synchronization.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _surahController.dispose();
    super.dispose();
  }
}
