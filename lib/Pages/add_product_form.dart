import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
  bool _useDefaultDescription = true;
  bool _isNegotiable = false;
  String _selectedFertilizerType = 'None';
  String _selectedPesticideType = 'None';
  String _selectedCategory = 'Vegetables';

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
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImages.add(image.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
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
        images: _selectedImages,
        quantity: double.parse(_quantityController.text),
        unit: _selectedUnit,
        isNegotiable: _isNegotiable,
        fertilizerType: _selectedFertilizerType,
        pesticideType: _selectedPesticideType,
      );

      widget.onProductAdded(product);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor:
          widget.isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Product',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product Images',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            widget.isDarkMode ? Colors.white30 : Colors.black26,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _selectedImages.isEmpty
                        ? Center(
                            child: TextButton.icon(
                              onPressed: _pickImage,
                              icon: Icon(
                                Icons.add_photo_alternate,
                                color: widget.isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                              label: Text(
                                'Add Images',
                                style: GoogleFonts.poppins(
                                  color: widget.isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _selectedImages.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TextButton.icon(
                                    onPressed: _pickImage,
                                    icon: Icon(
                                      Icons.add_photo_alternate,
                                      color: widget.isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                    label: Text(
                                      'Add More',
                                      style: GoogleFonts.poppins(
                                        color: widget.isDarkMode
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: FileImage(
                                              File(_selectedImages[index])),
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
                                        onPressed: () => _removeImage(index),
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
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          widget.isDarkMode ? Colors.white30 : Colors.black26,
                    ),
                  ),
                ),
                style: GoogleFonts.poppins(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
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
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          widget.isDarkMode ? Colors.white30 : Colors.black26,
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
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
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          widget.isDarkMode ? Colors.white30 : Colors.black26,
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
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
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          widget.isDarkMode ? Colors.white30 : Colors.black26,
                    ),
                  ),
                ),
                items: _units.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(
                      unit,
                      style: GoogleFonts.poppins(
                        color:
                            widget.isDarkMode ? Colors.white : Colors.black87,
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
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          widget.isDarkMode ? Colors.white30 : Colors.black26,
                    ),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: GoogleFonts.poppins(
                        color:
                            widget.isDarkMode ? Colors.white : Colors.black87,
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
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          widget.isDarkMode ? Colors.white30 : Colors.black26,
                    ),
                  ),
                ),
                items: _fertilizerTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type,
                      style: GoogleFonts.poppins(
                        color:
                            widget.isDarkMode ? Colors.white : Colors.black87,
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
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          widget.isDarkMode ? Colors.white30 : Colors.black26,
                    ),
                  ),
                ),
                items: _pesticideTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type,
                      style: GoogleFonts.poppins(
                        color:
                            widget.isDarkMode ? Colors.white : Colors.black87,
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
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
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
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          widget.isDarkMode ? Colors.white30 : Colors.black26,
                    ),
                  ),
                ),
                style: GoogleFonts.poppins(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
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
                        color:
                            widget.isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5DD3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Add Product',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
