import 'dart:math';

import '../../core/supabase/safe-zone-service.dart';

class SafeZoneEvaluation {
  final bool isInside;
  final SafeZone? closestZone;
  final double? distanceMeters;

  const SafeZoneEvaluation({
    required this.isInside,
    this.closestZone,
    this.distanceMeters,
  });
}

class SafeZoneMonitor {
  static SafeZoneEvaluation evaluate({
    required double latitude,
    required double longitude,
    required List<SafeZone> zones,
  }) {
    if (zones.isEmpty) {
      return const SafeZoneEvaluation(isInside: true);
    }

    SafeZone? closest;
    double? closestDistance;
    bool inside = false;

    for (final zone in zones.where((z) => z.isActive)) {
      final distance = _distanceMeters(
        latitude,
        longitude,
        zone.latitude,
        zone.longitude,
      );
      if (closest == null || distance < closestDistance!) {
        closest = zone;
        closestDistance = distance;
      }
      if (distance <= zone.radiusMeters) {
        inside = true;
        break;
      }
    }

    return SafeZoneEvaluation(
      isInside: inside,
      closestZone: closest,
      distanceMeters: closestDistance,
    );
  }

  static double _distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _deg2rad(double d) => d * pi / 180.0;
}

