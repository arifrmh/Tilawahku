import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tilawahku/features/prayer/data/device_location.dart';
import 'package:tilawahku/features/prayer/domain/prayer_models.dart';

Position _position(double lat, double lon) => Position(
  longitude: lon,
  latitude: lat,
  timestamp: DateTime.utc(2026, 1, 1),
  accuracy: 10,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  test('concurrent locate calls request location permission only once', () async {
    var requestCount = 0;
    final gate = Completer<LocationPermission>();
    final provider = GeolocatorDeviceLocation(
      isServiceEnabled: () async => true,
      checkPermission: () async => LocationPermission.denied,
      requestPermission: () {
        requestCount += 1;
        return gate.future;
      },
      readPosition: (_) async => _position(-6.2, 106.8),
    );

    final first = provider.locate();
    final second = provider.locate();
    await Future<void>.delayed(Duration.zero);
    gate.complete(LocationPermission.whileInUse);

    final results = await Future.wait([first, second]);
    expect(requestCount, 1);
    expect(results.first.latitude, -6.2);
    expect(results.last.longitude, 106.8);
  });

  test('already granted permission skips requestPermission', () async {
    var requestCount = 0;
    final provider = GeolocatorDeviceLocation(
      isServiceEnabled: () async => true,
      checkPermission: () async => LocationPermission.whileInUse,
      requestPermission: () async {
        requestCount += 1;
        return LocationPermission.whileInUse;
      },
      readPosition: (_) async => _position(-7.8, 110.4),
    );

    final location = await provider.locate();
    expect(requestCount, 0);
    expect(location.source, LocationSource.gps);
    expect(location.latitude, -7.8);
  });

  test('timeout falls back to last known position when available', () async {
    final provider = GeolocatorDeviceLocation(
      isServiceEnabled: () async => true,
      checkPermission: () async => LocationPermission.whileInUse,
      readPosition: (_) async => throw TimeoutException('gps timeout'),
      readLastKnownPosition: () async => _position(-6.9, 107.6),
    );

    final location = await provider.locate();
    expect(location.latitude, -6.9);
    expect(location.longitude, 107.6);
  });
}
