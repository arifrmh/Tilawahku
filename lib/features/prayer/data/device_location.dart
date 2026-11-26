import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/prayer_models.dart';

enum LocationFailureKind {
  serviceDisabled(
    'Lokasi perangkat belum aktif.',
    'Aktifkan layanan lokasi, lalu coba lagi.',
  ),
  permissionDenied(
    'Izin lokasi ditolak.',
    'Anda masih bisa memasukkan kota atau koordinat secara manual.',
  ),
  permissionDeniedForever(
    'Izin lokasi dicabut permanen.',
    'Buka pengaturan aplikasi dan izinkan akses lokasi, atau isi lokasi manual.',
  ),
  permissionUnableToDetermine(
    'Status izin lokasi tidak dapat dibaca.',
    'Coba lagi, atau isi lokasi manual.',
  ),
  timeout(
    'Permintaan lokasi melebihi batas waktu.',
    'Coba lagi di dekat jendela atau area terbuka.',
  ),
  unavailable(
    'Perangkat tidak memberikan posisi.',
    'Peramban atau perangkat menolak memberi lokasi; gunakan input manual.',
  );

  const LocationFailureKind(this.message, this.suggestion);

  final String message;
  final String suggestion;
}

class LocationFailure implements Exception {
  const LocationFailure(this.kind);

  final LocationFailureKind kind;

  String get message => kind.message;

  String get suggestion => kind.suggestion;

  @override
  String toString() => kind.message;
}

/// Satu-satunya pintu pengambilan posisi perangkat untuk seluruh aplikasi.
abstract interface class DeviceLocationProvider {
  /// Melempar [LocationFailure], bukan `null`, agar layar bisa menampilkan
  /// alasan yang berbeda (izin mati, GPS mati, peramban menolak).
  Future<WorshipLocation> locate();
}

typedef PositionReader = Future<Position> Function(LocationSettings settings);

class GeolocatorDeviceLocation implements DeviceLocationProvider {
  const GeolocatorDeviceLocation({
    PositionReader? readPosition,
    Future<Position?> Function()? readLastKnownPosition,
    Future<bool> Function()? isServiceEnabled,
    Future<LocationPermission> Function()? checkPermission,
    Future<LocationPermission> Function()? requestPermission,
  }) : _readPosition = readPosition,
       _readLastKnownPosition = readLastKnownPosition,
       _isServiceEnabled = isServiceEnabled,
       _checkPermission = checkPermission,
       _requestPermission = requestPermission;

  static const Duration timeLimit = Duration(seconds: 15);
  static Future<LocationPermission>? _permissionInFlight;

  final PositionReader? _readPosition;
  final Future<Position?> Function()? _readLastKnownPosition;
  final Future<bool> Function()? _isServiceEnabled;
  final Future<LocationPermission> Function()? _checkPermission;
  final Future<LocationPermission> Function()? _requestPermission;

  Future<LocationPermission> _resolvePermission() {
    final existing = _permissionInFlight;
    if (existing != null) return existing;
    final pending = _checkAndRequestPermission();
    _permissionInFlight = pending;
    return pending.whenComplete(() {
      if (identical(_permissionInFlight, pending)) {
        _permissionInFlight = null;
      }
    });
  }

  Future<LocationPermission> _checkAndRequestPermission() async {
    final check = _checkPermission ?? Geolocator.checkPermission;
    var permission = await check();
    if (permission == LocationPermission.denied) {
      final request = _requestPermission ?? Geolocator.requestPermission;
      permission = await request();
    }
    return permission;
  }

  @override
  Future<WorshipLocation> locate() async {
    // Web tidak mendukung cek layanan/izin Geolocator; langsung minta posisi.
    if (!kIsWeb) {
      final serviceCheck =
          _isServiceEnabled ?? Geolocator.isLocationServiceEnabled;
      if (!await serviceCheck()) {
        throw const LocationFailure(LocationFailureKind.serviceDisabled);
      }
      final permission = await _resolvePermission();
      switch (permission) {
        case LocationPermission.denied:
          throw const LocationFailure(LocationFailureKind.permissionDenied);
        case LocationPermission.deniedForever:
          throw const LocationFailure(
            LocationFailureKind.permissionDeniedForever,
          );
        case LocationPermission.unableToDetermine:
          throw const LocationFailure(
            LocationFailureKind.permissionUnableToDetermine,
          );
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          break;
      }
    }

    final settings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: timeLimit,
    );
    final reader = _readPosition;
    try {
      final position = reader == null
          ? await Geolocator.getCurrentPosition(locationSettings: settings)
          : await reader(settings);
      return _toLocation(position);
    } on TimeoutException {
      // Fallback ke posisi terakhir agar lokasi tetap tersimpan di dalam ruangan.
      final lastKnown = await _tryLastKnownPosition();
      if (lastKnown != null) return _toLocation(lastKnown);
      throw const LocationFailure(LocationFailureKind.timeout);
    } on LocationServiceDisabledException {
      throw const LocationFailure(LocationFailureKind.serviceDisabled);
    } on PermissionDeniedException {
      throw const LocationFailure(LocationFailureKind.permissionDenied);
    } on Exception catch (error) {
      throw LocationFailure(
        _kindOfMessage('${error.runtimeType} $error') ??
            LocationFailureKind.unavailable,
      );
    }
  }

  Future<Position?> _tryLastKnownPosition() async {
    if (kIsWeb) return null;
    try {
      final fallback =
          _readLastKnownPosition ??
          (_readPosition == null ? Geolocator.getLastKnownPosition : null);
      if (fallback == null) return null;
      return await fallback();
    } on Object {
      return null;
    }
  }

  static WorshipLocation _toLocation(Position position) => WorshipLocation(
    name: 'Posisi perangkat',
    latitude: position.latitude,
    longitude: position.longitude,
    source: LocationSource.gps,
  );

  static LocationFailureKind? _kindOfMessage(String message) {
    final lowered = message.toLowerCase();
    if (lowered.contains('timeout') || lowered.contains('time limit')) {
      return LocationFailureKind.timeout;
    }
    if (lowered.contains('denied') || lowered.contains('permission')) {
      return LocationFailureKind.permissionDenied;
    }
    if (lowered.contains('service') || lowered.contains('disabled')) {
      return LocationFailureKind.serviceDisabled;
    }
    return null;
  }
}
