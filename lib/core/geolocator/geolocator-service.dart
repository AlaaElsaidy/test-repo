import 'package:geolocator/geolocator.dart';

class LocationResult {
  final Position? position;
  final String? error;

  LocationResult({this.position, this.error});
}

Future<LocationResult> getCurrentLocation() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult(error: "Location permission denied by user");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationResult(
          error:
              "Location permission permanently denied. Enable it from settings");
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult(error: "Location services are disabled");
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    return LocationResult(position: position);
  } catch (e) {
    return LocationResult(error: "Unknown error: $e");
  }
}
