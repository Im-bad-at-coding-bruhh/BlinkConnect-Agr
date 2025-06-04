import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Get user's current position
  Future<Position> getCurrentPosition() async {
    print('Checking location services...');
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('Location services enabled: $serviceEnabled');

    if (!serviceEnabled) {
      print('Location services are disabled, requesting to enable...');
      // Request to enable location services
      serviceEnabled = await Geolocator.openLocationSettings();
      if (!serviceEnabled) {
        throw Exception(
            'Location services are disabled. Please enable location services in your device settings.');
      }
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    print('Current permission status: $permission');

    if (permission == LocationPermission.denied) {
      print('Requesting location permission...');
      permission = await Geolocator.requestPermission();
      print('Permission after request: $permission');

      if (permission == LocationPermission.denied) {
        throw Exception(
            'Location permissions are denied. Please enable location permissions in your device settings.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permission permanently denied, opening app settings...');
      await Geolocator.openAppSettings();
      throw Exception(
          'Location permissions are permanently denied. Please enable location permissions in your device settings.');
    }

    print('Getting current position...');
    // Get the current position
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      print('Got position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Error getting position: $e');
      throw Exception(
          'Could not get your location. Please try again or select your region manually.');
    }
  }

  // Get continent from coordinates
  Future<String> getContinentFromCoordinates(
      double latitude, double longitude) async {
    print('Getting continent for coordinates: $latitude, $longitude');
    try {
      // Get placemarks from coordinates
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      print('Got placemarks: ${placemarks.length}');

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks[0];
        final String? country = place.country;
        print('Detected country: $country');

        // Map country to continent
        if (country != null) {
          final continent = _getContinentFromCountry(country);
          print('Mapped to continent: $continent');
          return continent;
        }
      }

      print('Could not determine continent, returning Unknown');
      return 'Unknown';
    } catch (e) {
      print('Error getting continent: $e');
      return 'Unknown';
    }
  }

  // Helper function to map countries to continents
  String _getContinentFromCountry(String country) {
    // This is a simplified mapping. You might want to expand this
    final Map<String, String> countryToContinent = {
      // Africa
      'Nigeria': 'Africa',
      'South Africa': 'Africa',
      'Kenya': 'Africa',
      'Egypt': 'Africa',
      'Ghana': 'Africa',
      'Ethiopia': 'Africa',
      'Morocco': 'Africa',
      'Tanzania': 'Africa',
      'Uganda': 'Africa',
      'Algeria': 'Africa',

      // Europe
      'United Kingdom': 'Europe',
      'France': 'Europe',
      'Germany': 'Europe',
      'Italy': 'Europe',
      'Spain': 'Europe',
      'Netherlands': 'Europe',
      'Belgium': 'Europe',
      'Sweden': 'Europe',
      'Poland': 'Europe',
      'Greece': 'Europe',

      // Asia
      'China': 'Asia',
      'India': 'Asia',
      'Japan': 'Asia',
      'South Korea': 'Asia',
      'Indonesia': 'Asia',
      'Malaysia': 'Asia',
      'Thailand': 'Asia',
      'Vietnam': 'Asia',
      'Philippines': 'Asia',
      'Singapore': 'Asia',

      // North America
      'United States': 'North America',
      'Canada': 'North America',
      'Mexico': 'North America',
      'Costa Rica': 'North America',
      'Panama': 'North America',
      'Jamaica': 'North America',
      'Cuba': 'North America',
      'Haiti': 'North America',
      'Dominican Republic': 'North America',
      'Guatemala': 'North America',

      // South America
      'Brazil': 'South America',
      'Argentina': 'South America',
      'Colombia': 'South America',
      'Peru': 'South America',
      'Chile': 'South America',
      'Venezuela': 'South America',
      'Ecuador': 'South America',
      'Bolivia': 'South America',
      'Paraguay': 'South America',
      'Uruguay': 'South America',

      // Oceania
      'Australia': 'Oceania',
      'New Zealand': 'Oceania',
      'Fiji': 'Oceania',
      'Papua New Guinea': 'Oceania',
      'Samoa': 'Oceania',
      'Tonga': 'Oceania',
      'Vanuatu': 'Oceania',
      'Solomon Islands': 'Oceania',
      'Micronesia': 'Oceania',
      'Palau': 'Oceania',
    };

    return countryToContinent[country] ?? 'Unknown';
  }
}
