import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import '../storage/storage_keys.dart';
import '../storage/storage_service.dart';
import 'location_data.dart';

class LocationService {
  LocationService(this._storage);

  final StorageService _storage;

  Future<LocationData> getCurrentLocation() async {
    final cached = _readCachedLocation();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const AppException(AppErrorType.locationServicesDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const AppException(AppErrorType.locationPermissionDenied);
      }
      if (permission == LocationPermission.deniedForever) {
        throw const AppException(
          AppErrorType.locationPermissionPermanentlyDenied,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!_validCoordinates(position.latitude, position.longitude)) {
        throw const AppException(AppErrorType.locationUnavailable);
      }
      final place = await _findPlace(position.latitude, position.longitude);
      final location = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        city: place?.locality?.isNotEmpty == true
            ? place!.locality!
            : place?.subAdministrativeArea ?? '',
        country: place?.country ?? '',
        capturedAt: DateTime.now(),
      );
      try {
        await _storage.writeJson(StorageKeys.lastLocation, location.toJson());
      } catch (error) {
        if (kDebugMode) {
          debugPrint('[PrayerTime] Could not cache fresh location: $error');
        }
      }
      _logLocation(location, source: 'fresh GPS');
      return location;
    } catch (error) {
      if (cached != null) {
        _logLocation(cached, source: 'cache fallback');
        return cached;
      }
      if (error is AppException) rethrow;
      throw AppException(AppErrorType.locationUnavailable, error);
    }
  }

  LocationData? _readCachedLocation() {
    final json = _storage.readJson(StorageKeys.lastLocation);
    if (json == null) return null;
    try {
      final location = LocationData.fromJson(json);
      if (!_validCoordinates(location.latitude, location.longitude)) {
        return null;
      }
      final age = DateTime.now().difference(location.capturedAt);
      if (age.isNegative) return null;
      return location;
    } catch (_) {
      return null;
    }
  }

  static bool _validCoordinates(double latitude, double longitude) =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  static void _logLocation(LocationData location, {required String source}) {
    if (!kDebugMode) return;
    debugPrint(
      '[PrayerTime] Location ($source): '
      'lat=${location.latitude.toStringAsFixed(5)}, '
      'lng=${location.longitude.toStringAsFixed(5)}, '
      'capturedAt=${location.capturedAt.toIso8601String()}',
    );
  }

  Future<Placemark?> _findPlace(double latitude, double longitude) async {
    try {
      final places = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(AppConstants.requestTimeout);
      return places.firstOrNull;
    } catch (_) {
      return null;
    }
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
