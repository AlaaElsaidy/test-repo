import 'package:geocoding/geocoding.dart';

Future<String> getAddressFromLatLng(double lat, double lng) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isEmpty) return "No address found for these coordinates";

    Placemark place = placemarks[0];
    String street = place.street ?? '';
    String subLocality = place.subLocality ?? '';
    String locality = place.locality ?? '';
    String country = place.country ?? '';
    String administrativeArea = place.administrativeArea ?? '';
    String address = [
      street,
      subLocality,
      locality,
      administrativeArea,
      country
    ].where((e) => e.isNotEmpty).join(', ');

    return address.isEmpty ? "Address not available" : address;
  } catch (e) {
    return "Failed to get address";
  }
}
