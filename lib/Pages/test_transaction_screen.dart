import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../Services/invoice_provider.dart';
import '../Models/invoice_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme_provider.dart';
import 'package:flutter/foundation.dart';

class TestTransactionScreen extends StatefulWidget {
  final String customerName;
  final String customerId;
  final double amount;
  final String productName;
  final String farmerId;

  const TestTransactionScreen({
    Key? key,
    required this.customerName,
    required this.customerId,
    required this.amount,
    required this.productName,
    required this.farmerId,
  }) : super(key: key);

  @override
  State<TestTransactionScreen> createState() => _TestTransactionScreenState();
}

class _TestTransactionScreenState extends State<TestTransactionScreen> {
  String _selectedStatus = 'Pending';
  final List<String> _statuses = ['Pending', 'Paid', 'Unpaid'];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'Test Transaction',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Details',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Product', widget.productName, isDarkMode),
                  _buildDetailRow('Amount',
                      '\$${widget.amount.toStringAsFixed(2)}', isDarkMode),
                  _buildDetailRow('Customer', widget.customerName, isDarkMode),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Status Selection
            Text(
              'Select Transaction Status',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  dropdownColor: isDarkMode ? Colors.grey[900] : Colors.white,
                  style: GoogleFonts.poppins(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  items: _statuses.map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedStatus = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
            const Spacer(),

            // Create Invoice Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isLoading ? null : () => _createInvoice(widget.farmerId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5DD3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Create Invoice',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createInvoice(String? farmerId) async {
    if (farmerId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Debug logging
      debugPrint('Creating invoice with farmer ID: $farmerId');
      debugPrint('Customer ID: ${widget.customerId}');
      debugPrint('Amount: ${widget.amount}');

      final invoice = Invoice(
        id: '', // Will be set by Firestore
        customerName: widget.customerName,
        customerId: widget.customerId,
        farmerId: widget.farmerId,
        amount: widget.amount,
        date: DateTime.now(),
        status: _selectedStatus,
        paymentMethod: 'Test Payment',
      );

      // Debug logging
      debugPrint('Invoice data: ${invoice.toMap()}');

      await Provider.of<InvoiceProvider>(context, listen: false)
          .createInvoice(invoice);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating invoice: $e'),
          backgroundColor: Colors.red,
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
}
