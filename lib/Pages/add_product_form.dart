import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddProductForm extends StatefulWidget {
  final bool isDarkMode;
  final String defaultDescription;
  final Function(Map<String, dynamic>) onProductAdded;

  const AddProductForm({
    Key? key,
    required this.isDarkMode,
    required this.defaultDescription,
    required this.onProductAdded,
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
  String _selectedFertilizerType = 'Natural';
  String _selectedPesticideType = 'None';
  String _selectedCategory = 'Fruits';

  final List<String> _units = ['kg', 'pound', 'gram'];
  final List<String> _fertilizerTypes = ['Natural', 'Chemical', 'Mixed'];
  final List<String> _pesticideTypes = ['None', 'Natural', 'Chemical', 'Mixed'];
  final List<String> _categories = [
    'Fruits',
    'Vegetables',
    'Grains',
    'Dairy',
    'Meat',
    'Seeds',
    'Tools',
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
      final productData = {
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'quantity': _quantityController.text,
        'unit': _selectedUnit,
        'description': _descriptionController.text,
        'images': _selectedImages,
        'fertilizerType': _selectedFertilizerType,
        'pesticideType': _selectedPesticideType,
        'useDefaultDescription': _useDefaultDescription,
        'category': _selectedCategory,
      };

      widget.onProductAdded(productData);
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
                items:
                    _units.map((String unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(
                          unit,
                          style: GoogleFonts.poppins(
                            color:
                                widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedUnit = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Fertilizer Type',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color:
                      widget.isDarkMode
                          ? Colors.black.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isDarkMode ? Colors.white24 : Colors.black12,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFertilizerType,
                    isExpanded: true,
                    dropdownColor:
                        widget.isDarkMode
                            ? const Color(0xFF1A1A2E)
                            : Colors.white,
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    items:
                        _fertilizerTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedFertilizerType = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pesticide Type',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color:
                      widget.isDarkMode
                          ? Colors.black.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isDarkMode ? Colors.white24 : Colors.black12,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPesticideType,
                    isExpanded: true,
                    dropdownColor:
                        widget.isDarkMode
                            ? const Color(0xFF1A1A2E)
                            : Colors.white,
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    items:
                        _pesticideTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedPesticideType = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.defaultDescription != null)
                Row(
                  children: [
                    Checkbox(
                      value: _useDefaultDescription,
                      onChanged: (bool? value) {
                        setState(() {
                          _useDefaultDescription = value ?? false;
                          if (_useDefaultDescription) {
                            _descriptionController.text =
                                widget.defaultDescription!;
                          } else {
                            _descriptionController.clear();
                          }
                        });
                      },
                    ),
                    Text(
                      'Use default description',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color:
                            widget.isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              if (!_useDefaultDescription || widget.defaultDescription == null)
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: GoogleFonts.poppins(
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black54,
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
                    if (!_useDefaultDescription &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              Text(
                'Category',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
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
                items:
                    _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: GoogleFonts.poppins(
                            color:
                                widget.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Product Images',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color:
                            widget.isDarkMode
                                ? Colors.black.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              widget.isDarkMode
                                  ? Colors.white24
                                  : Colors.black12,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add_a_photo,
                          size: 28,
                          color:
                              widget.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_selectedImages.isNotEmpty)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              _selectedImages.asMap().entries.map((entry) {
                                final index = entry.key;
                                final image = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(File(image)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            color:
                                                widget.isDarkMode
                                                    ? Colors.white
                                                    : Colors.black87,
                                            size: 20,
                                          ),
                                          onPressed: () => _removeImage(index),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
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
                  const SizedBox(width: 16),
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
