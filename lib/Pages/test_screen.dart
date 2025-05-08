import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/test_data.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();
  bool _isLoading = false;

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  Future<void> _handleAuthAction(Future<void> Function() action) async {
    _setLoading(true);
    try {
      await action();
      if (mounted) {
        _showSnackBar(context, 'Operation successful!');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        _setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test Screen'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTestSection(
                  'Authentication Tests',
                  [
                    _buildTestButton(
                      'Test Sign In',
                      () => _handleAuthAction(() async {
                        await _authService.signInWithEmailAndPassword(
                          'test@example.com',
                          'password123',
                        );
                      }),
                    ),
                    _buildTestButton(
                      'Test Register',
                      () => _handleAuthAction(() async {
                        await _authService.registerWithEmailAndPassword(
                          'newuser@example.com',
                          'password123',
                          'Test User',
                          true,
                        );
                      }),
                    ),
                    _buildTestButton(
                      'Test Sign Out',
                      () => _handleAuthAction(() async {
                        await _authService.signOut();
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTestSection(
                  'Product Tests',
                  [
                    _buildTestButton(
                      'Add Test Product',
                      () => _handleAuthAction(() async {
                        final testImage = await TestData.getTestImage();
                        await _productService.addProduct(
                          name: 'Test Product',
                          price: 9.99,
                          description: 'This is a test product',
                          farmerId: 'test_farmer_1',
                          farmerName: 'Test Farmer',
                          image: testImage,
                          category: 'Vegetables',
                          tags: ['organic', 'fresh'],
                        );
                      }),
                    ),
                    _buildTestButton(
                      'Get All Products',
                      () => _handleAuthAction(() async {
                        _productService.getProducts().listen(
                          (snapshot) {
                            if (mounted) {
                              _showSnackBar(
                                context,
                                'Found ${snapshot.docs.length} products',
                              );
                            }
                          },
                          onError: (e) {
                            if (mounted) {
                              _showSnackBar(
                                  context, 'Error getting products: $e');
                            }
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTestSection(String title, List<Widget> buttons) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...buttons,
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        child: Text(label),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
