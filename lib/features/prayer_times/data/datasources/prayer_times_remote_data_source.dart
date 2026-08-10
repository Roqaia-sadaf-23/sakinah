import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/prayer_schedule_model.dart';

class PrayerTimesRemoteDataSource {
  PrayerTimesRemoteDataSource()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          connectTimeout: AppConstants.requestTimeout,
          receiveTimeout: AppConstants.requestTimeout,
          sendTimeout: AppConstants.requestTimeout,
          responseType: ResponseType.json,
        ),
      );

  final Dio _dio;

  Future<PrayerScheduleModel> fetchSchedule({
    required DateTime date,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/timings/${DateFormat('dd-MM-yyyy').format(date)}',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'method': AppConstants.prayerCalculationMethod,
        },
      );
      final body = response.data;
      final data = body?['data'];
      if (response.statusCode != 200 || data is! Map<String, dynamic>) {
        throw const AppException(AppErrorType.invalidResponse);
      }
      return PrayerScheduleModel.fromApi(data, date);
    } on DioException catch (error) {
      final type = switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout => AppErrorType.timeout,
        DioExceptionType.connectionError => AppErrorType.network,
        _ => AppErrorType.invalidResponse,
      };
      throw AppException(type, error);
    } on FormatException catch (error) {
      throw AppException(AppErrorType.invalidResponse, error);
    }
  }
}
