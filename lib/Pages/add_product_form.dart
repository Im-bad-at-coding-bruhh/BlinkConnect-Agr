import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../Models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final ImagePicker _picker = ImagePicker();

  final List<String> _units = ['kg', 'pound', 'gram'];
  final List<String> _fertilizerTypes = [
    'None',
    'Organic',
    'Chemical',
  ];
  final List<String> _pesticideTypes = [
    'None',
    'Organic',
    'Chemical',
  ];
  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Grains',
    'Dairy',
    'Meat',
    'Poultry',
    'Seafood',
    'Other',
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
        final now = DateTime.now();
        final product = Product(
          id: '', // This will be set by Firestore
          farmerId: widget.farmerId,
          farmerName: widget.username,
          productName: _nameController.text,
          category: _selectedCategory,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          currentPrice: double.parse(_priceController.text),
          region: 'Default', // Set a default region
          status: 'available',
          createdAt: now,
          updatedAt: now,
          images: _selectedImages, // Use the base64 strings directly
          quantity: double.parse(_quantityController.text),
          unit: _selectedUnit,
          isNegotiable: _isNegotiable,
          fertilizerType: _selectedFertilizerType,
          pesticideType: _selectedPesticideType,
        );

        widget.onProductAdded(product);
        Navigator.of(context).pop();
      } catch (e) {
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
                          labelText: 'Price',
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
                        style: GoogleFonts.poppins(
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a quantity';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
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
                      const SizedBox(height: 16),
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
