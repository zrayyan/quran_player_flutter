import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import '../models/ayah.dart';
import '../utils/logger.dart';

class DatabaseService {
  late Database _db;
  final String dbPath;
  final Logger logger;

  DatabaseService({
    required this.dbPath,
    required this.logger,
  }) {
    _initDatabase();
  }

  void _initDatabase() {
    try {
      if (!File(dbPath).existsSync()) {
        throw Exception('Database not found at: $dbPath');
      }
      _db = sqlite3.open(dbPath);
      logger.info('Database connected successfully');
    } catch (e) {
      logger.error('Database initialization error: $e');
      rethrow;
    }
  }

  List<Ayah> getAyahsForSurah(int surahNumber) {
    try {
      final results = _db.select('''
        SELECT a.*, GROUP_CONCAT(sec.audio_url) as secondary_audio_urls
        FROM ayahs a
        LEFT JOIN audio_secondary sec ON a.number = sec.ayah_number
        WHERE a.surah_number = ?
        GROUP BY a.number
        ORDER BY a.numberInSurah
      ''', [surahNumber]);

      return results.map((row) => Ayah.fromMap(row)).toList();
    } catch (e) {
      logger.error('Error fetching ayahs for surah $surahNumber: $e');
      rethrow;
    }
  }

  void close() {
    _db.dispose();
    logger.info('Database connection closed');
  }
}
