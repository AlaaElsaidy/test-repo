import 'package:alzcare/core/supabase/safe-zone-service.dart';
import 'package:alzcare/services/lobna/safe_zone_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects when patient is inside safe zone', () {
    final zone = SafeZone(
      id: 'zone1',
      patientId: 'patient1',
      name: 'Home',
      latitude: 30.0444,
      longitude: 31.2357,
      radiusMeters: 100,
      isActive: true,
    );
    final evaluation = SafeZoneMonitor.evaluate(
      latitude: 30.0445,
      longitude: 31.2358,
      zones: [zone],
    );

    expect(evaluation.isInside, isTrue);
    expect(evaluation.closestZone?.name, 'Home');
  });

  test('detects when patient leaves safe zone', () {
    final zone = SafeZone(
      id: 'zone1',
      patientId: 'patient1',
      name: 'Home',
      latitude: 30.0444,
      longitude: 31.2357,
      radiusMeters: 100,
      isActive: true,
    );
    final evaluation = SafeZoneMonitor.evaluate(
      latitude: 30.05,
      longitude: 31.25,
      zones: [zone],
    );

    expect(evaluation.isInside, isFalse);
    expect(evaluation.closestZone?.name, 'Home');
    expect(evaluation.distanceMeters, greaterThan(zone.radiusMeters));
  });
}

