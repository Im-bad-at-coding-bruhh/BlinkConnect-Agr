import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../Models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class AddProductForm extends StatefulWidget {
  final bool isDarkMode;
  final String defaultDescription;
  final Function(Product) onProductAdded;
  final String farmerId;
  final String username;

  const AddProductForm({
    Key? key,
    required this.isDarkMode,
    required this.defaultDescription,
    required this.onProductAdded,
    required this.farmerId,
    required this.username,
  }) : super(key: key);

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedUnit = 'kg';
  List<String> _selectedImages = [];
  List<String> _base64Images = [];
  bool _useDefaultDescription = true;
  bool _isNegotiable = false;
  bool _isUploading = false;
  String _selectedFertilizerType = 'None';
  String _selectedPesticideType = 'None';
  String _selectedCategory = 'Vegetables';
  String _selectedRipeningMethod = 'Natural';
  String _selectedPreservationMethod = 'None';
  String _selectedDryingMethod = 'Sun Dried';
  String _selectedStorageType = 'Sack';
  bool _isWeedControlUsed = false;
  // Dairy specific fields
  String _selectedAnimalFeedType = 'Natural (Grass-fed)';
  String _selectedMilkCoolingMethod = 'Chilled';
  bool _isAntibioticsUsed = false;
  String _selectedMilkingMethod = 'Manual';
  // Meat specific fields
  String _selectedSlaughterMethod = 'Manual';
  String _selectedRearingSystem = 'Free-range';
  // Seeds specific fields
  String _selectedSeedType = 'Open-pollinated';
  bool _isChemicallyTreated = false;
  bool _isCertified = false;
  String _selectedSeedStorageMethod = 'Airtight';
  final ImagePicker _picker = ImagePicker();

  // Poultry specific fields
  String _selectedPoultryFeedType = 'Natural (Free-range)';
  String _selectedPoultryRearingSystem = 'Free-range';
  bool _isPoultryAntibioticsUsed = false;
  bool _isGrowthBoostersUsed = false;
  String _selectedPoultrySlaughterMethod = 'Manual';
  bool _isPoultryVaccinated = false;

  // Seafood specific fields
  String _selectedSeafoodSource = 'Wild-caught';
  String _selectedSeafoodFeedingType = 'Natural';
  bool _isSeafoodAntibioticsUsed = false;
  bool _isWaterQualityManaged = false;
  String _selectedSeafoodPreservationMethod = 'Fresh';
  String _selectedSeafoodHarvestMethod = 'Traditional';

  final List<String> _units = ['kg', 'pound', 'gram'];
  final List<String> _fertilizerTypes = [
    'None',
    'Natural',
    'Artificial',
  ];
  final List<String> _pesticideTypes = [
    'None',
    'Used',
    'Not Used',
  ];
  final List<String> _ripeningMethods = [
    'Natural',
    'Artificial',
  ];
  final List<String> _preservationMethods = [
    'None',
    'Wax Coating',
    'Cold-Stored',
  ];
  final List<String> _dryingMethods = [
    'Sun Dried',
    'Mechanically Dried',
  ];
  final List<String> _storageTypes = [
    'Hermetic',
    'Sack',
    'Silo',
    'Not Stored',
  ];
  final List<String> _animalFeedTypes = [
    'Natural (Grass-fed)',
    'Mixed Feed',
    'Artificial/Processed Feed',
  ];
  final List<String> _milkCoolingMethods = [
    'Chilled',
    'Not Chilled',
  ];
  final List<String> _milkingMethods = [
    'Manual',
    'Machine',
  ];
  final List<String> _slaughterMethods = [
    'Manual',
    'Mechanized',
  ];
  final List<String> _rearingSystems = [
    'Free-range',
    'Confined',
    'Semi-free',
  ];
  final List<String> _seedTypes = [
    'Open-pollinated',
    'Hybrid',
    'GMO',
  ];
  final List<String> _seedStorageMethods = [
    'Airtight',
    'Sack',
    'Cold Storage',
  ];
  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Grains',
    'Dairy',
    'Meat',
    'Poultry',
    'Seafood',
    'Seeds',
  ];

  final List<String> _poultryFeedTypes = [
    'Natural (Free-range)',
    'Mixed Feed',
    'Commercial Feed',
  ];

  final List<String> _poultryRearingSystems = [
    'Free-range',
    'Cage',
    'Barn',
    'Organic',
  ];

  final List<String> _poultrySlaughterMethods = [
    'Manual',
    'Mechanized',
    'Halal',
  ];

  final List<String> _seafoodSources = [
    'Wild-caught',
    'Farmed',
  ];

  final List<String> _seafoodFeedingTypes = [
    'Natural',
    'Commercial Feed',
    'Mixed Feed',
  ];

  final List<String> _seafoodPreservationMethods = [
    'Fresh',
    'Frozen',
    'Dried',
    'Smoked',
  ];

  final List<String> _seafoodHarvestMethods = [
    'Traditional',
    'Modern',
    'Sustainable',
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.defaultDescription;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        setState(() {
          _selectedImages.add(base64String);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<String> _convertImageToBase64(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('Error converting image to base64: $e');
      throw 'Failed to convert image: $e';
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please add at least one product image')),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      try {
        // Get user data from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.farmerId)
            .get();

        if (!userDoc.exists) {
          throw 'User profile not found';
        }

        final userData = userDoc.data();
        if (userData == null) {
          throw 'User data is null';
        }

        print('Raw user data from Firestore: $userData');

        // Get username and region from user data
        final username = userData['username'] as String?;
        final region = userData['region'] as String?;

        print('Extracted username: $username');
        print('Extracted region: $region');

        if (username == null) {
          throw 'Username not found in user profile';
        }

        if (region == null) {
          throw 'Region not found in user profile';
        }

        final now = DateTime.now();
        // Build product data map dynamically based on category
        final Map<String, dynamic> productData = {
          'id': '',
          'farmerId': widget.farmerId,
          'farmerName': username,
          'productName': _nameController.text,
          'category': _selectedCategory,
          'description': _descriptionController.text,
          'price': double.parse(_priceController.text),
          'currentPrice': double.parse(_priceController.text),
          'region': region,
          'status': 'available',
          'createdAt': now,
          'updatedAt': now,
          'images': _selectedImages,
          'quantity': double.parse(_quantityController.text),
          'unit': _selectedUnit,
          'isNegotiable': _isNegotiable,
        };
        // Save ALL possible fields for every product, regardless of category
        productData['fertilizerType'] = _selectedFertilizerType;
        productData['pesticideType'] = _selectedPesticideType;
        productData['ripeningMethod'] = _selectedRipeningMethod;
        productData['preservationMethod'] = _selectedPreservationMethod;
        productData['dryingMethod'] = _selectedDryingMethod;
        productData['storageType'] = _selectedStorageType;
        productData['isWeedControlUsed'] = _isWeedControlUsed;
        productData['animalFeedType'] = _selectedAnimalFeedType;
        productData['milkCoolingMethod'] = _selectedMilkCoolingMethod;
        productData['isAntibioticsUsed'] = _isAntibioticsUsed;
        productData['milkingMethod'] = _selectedMilkingMethod;
        productData['slaughterMethod'] = _selectedSlaughterMethod;
        productData['rearingSystem'] = _selectedRearingSystem;
        productData['seedType'] = _selectedSeedType;
        productData['isChemicallyTreated'] = _isChemicallyTreated;
        productData['isCertified'] = _isCertified;
        productData['seedStorageMethod'] = _selectedSeedStorageMethod;
        productData['poultryFeedType'] = _selectedPoultryFeedType;
        productData['poultryRearingSystem'] = _selectedPoultryRearingSystem;
        productData['isPoultryAntibioticsUsed'] = _isPoultryAntibioticsUsed;
        productData['isGrowthBoostersUsed'] = _isGrowthBoostersUsed;
        productData['poultrySlaughterMethod'] = _selectedPoultrySlaughterMethod;
        productData['isPoultryVaccinated'] = _isPoultryVaccinated;
        productData['seafoodSource'] = _selectedSeafoodSource;
        productData['seafoodFeedingType'] = _selectedSeafoodFeedingType;
        productData['isSeafoodAntibioticsUsed'] = _isSeafoodAntibioticsUsed;
        productData['isWaterQualityManaged'] = _isWaterQualityManaged;
        productData['seafoodPreservationMethod'] =
            _selectedSeafoodPreservationMethod;
        productData['seafoodHarvestMethod'] = _selectedSeafoodHarvestMethod;
        // Create product object
        final product = Product.fromMap('', productData);
        widget.onProductAdded(product);
        Navigator.of(context).pop();
      } catch (e) {
        print('Error creating product: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor:
          widget.isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Add New Product',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Product Images *',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(At least 1 required)',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: widget.isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C5DD3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.add_photo_alternate,
                                    color: Colors.white),
                                label: Text(
                                  'Add Image',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_selectedImages.isNotEmpty)
                            Container(
                              height: 120,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            image: DecorationImage(
                                              image: MemoryImage(
                                                base64Decode(
                                                    _selectedImages[index]),
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _removeImage(index),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Product Name',
                          labelStyle: GoogleFonts.poppins(
                            color: widget.isDarkMode
                                ? Colors.white70
                                : Colors.black54,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: widget.isDarkMode
                                  ? Colors.white30
                                  : Colors.black26,
                            ),
                          ),
                        ),
                        style: GoogleFonts.poppins(
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a product name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Price/Kg',
                          labelStyle: GoogleFonts.poppins(
                            color: widget.isDarkMode
                                ? Colors.white70
                                : Colors.black54,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: widget.isDarkMode
                                  ? Colors.white30
                                  : Colors.black26,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a price';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid price';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          labelStyle: GoogleFonts.poppins(
                            color: widget.isDarkMode
                                ? Colors.white70
                                : Colors.black54,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: widget.isDarkMode
                                  ? Colors.white30
                                  : Colors.black26,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: GoogleFonts.poppins(
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a quantity';
                          }
                          final intValue = int.tryParse(value);
                          if (intValue == null || intValue <= 0) {
                            return 'Please enter a valid whole number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          labelStyle: GoogleFonts.poppins(
                            color: widget.isDarkMode
                                ? Colors.white70
                                : Colors.black54,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: widget.isDarkMode
                                  ? Colors.white30
                                  : Colors.black26,
                            ),
                          ),
                        ),
                        items: _units.map((unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(
                              unit,
                              style: GoogleFonts.poppins(
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedUnit = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: GoogleFonts.poppins(
                            color: widget.isDarkMode
                                ? Colors.white70
                                : Colors.black54,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: widget.isDarkMode
                                  ? Colors.white30
                                  : Colors.black26,
                            ),
                          ),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(
                              category,
                              style: GoogleFonts.poppins(
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                      ),
                      if (_selectedCategory == 'Fruits') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedRipeningMethod,
                          decoration: InputDecoration(
                            labelText: 'Ripening Method',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _ripeningMethods.map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Text(
                                method,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedRipeningMethod = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedPreservationMethod,
                          decoration: InputDecoration(
                            labelText: 'Preservation Method',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _preservationMethods.map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Text(
                                method,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedPreservationMethod = value;
                              });
                            }
                          },
                        ),
                      ],
                      if (_selectedCategory == 'Grains') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedDryingMethod,
                          decoration: InputDecoration(
                            labelText: 'Post-Harvest Drying',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _dryingMethods.map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Text(
                                method,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedDryingMethod = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedStorageType,
                          decoration: InputDecoration(
                            labelText: 'Storage Type',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _storageTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedStorageType = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: Text(
                            'Weed Control Used',
                            style: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          value: _isWeedControlUsed,
                          onChanged: (value) {
                            setState(() {
                              _isWeedControlUsed = value;
                            });
                          },
                        ),
                      ],
                      if (_selectedCategory == 'Dairy') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedAnimalFeedType,
                          decoration: InputDecoration(
                            labelText: 'Animal Feed Type',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _animalFeedTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedAnimalFeedType = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedMilkCoolingMethod,
                          decoration: InputDecoration(
                            labelText: 'Milk Cooling/Preservation',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _milkCoolingMethods.map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Text(
                                method,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedMilkCoolingMethod = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: Text(
                            'Antibiotics Used',
                            style: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          value: _isAntibioticsUsed,
                          onChanged: (value) {
                            setState(() {
                              _isAntibioticsUsed = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedMilkingMethod,
                          decoration: InputDecoration(
                            labelText: 'Milking Method',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _milkingMethods.map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Text(
                                method,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedMilkingMethod = value;
                              });
                            }
                          },
                        ),
                      ],
                      if (_selectedCategory == 'Meat') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedAnimalFeedType,
                          decoration: InputDecoration(
                            labelText: 'Animal Feed Type',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _animalFeedTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedAnimalFeedType = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: Text(
                            'Antibiotic Use',
                            style: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          value: _isAntibioticsUsed,
                          onChanged: (value) {
                            setState(() {
                              _isAntibioticsUsed = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedSlaughterMethod,
                          decoration: InputDecoration(
                            labelText: 'Slaughter Method',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _slaughterMethods.map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Text(
                                method,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedSlaughterMethod = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedRearingSystem,
                          decoration: InputDecoration(
                            labelText: 'Rearing System',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _rearingSystems.map((system) {
                            return DropdownMenuItem(
                              value: system,
                              child: Text(
                                system,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedRearingSystem = value;
                              });
                            }
                          },
                        ),
                      ],
                      if (_selectedCategory == 'Seeds') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedSeedType,
                          decoration: InputDecoration(
                            labelText: 'Seed Type',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _seedTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedSeedType = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: Text(
                            'Chemically Treated',
                            style: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          value: _isChemicallyTreated,
                          onChanged: (value) {
                            setState(() {
                              _isChemicallyTreated = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedSeedStorageMethod,
                          decoration: InputDecoration(
                            labelText: 'Storage Method',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _seedStorageMethods.map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Text(
                                method,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedSeedStorageMethod = value;
                              });
                            }
                          },
                        ),
                      ],
                      if (_selectedCategory == 'Poultry') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedPoultryFeedType,
                          decoration: InputDecoration(
                            labelText: 'Feed Type',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _poultryFeedTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedPoultryFeedType = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedPoultryRearingSystem,
                          decoration: InputDecoration(
                            labelText: 'Rearing System',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _poultryRearingSystems.map((system) {
                            return DropdownMenuItem(
                              value: system,
                              child: Text(
                                system,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedPoultryRearingSystem = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: Text(
                            'Antibiotics Used',
                            style: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          value: _isPoultryAntibioticsUsed,
                          onChanged: (value) {
                            setState(() {
                              _isPoultryAntibioticsUsed = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: Text(
                            'Growth Boosters Used',
                            style: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          value: _isGrowthBoostersUsed,
                          onChanged: (value) {
                            setState(() {
                              _isGrowthBoostersUsed = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedPoultrySlaughterMethod,
                          decoration: InputDecoration(
                            labelText: 'Slaughter Method',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _poultrySlaughterMethods.map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Text(
                                method,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedPoultrySlaughterMethod = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: Text(
                            'Vaccinated',
                            style: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          value: _isPoultryVaccinated,
                          onChanged: (value) {
                            setState(() {
                              _isPoultryVaccinated = value;
                            });
                          },
                        ),
                      ],
                      if (_selectedCategory == 'Seafood') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedSeafoodSource,
                          decoration: InputDecoration(
                            labelText: 'Source',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _seafoodSources.map((source) {
                            return DropdownMenuItem(
                              value: source,
                              child: Text(
                                source,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedSeafoodSource = value;
                              });
                            }
                          },
                        ),
                        if (_selectedSeafoodSource == 'Farmed') ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedSeafoodFeedingType,
                            decoration: InputDecoration(
                              labelText: 'Feeding Type',
                              labelStyle: GoogleFonts.poppins(
                                color: widget.isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: widget.isDarkMode
                                      ? Colors.white30
                                      : Colors.black26,
                                ),
                              ),
                            ),
                            items: _seafoodFeedingTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type,
                                  style: GoogleFonts.poppins(
                                    color: widget.isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedSeafoodFeedingType = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: Text(
                              'Antibiotics Used',
                              style: GoogleFonts.poppins(
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            value: _isSeafoodAntibioticsUsed,
                            onChanged: (value) {
                              setState(() {
                                _isSeafoodAntibioticsUsed = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: Text(
                              'Water Quality Managed',
                              style: GoogleFonts.poppins(
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            value: _isWaterQualityManaged,
                            onChanged: (value) {
                              setState(() {
                                _isWaterQualityManaged = value;
                              });
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedSeafoodPreservationMethod,
                          decoration: InputDecoration(
                            labelText: 'Preservation Method',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _seafoodPreservationMethods.map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Text(
                                method,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedSeafoodPreservationMethod = value;
                              });
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (_selectedCategory != 'Dairy' &&
                          _selectedCategory != 'Meat' &&
                          _selectedCategory != 'Poultry' &&
                          _selectedCategory != 'Seafood') ...[
                        DropdownButtonFormField<String>(
                          value: _selectedFertilizerType,
                          decoration: InputDecoration(
                            labelText: 'Fertilizer Type',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _fertilizerTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedFertilizerType = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedPesticideType,
                          decoration: InputDecoration(
                            labelText: 'Pesticide Type',
                            labelStyle: GoogleFonts.poppins(
                              color: widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: widget.isDarkMode
                                    ? Colors.white30
                                    : Colors.black26,
                              ),
                            ),
                          ),
                          items: _pesticideTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedPesticideType = value;
                              });
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text(
                          'Allow Negotiation',
                          style: GoogleFonts.poppins(
                            color: widget.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        value: _isNegotiable,
                        onChanged: (value) {
                          setState(() {
                            _isNegotiable = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: GoogleFonts.poppins(
                            color: widget.isDarkMode
                                ? Colors.white70
                                : Colors.black54,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: widget.isDarkMode
                                  ? Colors.white30
                                  : Colors.black26,
                            ),
                          ),
                        ),
                        style: GoogleFonts.poppins(
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                color: widget.isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: ElevatedButton(
                                onPressed: _isUploading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C5DD3),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isUploading
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Uploading Images...',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        'Add Product',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
