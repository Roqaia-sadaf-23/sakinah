import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../../domain/services/quran_audio_player.dart';

class JustAudioQuranPlayer implements QuranAudioPlayer {
  JustAudioQuranPlayer() : _player = AudioPlayer();

  final AudioPlayer _player;
  final StreamController<Object> _errors = StreamController<Object>.broadcast();

  @override
  Stream<void> get completedStream => _player.playerStateStream
      .where((state) => state.processingState == ProcessingState.completed)
      .map<void>((_) {});

  @override
  Stream<Object> get errorStream => _errors.stream;

  @override
  Future<void> playUrl(String url) async {
    await _player.stop();
    await _player.setUrl(url);
    _startPlayback();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() async {
    _startPlayback();
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() async {
    await _player.dispose();
    await _errors.close();
  }

  void _startPlayback() {
    unawaited(
      _player.play().catchError((Object error) {
        if (!_errors.isClosed) _errors.add(error);
      }),
    );
  }
}
