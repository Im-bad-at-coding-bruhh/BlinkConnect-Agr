import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class LocationService {
  bool _isDisposed = false;

  void dispose() {
    print('LocationService: Disposing...');
    _isDisposed = true;
  }

  // Get user's current position
  Future<Position?> getCurrentLocation() async {
    if (_isDisposed) {
      print('LocationService: Service is disposed, skipping location request');
      return null;
    }

    print('LocationService: Getting current location...');
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('Latitude: ${position.latitude}, Longitude: ${position.longitude}');
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Get continent from coordinates
  Future<String> getContinentFromCoordinates(
      double latitude, double longitude) async {
    print('Getting continent for coordinates: $latitude, $longitude');
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks[0];
        final String? country = place.country;
        if (country != null) {
          return _getContinentFromCountry(country);
        }
      }
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

  Future<bool> requestLocationPermission() async {
    if (_isDisposed) {
      print(
          'LocationService: Service is disposed, skipping permission request');
      return false;
    }

    print('LocationService: Starting permission request...');
    try {
      // Check if location services are enabled
      print('LocationService: Checking if location services are enabled...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('LocationService: Location services enabled: $serviceEnabled');

      if (!serviceEnabled) {
        print('LocationService: Location services are disabled');
        // Request to enable location services
        serviceEnabled = await Geolocator.openAppSettings();
        if (!serviceEnabled) {
          print('LocationService: User did not enable location services');
          return false;
        }
      }

      // Request location permission using Geolocator
      print('LocationService: Requesting location permission...');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('LocationService: Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('LocationService: Location permission permanently denied');
        return false;
      }

      print('LocationService: Location permission granted');
      return true;
    } catch (e) {
      print('LocationService: Error requesting location permission: $e');
      return false;
    }
  }
}
