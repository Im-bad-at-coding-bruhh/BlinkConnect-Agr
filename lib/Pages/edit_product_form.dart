import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProductForm extends StatefulWidget {
  final bool isDarkMode;
  final Product product;
  final Function(Product) onProductUpdated;

  const EditProductForm({
    Key? key,
    required this.isDarkMode,
    required this.product,
    required this.onProductUpdated,
  }) : super(key: key);

  @override
  State<EditProductForm> createState() => _EditProductFormState();
}

class _EditProductFormState extends State<EditProductForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late String _selectedUnit;
  late String _selectedFertilizerType;
  late String _selectedPesticideType;
  late String _selectedPesticideUse;
  late String _selectedRipeningMethod;
  late String _selectedPreservationMethod;
  late String _niche;
  bool _isLoading = false;

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

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _quantityController =
        TextEditingController(text: widget.product.quantity.toString());
    _priceController =
        TextEditingController(text: widget.product.price.toString());
    _selectedUnit = widget.product.unit;
    _selectedFertilizerType = widget.product.fertilizerType;
    _selectedPesticideType = widget.product.pesticideType;
    _selectedPesticideUse = widget.product.pesticideType;
    _selectedRipeningMethod = widget.product.ripeningMethod;
    _selectedPreservationMethod = widget.product.preservationMethod;
    _niche = widget.product.niche;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor:
          widget.isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Product',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                widget.product.productName,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: GoogleFonts.poppins(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: GoogleFonts.poppins(
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          widget.isDarkMode ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          widget.isDarkMode ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6C5DD3),
                    ),
                  ),
                  filled: true,
                  fillColor:
                      widget.isDarkMode ? Colors.black26 : Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$ ',
                  labelStyle: GoogleFonts.poppins(
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          widget.isDarkMode ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          widget.isDarkMode ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6C5DD3),
                    ),
                  ),
                  filled: true,
                  fillColor:
                      widget.isDarkMode ? Colors.black26 : Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Price must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(
                        color:
                            widget.isDarkMode ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        labelStyle: GoogleFonts.poppins(
                          color: widget.isDarkMode
                              ? Colors.white70
                              : Colors.black54,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.isDarkMode
                                ? Colors.white24
                                : Colors.black12,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.isDarkMode
                                ? Colors.white24
                                : Colors.black12,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6C5DD3),
                          ),
                        ),
                        filled: true,
                        fillColor: widget.isDarkMode
                            ? Colors.black26
                            : Colors.grey[50],
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
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            widget.isDarkMode ? Colors.white24 : Colors.black12,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedUnit,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        dropdownColor: widget.isDarkMode
                            ? const Color(0xFF1A1A2E)
                            : Colors.white,
                        style: GoogleFonts.poppins(
                          color:
                              widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                        items: _units.map((String unit) {
                          return DropdownMenuItem<String>(
                            value: unit,
                            child: Text(unit),
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (widget.product.category == 'Fruits') ...[
                DropdownButtonFormField<String>(
                  value: _selectedFertilizerType,
                  decoration: InputDecoration(
                    labelText: 'Fertilizer Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _fertilizerTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFertilizerType = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedPesticideType,
                  decoration: InputDecoration(
                    labelText: 'Pesticide Use',
                    border: OutlineInputBorder(),
                  ),
                  items: _pesticideTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPesticideType = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRipeningMethod,
                  decoration: InputDecoration(
                    labelText: 'Ripening Method',
                    border: OutlineInputBorder(),
                  ),
                  items: _ripeningMethods.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRipeningMethod = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedPreservationMethod,
                  decoration: InputDecoration(
                    labelText: 'Preservation Method',
                    border: OutlineInputBorder(),
                  ),
                  items: _preservationMethods.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPreservationMethod = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
              ],
              if (![
                'Fruits',
                'Grains',
                'Dairy',
                'Meat',
                'Poultry',
                'Seafood',
                'Seeds'
              ].contains(widget.product.category)) ...[
                TextFormField(
                  initialValue: widget.product.niche,
                  decoration: InputDecoration(
                    labelText: 'Niche',
                    labelStyle: GoogleFonts.poppins(
                      color:
                          widget.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _niche = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a niche';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });

                            try {
                              final wasSoldOut =
                                  widget.product.status == 'sold_out';
                              final newQuantity =
                                  double.parse(_quantityController.text);
                              final newStatus = wasSoldOut && newQuantity > 0
                                  ? 'restocked'
                                  : widget.product.status;

                              final updatedProduct = widget.product.copyWith(
                                description: _descriptionController.text,
                                quantity: newQuantity,
                                price: double.parse(_priceController.text),
                                currentPrice:
                                    double.parse(_priceController.text),
                                unit: _selectedUnit,
                                isNegotiable: widget.product.isNegotiable,
                                fertilizerType: _selectedFertilizerType,
                                pesticideType: _selectedPesticideType,
                                ripeningMethod: _selectedRipeningMethod,
                                preservationMethod: _selectedPreservationMethod,
                                status: newStatus,
                                niche: _niche,
                              );

                              await widget.onProductUpdated(updatedProduct);
                              if (!mounted) return;
                              Navigator.pop(context);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Failed to update product: ${e.toString()}'),
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5DD3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Update Product',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
