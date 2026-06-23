import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  /// Converts a given Pincode (assumed India) into a Latitude/Longitude coordinate using OpenStreetMap's Nominatim API.
  static Future<LatLng?> getCoordinatesFromPincode(String pincode) async {
    try {
      // We explicitly search for country=India to help the geocoder accurately locate the 6-digit postal code.
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?postalcode=$pincode&country=India&format=json&limit=1');
      
      // Nominatim requires a User-Agent header to prevent abuse.
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'ClickAndFixApp/1.0 (contact@clickandfix.com)',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'].toString());
          final lon = double.tryParse(data[0]['lon'].toString());
          if (lat != null && lon != null && lat.isFinite && lon.isFinite) {
            return LatLng(lat, lon);
          }
        }
      }
      return null;
    } catch (e) {
      print("Geocoding Error: $e");
      return null;
    }
  }
}
