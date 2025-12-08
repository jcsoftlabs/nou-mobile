import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/podcast.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  
  AudioPlayerService._internal() {
    _setupAudioPlayer();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  final ApiService _apiService = ApiService();
  
  Podcast? _currentPodcast;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _hasIncrementedListens = false; // Pour ne compter qu'à la première lecture

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  Podcast? get currentPodcast => _currentPodcast;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  void _setupAudioPlayer() {
    // Configuration pour le background playback
    _audioPlayer.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );

    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      
      // Incrémenter le compteur d'écoutes quand le podcast commence vraiment à jouer
      if (state == PlayerState.playing && _currentPodcast != null && !_hasIncrementedListens) {
        _hasIncrementedListens = true;
        _apiService.incrementPodcastListens(_currentPodcast!.id).then((success) {
          if (success) {
            debugPrint('✅ Écoute enregistrée pour le podcast ${_currentPodcast!.id}');
          }
        });
      }
      
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      _totalDuration = duration;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      _isPlaying = false;
      _currentPosition = Duration.zero;
      notifyListeners();
    });
  }

  Future<void> playPodcast(Podcast podcast) async {
    try {
      // Calcul de l'URL finale
      String url = podcast.audioUrl;
      if (url.isEmpty) {
        throw Exception("Aucune URL audio disponible pour cet épisode.");
      }
      if (url.startsWith('/')) {
        url = ApiConstants.baseUrl + url;
      }

      if (_currentPodcast?.id == podcast.id && _isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_currentPodcast?.id != podcast.id) {
          await _audioPlayer.stop();
          _currentPodcast = podcast;
          _currentPosition = Duration.zero;
          _hasIncrementedListens = false; // Réinitialiser pour le nouveau podcast
          notifyListeners();
          await _audioPlayer.play(UrlSource(url));
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      debugPrint('Erreur de lecture: $e');
      rethrow;
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentPodcast = null;
    _currentPosition = Duration.zero;
    _isPlaying = false;
    _hasIncrementedListens = false;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> seekBackward(Duration duration) async {
    final newPosition = _currentPosition - duration;
    await seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  Future<void> seekForward(Duration duration) async {
    final newPosition = _currentPosition + duration;
    await seek(newPosition > _totalDuration ? _totalDuration : newPosition);
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
