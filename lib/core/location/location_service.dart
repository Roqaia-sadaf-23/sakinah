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

    try {
      final cached = _readCachedLocation();
      final Position position;
      if (cached != null &&
          DateTime.now().difference(cached.capturedAt) <
              AppConstants.locationCacheMaxAge) {
        return cached;
      }

      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
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
      await _storage.writeJson(StorageKeys.lastLocation, location.toJson());
      return location;
    } catch (error) {
      if (error is AppException) rethrow;
      final cached = _readCachedLocation();
      if (cached != null) return cached;
      throw AppException(AppErrorType.locationUnavailable, error);
    }
  }

  LocationData? _readCachedLocation() {
    final json = _storage.readJson(StorageKeys.lastLocation);
    if (json == null) return null;
    try {
      return LocationData.fromJson(json);
    } catch (_) {
      return null;
    }
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

/* Future<LocationData> getCurrentLocation() async {
  // 1. استخدمي الموقع المحفوظ أولاً
  final cached = _readCachedLocation();

  if (cached != null &&
      DateTime.now().difference(cached.capturedAt) <
          AppConstants.locationCacheMaxAge) {
    return cached;
  }

  // 2. بعدها فقط افحصي GPS
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const AppException(
      AppErrorType.locationServicesDisabled,
    );
  }

  var permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied) {
    throw const AppException(
      AppErrorType.locationPermissionDenied,
    );
  }

  if (permission == LocationPermission.deniedForever) {
    throw const AppException(
      AppErrorType.locationPermissionPermanentlyDenied,
    );
  }

  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );

    final place = await _findPlace(
      position.latitude,
      position.longitude,
    );

    final location = LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      city: place?.locality?.isNotEmpty == true
          ? place!.locality!
          : place?.subAdministrativeArea ?? '',
      country: place?.country ?? '',
      capturedAt: DateTime.now(),
    );

    await _storage.writeJson(
      StorageKeys.lastLocation,
      location.toJson(),
    );

    return location;
  } catch (error) {
    if (error is AppException) rethrow;

    // حتى لو أصبح الـ cache قديمًا، أفضل من فشل الصفحة بالكامل
    if (cached != null) {
      return cached;
    }

    throw AppException(
      AppErrorType.locationUnavailable,
      error,
    );
  }
} */
