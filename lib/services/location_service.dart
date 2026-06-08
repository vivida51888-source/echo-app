import 'dart:async' show TimeoutException;

import 'package:flutter/foundation.dart';

import '../l10n/localized.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// 写日记时的可选定位。
class DiaryLocation {
  const DiaryLocation({
    required this.latitude,
    required this.longitude,
    required this.placeLabel,
    this.approximate = false,
  });

  final double latitude;
  final double longitude;
  final String placeLabel;

  /// 来自缓存或较久前的系统位置；界面可标「约」，并会在后台尝试刷新。
  final bool approximate;
}

enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unavailable,
}

class LocationResolveResult {
  const LocationResolveResult._({this.location, this.failure});

  const LocationResolveResult.success(DiaryLocation location)
      : this._(location: location);

  const LocationResolveResult.failure(LocationFailure failure)
      : this._(failure: failure);

  final DiaryLocation? location;
  final LocationFailure? failure;

  bool get isSuccess => location != null;

  String get userMessage => switch (failure) {
        LocationFailure.serviceDisabled =>
          tr('请打开手机定位服务', 'Turn on location services'),
        LocationFailure.permissionDenied =>
          tr('需要位置权限才能记录地点', 'Location permission is required'),
        LocationFailure.permissionDeniedForever => tr(
              '位置权限已关闭，请在系统设置中允许 Echo 使用位置',
              'Location is off — allow Echo in system settings',
            ),
        LocationFailure.timeout => tr(
              '定位超时，请到开阔处后重试',
              'Location timed out — try again in an open area',
            ),
        LocationFailure.unavailable => tr(
              '暂时无法获取位置，请稍后再试',
              'Cannot get location right now — try again later',
            ),
        null => '',
      };
}

class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  /// 内存缓存：20 分钟内、且为精确定位结果时可即时复用。
  static const _memoryFreshTtl = Duration(minutes: 20);

  /// 系统上次坐标超过此时长则先尝试 GPS（便于换城市后更新）。
  static const _trustLastPositionTtl = Duration(minutes: 20);

  static const _stalePositionTtl = Duration(days: 7);

  static const _gpsQuickWait = Duration(seconds: 5);
  static const _geocodeWait = Duration(seconds: 3);
  static const _totalWait = Duration(seconds: 10);

  static const _quickGps = LocationSettings(
    accuracy: LocationAccuracy.low,
    timeLimit: Duration(seconds: 5),
  );

  DiaryLocation? _memoryPlace;
  DateTime? _memoryAt;
  final Map<String, _GeocodeCacheEntry> _geocodeCache = {};

  Future<void> warmUp() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied ||
          p == LocationPermission.deniedForever) {
        return;
      }
      await Geolocator.getLastKnownPosition();
    } catch (_) {}
  }

  /// 即时展示：仅用于先显示「约」占位，不写入长期缓存。
  Future<DiaryLocation?> resolveCachedPlace() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final cached = _readMemory();
      if (cached != null) return cached;

      final last = await Geolocator.getLastKnownPosition();
      if (last == null || _positionAge(last) > _stalePositionTtl) {
        return null;
      }
      if (_positionAge(last) <= _trustLastPositionTtl) {
        final place = await _labelFor(
          last.latitude,
          last.longitude,
          approximate: false,
        );
        _remember(place);
        return place;
      }

      return _labelFor(
        last.latitude,
        last.longitude,
        approximate: true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<LocationResolveResult> resolveCurrentPlace({
    bool preferFresh = false,
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResolveResult.failure(
          LocationFailure.serviceDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResolveResult.failure(
          LocationFailure.permissionDenied,
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResolveResult.failure(
          LocationFailure.permissionDeniedForever,
        );
      }

      return await _resolveCore(preferFresh: preferFresh).timeout(
        _totalWait,
        onTimeout: () async {
          final fallback = await _placeFromLastKnown(
            maxAge: const Duration(days: 30),
            approximate: true,
          );
          if (fallback != null) {
            return LocationResolveResult.success(fallback);
          }
          return const LocationResolveResult.failure(LocationFailure.timeout);
        },
      );
    } catch (e, st) {
      if (e is TimeoutException) {
        final fallback = await _placeFromLastKnown(
          maxAge: const Duration(days: 30),
          approximate: true,
        );
        if (fallback != null) {
          return LocationResolveResult.success(fallback);
        }
        return const LocationResolveResult.failure(LocationFailure.timeout);
      }
      if (kDebugMode) {
        debugPrint('LocationService.resolveCurrentPlace: $e\n$st');
      }
      return const LocationResolveResult.failure(LocationFailure.unavailable);
    }
  }

  Future<LocationResolveResult> _resolveCore({required bool preferFresh}) async {
    if (!preferFresh) {
      final cached = _readMemory();
      if (cached != null) {
        return LocationResolveResult.success(cached);
      }
    }

    final last = await Geolocator.getLastKnownPosition();
    final lastAge = _positionAge(last);

    if (!preferFresh &&
        last != null &&
        lastAge <= _trustLastPositionTtl) {
      final place = await _labelFor(
        last.latitude,
        last.longitude,
        approximate: false,
      );
      _remember(place);
      return LocationResolveResult.success(place);
    }

    final gps = await _fetchGpsQuick();
    if (gps != null) {
      final place = await _labelFor(
        gps.latitude,
        gps.longitude,
        approximate: false,
      );
      _remember(place);
      return LocationResolveResult.success(place);
    }

    if (last != null && lastAge <= _stalePositionTtl) {
      final place = await _labelFor(
        last.latitude,
        last.longitude,
        approximate: lastAge > _trustLastPositionTtl || gps == null,
      );
      if (!place.approximate) _remember(place);
      return LocationResolveResult.success(place);
    }

    if (gps != null) {
      final place = await _labelFor(
        gps.latitude,
        gps.longitude,
        approximate: false,
      );
      _remember(place);
      return LocationResolveResult.success(place);
    }

    return const LocationResolveResult.failure(LocationFailure.timeout);
  }

  Future<Position?> _fetchGpsQuick() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _quickGps,
      ).timeout(_gpsQuickWait);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<DiaryLocation?> _placeFromLastKnown({
    required Duration maxAge,
    required bool approximate,
  }) async {
    final last = await Geolocator.getLastKnownPosition();
    if (last == null || _positionAge(last) > maxAge) return null;
    return _labelFor(
      last.latitude,
      last.longitude,
      approximate: approximate,
    );
  }

  DiaryLocation? _readMemory() {
    if (_memoryPlace == null || _memoryAt == null) return null;
    if (_memoryPlace!.approximate) return null;
    if (DateTime.now().difference(_memoryAt!) > _memoryFreshTtl) {
      return null;
    }
    return _memoryPlace;
  }

  void _remember(DiaryLocation place) {
    if (place.approximate) return;
    _memoryPlace = place;
    _memoryAt = DateTime.now();
  }

  Duration _positionAge(Position? position) {
    if (position == null) return const Duration(days: 9999);
    final age = DateTime.now().difference(position.timestamp);
    return age.isNegative ? Duration.zero : age;
  }

  Future<DiaryLocation> _labelFor(
    double lat,
    double lng, {
    required bool approximate,
  }) async {
    final key = '${lat.toStringAsFixed(2)},${lng.toStringAsFixed(2)}';
    final cached = _geocodeCache[key];
    if (cached != null &&
        DateTime.now().difference(cached.at) < const Duration(hours: 24)) {
      return DiaryLocation(
        latitude: lat,
        longitude: lng,
        placeLabel: cached.label,
        approximate: approximate,
      );
    }

    try {
      final places = await placemarkFromCoordinates(lat, lng)
          .timeout(_geocodeWait);
      if (places.isNotEmpty) {
        final label = _formatPlacemark(places.first);
        if (label.isNotEmpty) {
          _geocodeCache[key] = _GeocodeCacheEntry(label, DateTime.now());
          return DiaryLocation(
            latitude: lat,
            longitude: lng,
            placeLabel: label,
            approximate: approximate,
          );
        }
      }
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint('LocationService._labelFor: geocode timeout');
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('LocationService._labelFor: $e\n$st');
    }

    return DiaryLocation(
      latitude: lat,
      longitude: lng,
      placeLabel: _coordinateLabel(lat, lng),
      approximate: approximate,
    );
  }

  String _formatPlacemark(Placemark p) {
    final province = _placePart(p.administrativeArea);
    final city = _placePart(p.locality).isNotEmpty
        ? _placePart(p.locality)
        : _placePart(p.subAdministrativeArea);

    if (province.isEmpty && city.isEmpty) return '';
    if (province.isEmpty) return city;
    if (city.isEmpty) return province;
    if (province == city ||
        province.contains(city) ||
        city.contains(province)) {
      return city;
    }
    return '$province · $city';
  }

  String _placePart(String? raw) {
    if (raw == null) return '';
    var name = raw.trim();
    if (name.isEmpty) return '';
    for (final suffix in ['特别行政区', '自治区', '自治州', '地区', '盟', '省', '市']) {
      if (name.endsWith(suffix) && name.length > suffix.length) {
        name = name.substring(0, name.length - suffix.length);
      }
    }
    return name.trim();
  }

  String _coordinateLabel(double lat, double lng) =>
      '${lat.toStringAsFixed(2)}°, ${lng.toStringAsFixed(2)}°';

  Future<void> openPermissionSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}

class _GeocodeCacheEntry {
  _GeocodeCacheEntry(this.label, this.at);

  final String label;
  final DateTime at;
}
