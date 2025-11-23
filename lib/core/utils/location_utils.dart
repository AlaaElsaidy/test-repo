// lib/core/utils/location_utils.dart

import 'dart:math';

import '../models/tracking_models.dart';

/// حساب المسافة بين نقطتين باستخدام Haversine Formula
double calculateHaversineDistance({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  const earthRadius = 6371000.0; // بالمتر
  final dLat = _degreesToRadians(lat2 - lat1);
  final dLng = _degreesToRadians(lng2 - lng1);
  
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) *
          cos(_degreesToRadians(lat2)) *
          sin(dLng / 2) *
          sin(dLng / 2);
  
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

/// تحويل الدرجات إلى راديان
double _degreesToRadians(double degrees) => degrees * pi / 180.0;

/// التحقق مما إذا كانت النقطة داخل منطقة آمنة
bool isLocationInsideSafeZone({
  required double latitude,
  required double longitude,
  required SafeZone zone,
}) {
  final distance = calculateHaversineDistance(
    lat1: latitude,
    lng1: longitude,
    lat2: zone.latitude,
    lng2: zone.longitude,
  );
  return distance <= zone.radiusMeters;
}

/// البحث عن المنطقة الآمنة التي يوجد بها الموقع (إن وجدت)
SafeZone? findSafeZoneForLocation({
  required double latitude,
  required double longitude,
  required List<SafeZone> safeZones,
}) {
  for (final zone in safeZones) {
    if (!zone.isActive) continue;
    if (isLocationInsideSafeZone(
      latitude: latitude,
      longitude: longitude,
      zone: zone,
    )) {
      return zone;
    }
  }
  return null;
}

/// حساب المسافة الكلية بين مجموعة نقاط (تقريبي)
double calculateTotalDistance(List<({double lat, double lng})> points) {
  if (points.length < 2) return 0.0;
  
  double totalDistance = 0.0;
  for (int i = 0; i < points.length - 1; i++) {
    totalDistance += calculateHaversineDistance(
      lat1: points[i].lat,
      lng1: points[i].lng,
      lat2: points[i + 1].lat,
      lng2: points[i + 1].lng,
    );
  }
  
  return totalDistance;
}

/// حساب متوسط السرعة (م/ث)
double calculateAverageSpeed(
  double distanceInMeters,
  Duration duration,
) {
  if (duration.inSeconds == 0) return 0.0;
  return distanceInMeters / duration.inSeconds;
}

/// حساب الاتجاه بين نقطتين (بالدرجات)
double calculateBearing({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  final dLng = _degreesToRadians(lng2 - lng1);
  final y = sin(dLng) * cos(_degreesToRadians(lat2));
  final x = cos(_degreesToRadians(lat1)) * sin(_degreesToRadians(lat2)) -
      sin(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * cos(dLng);
  final bearing = atan2(y, x);
  return (_radiansToDegrees(bearing) + 360) % 360;
}

/// تحويل الراديان إلى درجات
double _radiansToDegrees(double radians) => radians * 180.0 / pi;

/// تنسيق المسافة للعرض
String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.toStringAsFixed(0)} م';
  }
  return '${(meters / 1000).toStringAsFixed(2)} كم';
}

/// تنسيق السرعة للعرض
String formatSpeed(double meterPerSecond) {
  final kmh = meterPerSecond * 3.6;
  return '${kmh.toStringAsFixed(1)} كم/س';
}

/// التحقق من وجود تغيير كبير في الموقع
bool hasSignificantLocationChange({
  required double oldLat,
  required double oldLng,
  required double newLat,
  required double newLng,
  double minDistanceMeters = 100.0,
}) {
  final distance = calculateHaversineDistance(
    lat1: oldLat,
    lng1: oldLng,
    lat2: newLat,
    lng2: newLng,
  );
  return distance >= minDistanceMeters;
}
