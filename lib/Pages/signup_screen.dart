import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/Services/location_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final LocationService _locationService = LocationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _userContinent = 'Unknown';
  bool _isLoadingLocation = false;
  bool _isFarmer = false;

  final List<String> _continents = [
    'Africa',
    'Europe',
    'Asia',
    'North America',
    'South America',
  ];

  @override
  void initState() {
    super.initState();
    print('SignupScreen initialized');
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    print('Getting user location...');
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      print('Got position: ${position.latitude}, ${position.longitude}');

      final continent = await _locationService.getContinentFromCoordinates(
        position.latitude,
        position.longitude,
      );
      print('Detected continent: $continent');

      setState(() {
        _userContinent = continent;
        _isLoadingLocation = false;
      });
      print('Updated region to: $_userContinent');
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoadingLocation = false;
      });
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Could not get your location. Please select your region manually.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _signUp() async {
    print('Starting signup process...');
    print('Current region: $_userContinent');

    // First check if all required fields are filled
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      print('Missing required fields');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Then check if region is selected
    if (_userContinent == 'Unknown') {
      print('No region selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your region to continue'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      print('Creating user account...');
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      print('User created with ID: ${userCredential.user!.uid}');

      // Save user data to Firestore
      final userData = {
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'isFarmer': _isFarmer,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'region': _userContinent,
      };
      print('Saving user data: $userData');

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);
      print('User data saved successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print('Error during signup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... your existing form fields ...

              // Region Selection Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        _userContinent == 'Unknown' ? Colors.red : Colors.green,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Region Selection *',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_userContinent != 'Unknown')
                          Text(
                            '($_userContinent)',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingLocation)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value:
                            _userContinent == 'Unknown' ? null : _userContinent,
                        items: _continents.map((String continent) {
                          return DropdownMenuItem<String>(
                            value: continent,
                            child: Text(continent),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          print('Region selected: $newValue');
                          if (newValue != null) {
                            setState(() {
                              _userContinent = newValue;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          hintText: 'Select your region',
                          errorText: _userContinent == 'Unknown'
                              ? 'Region is required'
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value == 'Unknown') {
                            return 'Please select a region';
                          }
                          return null;
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sign Up Button
              ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _userContinent == 'Unknown'
                      ? Colors.grey
                      : Theme.of(context).primaryColor,
                ),
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
