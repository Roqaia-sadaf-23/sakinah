import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/surah_model.dart';

abstract interface class QuranRemoteDataSource {
  Future<List<SurahModel>> fetchSurahs();

  Future<SurahModel> fetchSurah(int surahNumber);
}

class ApiQuranRemoteDataSource implements QuranRemoteDataSource {
  ApiQuranRemoteDataSource({Dio? dio})
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
  static const _textEdition = 'quran-uthmani';

  final Dio _dio;

  @override
  Future<List<SurahModel>> fetchSurahs() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/surah');
      final data = _responseData(response);
      if (data is! List) throw const FormatException('Invalid Surah list');
      return data
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Invalid Surah entry');
            }
            return SurahModel.fromJson(item);
          })
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on FormatException catch (error) {
      throw AppException(AppErrorType.invalidResponse, error);
    }
  }

  @override
  Future<SurahModel> fetchSurah(int surahNumber) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/surah/$surahNumber/$_textEdition',
      );
      final data = _responseData(response);
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid Surah response');
      }
      return SurahModel.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on FormatException catch (error) {
      throw AppException(AppErrorType.invalidResponse, error);
    }
  }

  Object? _responseData(Response<Map<String, dynamic>> response) {
    if (response.statusCode != 200 || response.data?['code'] != 200) {
      throw const FormatException('Quran API returned an error');
    }
    return response.data?['data'];
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
