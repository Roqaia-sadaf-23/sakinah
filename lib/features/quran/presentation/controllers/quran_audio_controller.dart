import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/quran_reading_position.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/services/quran_audio_player.dart';

enum QuranPlaybackState { stopped, loading, playing, paused, error }

class QuranAudioController extends GetxController {
  QuranAudioController(this._repository, this._player);

  final QuranRepository _repository;
  final QuranAudioPlayer _player;

  final selectedReciter = SupportedReciters.misharyAlafasy.obs;
  final currentSurah = Rxn<Surah>();
  final currentAyah = Rxn<Ayah>();
  final playbackState = QuranPlaybackState.stopped.obs;
  final errorKey = ''.obs;

  StreamSubscription<void>? _completionSubscription;
  StreamSubscription<Object>? _errorSubscription;
  int _requestId = 0;

  List<Reciter> get reciters => SupportedReciters.all;
  bool get hasCurrentAyah =>
      currentSurah.value != null && currentAyah.value != null;
  bool get isPlaying => playbackState.value == QuranPlaybackState.playing;
  bool get isPaused => playbackState.value == QuranPlaybackState.paused;
  bool get isLoading => playbackState.value == QuranPlaybackState.loading;

  @override
  void onInit() {
    super.onInit();
    selectedReciter.value = _repository.getSelectedReciter();
    _completionSubscription = _player.completedStream.listen((_) {
      if (playbackState.value == QuranPlaybackState.playing) {
        unawaited(playNextAyah());
      }
    });
    _errorSubscription = _player.errorStream.listen((_) {
      if (playbackState.value == QuranPlaybackState.playing ||
          playbackState.value == QuranPlaybackState.loading) {
        errorKey.value = 'quran_audio_unavailable';
        playbackState.value = QuranPlaybackState.error;
      }
    });
  }

  bool isCurrent(int surahNumber, int ayahNumber) =>
      currentSurah.value?.number == surahNumber &&
      currentAyah.value?.numberInSurah == ayahNumber &&
      playbackState.value != QuranPlaybackState.stopped &&
      playbackState.value != QuranPlaybackState.error;

  Future<void> selectReciter(Reciter reciter) async {
    if (selectedReciter.value.id == reciter.id) return;
    await stop();
    selectedReciter.value = reciter;
    try {
      await _repository.saveSelectedReciter(reciter);
    } catch (_) {
      errorKey.value = 'quran_settings_error';
    }
  }

  Future<void> playAyah(Surah surah, Ayah ayah) async {
    final isSameAyah =
        currentSurah.value?.number == surah.number &&
        currentAyah.value?.numberInSurah == ayah.numberInSurah;
    if (isSameAyah) {
      if (isPlaying) {
        await pause();
        return;
      }
      if (isPaused) {
        await resume();
        return;
      }
      if (isLoading) return;
    }

    final requestId = ++_requestId;
    await _player.stop();
    currentSurah.value = surah;
    currentAyah.value = ayah;
    errorKey.value = '';
    playbackState.value = QuranPlaybackState.loading;
    unawaited(
      _repository
          .saveLastReadingPosition(
            QuranReadingPosition(
              surahNumber: surah.number,
              ayahNumber: ayah.numberInSurah,
            ),
          )
          .catchError((_) {}),
    );

    try {
      final urls = await _repository.getAyahAudioUrls(
        surahNumber: surah.number,
        reciter: selectedReciter.value,
      );
      if (requestId != _requestId) return;
      final url = urls[ayah.numberInSurah];
      if (url == null) {
        throw const AppException(AppErrorType.invalidResponse);
      }
      await _player.playUrl(url);
      if (requestId == _requestId) {
        playbackState.value = QuranPlaybackState.playing;
      }
    } catch (error) {
      if (requestId != _requestId) return;
      errorKey.value = _errorKeyFor(error);
      playbackState.value = QuranPlaybackState.error;
    }
  }

  Future<void> pause() async {
    if (!isPlaying) return;
    await _player.pause();
    playbackState.value = QuranPlaybackState.paused;
  }

  Future<void> resume() async {
    if (!isPaused) return;
    try {
      await _player.resume();
      playbackState.value = QuranPlaybackState.playing;
    } catch (_) {
      errorKey.value = 'quran_audio_unavailable';
      playbackState.value = QuranPlaybackState.error;
    }
  }

  Future<void> stop() async {
    _requestId++;
    await _player.stop();
    playbackState.value = QuranPlaybackState.stopped;
    errorKey.value = '';
  }

  Future<void> playNextAyah() => _playRelative(1);

  Future<void> playPreviousAyah() => _playRelative(-1);

  Future<void> _playRelative(int offset) async {
    final surah = currentSurah.value;
    final ayah = currentAyah.value;
    if (surah == null || ayah == null) return;
    final nextIndex = ayah.numberInSurah - 1 + offset;
    if (nextIndex < 0 || nextIndex >= surah.ayahs.length) {
      await stop();
      return;
    }
    await playAyah(surah, surah.ayahs[nextIndex]);
  }

  String _errorKeyFor(Object error) {
    if (error is AppException) {
      return switch (error.type) {
        AppErrorType.network => 'quran_audio_no_internet',
        AppErrorType.timeout => 'quran_audio_timeout',
        _ => 'quran_audio_unavailable',
      };
    }
    return 'quran_audio_unavailable';
  }

  @override
  void onClose() {
    unawaited(_completionSubscription?.cancel());
    unawaited(_errorSubscription?.cancel());
    unawaited(_player.dispose());
    super.onClose();
  }
}
