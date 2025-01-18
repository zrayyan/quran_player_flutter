// lib/services/audio_service.dart

import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/ayah.dart';
import '../utils/logger.dart';

class AudioServiceState {
  final bool isPlaying;
  final bool isBuffering;
  final int currentAyahNumber;
  final int totalAyahs;
  final Duration? position;
  final Duration? duration;

  AudioServiceState({
    required this.isPlaying,
    required this.isBuffering,
    required this.currentAyahNumber,
    required this.totalAyahs,
    this.position,
    this.duration,
  });

  @override
  String toString() {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final now = DateTime.now().toUtc();

    return '''
=========================================
AUDIO SERVICE STATUS (UTC)
=========================================
Time: ${formatter.format(now)}
User: zrayyan
State: ${isPlaying ? "Playing" : isBuffering ? "Buffering" : "Stopped"}
Current Ayah: $currentAyahNumber of $totalAyahs
Position: ${position?.toString().split('.').first ?? 'N/A'}
Duration: ${duration?.toString().split('.').first ?? 'N/A'}
=========================================
''';
  }
}

class AudioService {
  final AudioPlayer _player;
  final Logger logger;
  final void Function(Ayah ayah)? onAyahChange;
  final void Function()? onPlaybackComplete;
  final void Function(String message)? onError;
  final void Function(AudioServiceState state)? onStateChange;

  final _stateController = StreamController<AudioServiceState>.broadcast();
  Stream<AudioServiceState> get stateStream => _stateController.stream;

  List<Ayah> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Timer? _positionTimer;
  final Map<String, bool> _verifiedUrls = {};

  AudioService({
    required this.logger,
    this.onAyahChange,
    this.onPlaybackComplete,
    this.onError,
    this.onStateChange,
  }) : _player = AudioPlayer() {
    _initializeAudioPlayer();
  }

  void _initializeAudioPlayer() {
    _player.playerStateStream.listen((state) {
      _handlePlayerStateChange(state);
    });

    _player.positionStream.listen((position) {
      _updateState();
    });

    _player.durationStream.listen((duration) {
      _updateState();
    });

    logger.info('Audio player initialized');
  }

  void _handlePlayerStateChange(PlayerState state) {
    switch (state.processingState) {
      case ProcessingState.loading:
      case ProcessingState.buffering:
        _isBuffering = true;
        _isPlaying = false;
        break;
      case ProcessingState.ready:
        _isBuffering = false;
        _isPlaying = state.playing;
        break;
      case ProcessingState.completed:
        _onAyahComplete();
        break;
      default:
        _isBuffering = false;
        _isPlaying = false;
    }
    _updateState();
  }

  void _updateState() {
    final state = AudioServiceState(
      isPlaying: _isPlaying,
      isBuffering: _isBuffering,
      currentAyahNumber: _currentIndex + 1,
      totalAyahs: _playlist.length,
      position: _player.position,
      duration: _player.duration,
    );
    _stateController.add(state);
    onStateChange?.call(state);
  }

  Future<void> playSurah(int surahNumber) async {
    try {
      logger.info('Loading Surah $surahNumber');

      // Example ayahs - replace with actual data from your database
      List<Ayah> ayahs = [
        Ayah(
          number: 1,
          surahNumber: surahNumber,
          text: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
          audio: 'https://verses.quran.com/AbdulBaset/Murattal/mp3/001001.mp3',
          numberInSurah: 1,
          juz: 1,
          page: 1,
        ),
        Ayah(
          number: 2,
          surahNumber: surahNumber,
          text: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
          audio: 'https://verses.quran.com/AbdulBaset/Murattal/mp3/001002.mp3',
          numberInSurah: 2,
          juz: 1,
          page: 1,
        ),
      ];

      // Load the playlist
      await loadPlaylist(ayahs);

      // Start playing
      await play();

      logger.info('Started playing Surah $surahNumber');
    } catch (e) {
      logger.error('Error playing surah: $e');
      onError?.call('Error playing surah: $e');
    }
  }

  Future<bool> _verifyAudioUrl(String url) async {
    if (_verifiedUrls.containsKey(url)) {
      return _verifiedUrls[url]!;
    }

    try {
      final response = await http.head(Uri.parse(url));
      final isValid = response.statusCode == 200;
      _verifiedUrls[url] = isValid;
      return isValid;
    } catch (e) {
      logger.error('Error verifying audio URL: $e');
      _verifiedUrls[url] = false;
      return false;
    }
  }

  Future<void> loadPlaylist(List<Ayah> ayahs) async {
    _playlist = ayahs;
    _currentIndex = 0;
    _isPlaying = false;
    _isBuffering = false;
    logger.info('Loaded playlist with ${ayahs.length} ayahs');
    _updateState();
  }

  Future<void> play() async {
    if (_playlist.isEmpty) {
      logger.warning('No ayahs loaded in playlist');
      onError?.call('No ayahs loaded in playlist');
      return;
    }

    try {
      final currentAyah = _playlist[_currentIndex];
      if (currentAyah.audio == null || currentAyah.audio!.isEmpty) {
        logger.warning('No audio URL available for ayah ${currentAyah.number}');
        _tryPlayNextAyah();
        return;
      }

      _isBuffering = true;
      _updateState();

      final isValidUrl = await _verifyAudioUrl(currentAyah.audio!);
      if (!isValidUrl) {
        logger.error('Invalid audio URL for ayah ${currentAyah.number}');
        _tryPlayNextAyah();
        return;
      }

      await _player.setUrl(currentAyah.audio!);
      await _player.play();
      onAyahChange?.call(currentAyah);

      // Pre-buffer next ayah
      _preBufferNextAyah();
    } catch (e) {
      logger.error('Error playing audio: $e');
      onError?.call('Error playing ayah: $e');
      _tryPlayNextAyah();
    }
  }

  Future<void> _preBufferNextAyah() async {
    if (_currentIndex < _playlist.length - 1) {
      final nextAyah = _playlist[_currentIndex + 1];
      if (nextAyah.audio != null) {
        await _verifyAudioUrl(nextAyah.audio!);
      }
    }
  }

  void _tryPlayNextAyah() {
    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      play();
    } else {
      _isPlaying = false;
      _updateState();
      onPlaybackComplete?.call();
    }
  }

  void _onAyahComplete() {
    logger.info('Ayah ${_playlist[_currentIndex].number} completed');
    _tryPlayNextAyah();
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    _updateState();
    logger.info('Playback paused');
  }

  Future<void> resume() async {
    await _player.play();
    _isPlaying = true;
    _updateState();
    logger.info('Playback resumed');
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _currentIndex = 0;
    _updateState();
    logger.info('Playback stopped');
  }

  Future<void> seekToAyah(int index) async {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      if (_isPlaying) {
        await play();
      } else {
        _updateState();
      }
      logger.info('Seeked to ayah ${index + 1}');
    }
  }

  Future<void> seekToNextAyah() async {
    if (_currentIndex < _playlist.length - 1) {
      await seekToAyah(_currentIndex + 1);
      logger.info('Seeked to next ayah: ${_currentIndex + 1}');
    } else {
      logger.warning('Already at last ayah');
      onError?.call('Already at last ayah');
    }
  }

  Future<void> seekToPreviousAyah() async {
    if (_currentIndex > 0) {
      await seekToAyah(_currentIndex - 1);
      logger.info('Seeked to previous ayah: ${_currentIndex + 1}');
    } else {
      logger.warning('Already at first ayah');
      onError?.call('Already at first ayah');
    }
  }

  AudioServiceState get currentState => AudioServiceState(
        isPlaying: _isPlaying,
        isBuffering: _isBuffering,
        currentAyahNumber: _currentIndex + 1,
        totalAyahs: _playlist.length,
        position: _player.position,
        duration: _player.duration,
      );

  bool get isPlaying => _isPlaying;

  @override
  void dispose() {
    _stateController.close();
    _positionTimer?.cancel();
    _player.dispose();
    logger.info('Audio service disposed');
  }
}
