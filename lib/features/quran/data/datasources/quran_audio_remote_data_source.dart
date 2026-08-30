import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';

abstract interface class QuranAudioRemoteDataSource {
  Future<Map<int, String>> fetchAyahAudioUrls({
    required int surahNumber,
    required String audioIdentifier,
  });
}

class ApiQuranAudioRemoteDataSource implements QuranAudioRemoteDataSource {
  ApiQuranAudioRemoteDataSource({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: AppConstants.requestTimeout,
              receiveTimeout: AppConstants.requestTimeout,
              sendTimeout: AppConstants.requestTimeout,
              responseType: ResponseType.json,
            ),
          );

  static const _baseUrl = 'https://api.alquran.cloud/v1';
  final Dio _dio;

  @override
  Future<Map<int, String>> fetchAyahAudioUrls({
    required int surahNumber,
    required String audioIdentifier,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/surah/$surahNumber/$audioIdentifier',
      );
      final body = response.data;
      final data = body?['data'];
      if (response.statusCode != 200 ||
          body?['code'] != 200 ||
          data is! Map<String, dynamic>) {
        throw const FormatException('Invalid Quran audio response');
      }
      final edition = data['edition'];
      final ayahs = data['ayahs'];
      if (edition is! Map<String, dynamic> ||
          edition['identifier'] != audioIdentifier ||
          edition['format'] != 'audio' ||
          ayahs is! List) {
        throw const FormatException('Invalid Quran audio edition');
      }

      final urls = <int, String>{};
      for (final item in ayahs) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid Quran audio Ayah');
        }
        final number = item['numberInSurah'];
        final audio = item['audio'];
        final uri = audio is String ? Uri.tryParse(audio) : null;
        if (number is! int || uri == null || uri.scheme != 'https') {
          throw const FormatException('Invalid Quran audio URL');
        }
        urls[number] = audio as String;
      }
      if (urls.isEmpty) {
        throw const FormatException('Empty Quran audio response');
      }
      return urls;
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on FormatException catch (error) {
      throw AppException(AppErrorType.invalidResponse, error);
    }
  }
}

AppException _mapDioException(DioException error) {
  final type = switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => AppErrorType.timeout,
    DioExceptionType.connectionError => AppErrorType.network,
    _ => AppErrorType.invalidResponse,
  };
  return AppException(type, error);
}
