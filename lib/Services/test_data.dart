import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class TestData {
  // Mock user data
  static final Map<String, dynamic> mockUser = {
    'name': 'Test Farmer',
    'email': 'test@example.com',
    'isFarmer': true,
    'isVerified': true,
    'phoneNumber': '+1234567890',
    'address': '123 Farm Street, Countryside',
    'bio': 'Organic farmer with 10 years of experience',
  };

  // Mock product data
  static final List<Map<String, dynamic>> mockProducts = [
    {
      'name': 'Organic Apples',
      'price': 2.99,
      'description': 'Fresh organic apples from local farm',
      'farmerId': 'test_farmer_1',
      'farmerName': 'Test Farmer',
      'imageUrl': 'assets/images/apple.png',
      'category': 'Fruits',
      'tags': ['organic', 'fresh', 'local'],
      'rating': 4.5,
      'totalRatings': 10,
    },
    {
      'name': 'Fresh Carrots',
      'price': 1.99,
      'description': 'Organic carrots, freshly harvested',
      'farmerId': 'test_farmer_1',
      'farmerName': 'Test Farmer',
      'imageUrl': 'assets/images/carrot.png',
      'category': 'Vegetables',
      'tags': ['organic', 'fresh', 'root'],
      'rating': 4.0,
      'totalRatings': 8,
    },
  ];

  // Helper method to get a test image file
  static Future<File> getTestImage() async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final testImagePath = path.join(directory.path, 'test_image.jpg');

      // Check if the test image already exists
      final testImageFile = File(testImagePath);
      if (await testImageFile.exists()) {
        return testImageFile;
      }

      // If not, create a new test image
      final testImage = await _createTestImage();
      await testImageFile.writeAsBytes(testImage);
      return testImageFile;
    } catch (e) {
      throw 'Failed to create test image: $e';
    }
  }

  // Helper method to create a test image
  static Future<Uint8List> _createTestImage() async {
    try {
      // Load a default image from assets
      final ByteData data = await rootBundle.load('assets/images/apple.png');
      return data.buffer.asUint8List();
    } catch (e) {
      throw 'Failed to load test image from assets: $e';
    }
  }

  // Helper method to create test data in Firestore
  static Future<void> populateTestData() async {
    // This will be implemented when we have Firebase emulator running
    // For now, we'll just print a message
    print('Test data population is not implemented yet.');
  }

  // Helper method to get a list of test categories
  static List<String> getTestCategories() {
    return [
      'Fruits',
      'Vegetables',
      'Grains',
      'Dairy',
      'Meat',
      'Herbs',
      'Flowers',
      'Other',
    ];
  }

  // Helper method to get a list of common tags
  static List<String> getCommonTags() {
    return [
      'organic',
      'fresh',
      'local',
      'seasonal',
      'heirloom',
      'sustainable',
      'pesticide-free',
      'non-gmo',
    ];
  }
}
