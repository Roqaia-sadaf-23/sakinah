import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/features/quran/domain/entities/ayah.dart';
import 'package:sakinah/features/quran/domain/entities/quran_reading_position.dart';
import 'package:sakinah/features/quran/domain/entities/reciter.dart';
import 'package:sakinah/features/quran/domain/entities/surah.dart';
import 'package:sakinah/features/quran/domain/repositories/quran_repository.dart';
import 'package:sakinah/features/quran/domain/services/quran_audio_player.dart';
import 'package:sakinah/features/quran/presentation/controllers/quran_audio_controller.dart';

void main() {
  test('plays the tapped Ayah and advances when playback completes', () async {
    final repository = _AudioTestRepository();
    final player = _FakeQuranAudioPlayer();
    final controller = QuranAudioController(repository, player)..onInit();
    addTearDown(controller.onClose);

    await controller.playAyah(_surah, _surah.ayahs[1]);
    expect(controller.currentAyah.value?.numberInSurah, 2);
    expect(player.playedUrls.last, endsWith('/ar.alafasy/2.mp3'));
    expect(controller.playbackState.value, QuranPlaybackState.playing);

    player.completeCurrentAyah();
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(controller.currentAyah.value?.numberInSurah, 3);
    expect(player.playedUrls.last, endsWith('/ar.alafasy/3.mp3'));
  });

  test('tapping the current Ayah pauses and resumes one player', () async {
    final player = _FakeQuranAudioPlayer();
    final controller = QuranAudioController(_AudioTestRepository(), player)
      ..onInit();
    addTearDown(controller.onClose);

    await controller.playAyah(_surah, _surah.ayahs.first);
    await controller.playAyah(_surah, _surah.ayahs.first);
    expect(controller.playbackState.value, QuranPlaybackState.paused);
    expect(player.pauseCalls, 1);

    await controller.playAyah(_surah, _surah.ayahs.first);
    expect(controller.playbackState.value, QuranPlaybackState.playing);
    expect(player.resumeCalls, 1);
    expect(player.playedUrls, hasLength(1));
  });

  test('tapping another Ayah stops before playing the new selection', () async {
    final player = _FakeQuranAudioPlayer();
    final controller = QuranAudioController(_AudioTestRepository(), player)
      ..onInit();
    addTearDown(controller.onClose);

    await controller.playAyah(_surah, _surah.ayahs.first);
    await controller.playAyah(_surah, _surah.ayahs[1]);

    expect(player.stopCalls, 2);
    expect(player.playedUrls, hasLength(2));
    expect(player.playedUrls.last, endsWith('/ar.alafasy/2.mp3'));
    expect(controller.currentAyah.value?.numberInSurah, 2);
    expect(controller.playbackState.value, QuranPlaybackState.playing);
  });

  test('changing reciter stops playback and persists the selection', () async {
    final repository = _AudioTestRepository();
    final player = _FakeQuranAudioPlayer();
    final controller = QuranAudioController(repository, player)..onInit();
    addTearDown(controller.onClose);

    await controller.playAyah(_surah, _surah.ayahs.first);
    await controller.selectReciter(SupportedReciters.husary);

    expect(player.stopCalls, greaterThanOrEqualTo(2));
    expect(controller.playbackState.value, QuranPlaybackState.stopped);
    expect(repository.savedReciter?.id, SupportedReciters.husary.id);

    await controller.playAyah(_surah, _surah.ayahs.first);
    expect(player.playedUrls.last, endsWith('/ar.husary/1.mp3'));
  });

  test('surfaces an asynchronous decoder error without throwing', () async {
    final player = _FakeQuranAudioPlayer();
    final controller = QuranAudioController(_AudioTestRepository(), player)
      ..onInit();
    addTearDown(controller.onClose);

    await controller.playAyah(_surah, _surah.ayahs.first);
    player.failCurrentAyah();
    await Future<void>.delayed(Duration.zero);

    expect(controller.playbackState.value, QuranPlaybackState.error);
    expect(controller.errorKey.value, 'quran_audio_unavailable');
  });
}

const _surah = Surah(
  number: 1,
  arabicName: 'الفاتحة',
  englishName: 'Al-Faatiha',
  englishNameTranslation: 'The Opening',
  revelationType: 'Meccan',
  numberOfAyahs: 3,
  ayahs: [
    Ayah(number: 1, numberInSurah: 1, text: 'الأولى', juz: 1, page: 1),
    Ayah(number: 2, numberInSurah: 2, text: 'الثانية', juz: 1, page: 1),
    Ayah(number: 3, numberInSurah: 3, text: 'الثالثة', juz: 1, page: 1),
  ],
);

class _AudioTestRepository implements QuranRepository {
  Reciter? savedReciter;
  QuranReadingPosition? savedPosition;

  @override
  Future<Map<int, String>> getAyahAudioUrls({
    required int surahNumber,
    required Reciter reciter,
  }) async => <int, String>{
    for (var index = 1; index <= 3; index++)
      index: 'https://example.com/${reciter.audioIdentifier}/$index.mp3',
  };

  @override
  QuranReadingPosition? getLastReadingPosition() => savedPosition;

  @override
  Reciter getSelectedReciter() => SupportedReciters.misharyAlafasy;

  @override
  Future<Surah> getSurah(int surahNumber, {bool forceRefresh = false}) async =>
      _surah;

  @override
  Future<List<Surah>> getSurahs({bool forceRefresh = false}) async => [_surah];

  @override
  Future<void> saveLastReadingPosition(QuranReadingPosition position) async {
    savedPosition = position;
  }

  @override
  Future<void> saveSelectedReciter(Reciter reciter) async {
    savedReciter = reciter;
  }
}

class _FakeQuranAudioPlayer implements QuranAudioPlayer {
  final _completed = StreamController<void>.broadcast();
  final _errors = StreamController<Object>.broadcast();
  final playedUrls = <String>[];
  int pauseCalls = 0;
  int resumeCalls = 0;
  int stopCalls = 0;

  @override
  Stream<void> get completedStream => _completed.stream;

  @override
  Stream<Object> get errorStream => _errors.stream;

  void completeCurrentAyah() => _completed.add(null);

  void failCurrentAyah() => _errors.add(StateError('decoder failed'));

  @override
  Future<void> playUrl(String url) async => playedUrls.add(url);

  @override
  Future<void> pause() async => pauseCalls++;

  @override
  Future<void> resume() async => resumeCalls++;

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Future<void> dispose() async {
    await _completed.close();
    await _errors.close();
  }
}
