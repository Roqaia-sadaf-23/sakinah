import 'package:get/get.dart';

import '../../../../core/storage/storage_service.dart';
import '../../data/datasources/quran_audio_remote_data_source.dart';
import '../../data/datasources/quran_remote_data_source.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../data/services/just_audio_quran_player.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/services/quran_audio_player.dart';
import '../../domain/usecases/get_quran_surahs.dart';
import '../../domain/usecases/get_surah.dart';
import '../controllers/quran_audio_controller.dart';
import '../controllers/quran_controller.dart';
import '../controllers/quran_reader_controller.dart';

class QuranBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<QuranRemoteDataSource>()) {
      Get.lazyPut<QuranRemoteDataSource>(ApiQuranRemoteDataSource.new);
    }
    if (!Get.isRegistered<QuranAudioRemoteDataSource>()) {
      Get.lazyPut<QuranAudioRemoteDataSource>(
        ApiQuranAudioRemoteDataSource.new,
      );
    }
    if (!Get.isRegistered<QuranRepository>()) {
      Get.lazyPut<QuranRepository>(
        () => QuranRepositoryImpl(
          Get.find<QuranRemoteDataSource>(),
          Get.find<QuranAudioRemoteDataSource>(),
          Get.find<StorageService>(),
        ),
      );
    }
    if (!Get.isRegistered<GetQuranSurahs>()) {
      Get.lazyPut(() => GetQuranSurahs(Get.find<QuranRepository>()));
    }
    if (!Get.isRegistered<GetSurah>()) {
      Get.lazyPut(() => GetSurah(Get.find<QuranRepository>()));
    }
    if (!Get.isRegistered<QuranAudioPlayer>()) {
      Get.lazyPut<QuranAudioPlayer>(JustAudioQuranPlayer.new);
    }
    if (!Get.isRegistered<QuranController>()) {
      Get.lazyPut(
        () => QuranController(
          Get.find<GetQuranSurahs>(),
          Get.find<GetSurah>(),
          Get.find<QuranRepository>(),
        ),
      );
    }
    if (!Get.isRegistered<QuranAudioController>()) {
      Get.lazyPut(
        () => QuranAudioController(
          Get.find<QuranRepository>(),
          Get.find<QuranAudioPlayer>(),
        ),
      );
    }
    if (!Get.isRegistered<QuranReaderController>()) {
      Get.lazyPut(() => QuranReaderController(Get.find<StorageService>()));
    }
  }
}
