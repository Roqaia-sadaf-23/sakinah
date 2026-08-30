abstract interface class QuranAudioPlayer {
  Stream<void> get completedStream;

  Stream<Object> get errorStream;

  Future<void> playUrl(String url);

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<void> dispose();
}
