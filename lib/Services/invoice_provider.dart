import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/invoice_model.dart';
import 'sales_analytics_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvoiceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SalesAnalyticsService _salesAnalytics = SalesAnalyticsService();
  List<Invoice> _invoices = [];
  bool _isLoading = false;
  String? _error;

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load invoices for a specific farmer
  Future<void> loadFarmerInvoices(String farmerId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('Loading invoices for farmer ID: $farmerId');

      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(farmerId)
          .collection('invoices')
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint('Found ${snapshot.docs.length} invoices');

      _invoices =
          snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();

      debugPrint('Processed ${_invoices.length} invoices');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading invoices: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Create a new invoice
  Future<Invoice> createInvoice(Invoice invoice) async {
    try {
      debugPrint('Creating invoice for farmer ID: ${invoice.farmerId}');
      debugPrint('Customer ID: ${invoice.customerId}');
      debugPrint('Customer Name: ${invoice.customerName}');

      // Validate invoice data
      if (invoice.farmerId.isEmpty ||
          invoice.customerId.isEmpty ||
          invoice.productId.isEmpty ||
          invoice.customerName.isEmpty) {
        throw Exception('Invalid invoice data: Missing required fields');
      }

      if (invoice.amount <= 0 || invoice.quantity <= 0) {
        throw Exception('Invalid invoice data: Invalid amount or quantity');
      }

      // First verify that the farmer exists in the users collection
      final farmerDoc =
          await _firestore.collection('users').doc(invoice.farmerId).get();
      debugPrint('Farmer document exists: ${farmerDoc.exists}');

      if (!farmerDoc.exists) {
        throw Exception('Farmer not found with ID: ${invoice.farmerId}');
      }

      // Verify that the customer exists
      final customerDoc =
          await _firestore.collection('users').doc(invoice.customerId).get();
      debugPrint('Customer document exists: ${customerDoc.exists}');

      if (!customerDoc.exists) {
        throw Exception('Customer not found with ID: ${invoice.customerId}');
      }

      // Create the invoice in the user's document (since farmer is also a user)
      final docRef = await _firestore
          .collection('users')
          .doc(invoice.farmerId)
          .collection('invoices')
          .add(invoice.toMap());

      debugPrint('Created invoice with ID: ${docRef.id}');

      // Verify the invoice was actually created in Firestore
      final verifyDoc = await _firestore
          .collection('users')
          .doc(invoice.farmerId)
          .collection('invoices')
          .doc(docRef.id)
          .get();

      debugPrint(
          'Verification - Invoice exists in Firestore: ${verifyDoc.exists}');
      if (verifyDoc.exists) {
        debugPrint('Verification - Invoice data: ${verifyDoc.data()}');
      }

      // Also create a reference in the customer's document for easy access
      await _firestore
          .collection('users')
          .doc(invoice.customerId)
          .collection('purchases')
          .doc(docRef.id)
          .set({
        'invoiceId': docRef.id,
        'farmerId': invoice.farmerId,
        'date': invoice.date,
        'amount': invoice.amount,
        'status': invoice.status,
      });

      debugPrint('Created purchase reference for user: ${invoice.customerId}');

      // Update sales analytics
      if (invoice.status == 'Paid') {
        try {
          // Get product details from the invoice
          final productDoc = await _firestore
              .collection('products')
              .doc(invoice.productId)
              .get();

          if (productDoc.exists) {
            final productData = productDoc.data();
            if (productData != null) {
              // Validate required fields before updating sales analytics
              final productName = productData['productName']?.toString() ?? '';
              final farmerName = productData['farmerName']?.toString() ?? '';
              final category = productData['category']?.toString() ?? '';
              final unit = productData['unit']?.toString() ?? 'kg';
              final region = productData['region']?.toString() ?? '';

              if (productName.isNotEmpty &&
                  farmerName.isNotEmpty &&
                  category.isNotEmpty &&
                  region.isNotEmpty) {
                await _salesAnalytics.updateProductSales(
                  productId: invoice.productId,
                  productName: productName,
                  farmerId: invoice.farmerId,
                  farmerName: farmerName,
                  category: category,
                  quantity: invoice.quantity,
                  unit: unit,
                  saleAmount: invoice.amount,
                  region: 'global', // For leaderboard
                );
                await _salesAnalytics.updateProductSales(
                  productId: invoice.productId,
                  productName: productName,
                  farmerId: invoice.farmerId,
                  farmerName: farmerName,
                  category: category,
                  quantity: invoice.quantity,
                  unit: unit,
                  saleAmount: invoice.amount,
                  region: region, // For analytics by region
                );
              } else {
                debugPrint(
                    'Warning: Missing required product data for sales analytics update');
              }
            } else {
              debugPrint(
                  'Warning: Product data is null for sales analytics update');
            }
          } else {
            debugPrint(
                'Warning: Product document does not exist for sales analytics update');
          }
        } catch (e) {
          debugPrint('Error updating sales analytics: $e');
          // Don't rethrow this error as it shouldn't prevent invoice creation
        }
      }

      final newInvoice = invoice.copyWith(id: docRef.id);
      debugPrint('Created new invoice with ID: ${newInvoice.id}');
      debugPrint(
          'Adding invoice to local list. Current count: ${_invoices.length}');

      _invoices.insert(0, newInvoice);
      debugPrint('Invoice added to local list. New count: ${_invoices.length}');

      notifyListeners();
      debugPrint('Notified listeners about invoice update');

      return newInvoice;
    } catch (e) {
      debugPrint('Error creating invoice: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update invoice status
  Future<void> updateInvoiceStatus(
      String farmerId, String invoiceId, String newStatus) async {
    try {
      debugPrint(
          'Updating invoice status for farmer: $farmerId, invoice: $invoiceId');

      // Update the invoice in the farmer's subcollection
      final farmerInvoiceRef = _firestore
          .collection('users')
          .doc(farmerId)
          .collection('invoices')
          .doc(invoiceId);

      await farmerInvoiceRef.update({'status': newStatus});
      debugPrint('Updated farmer invoice status');

      // Find the invoice to get the customer ID
      final invoiceSnapshot = await farmerInvoiceRef.get();
      if (!invoiceSnapshot.exists) {
        debugPrint('Invoice not found during status update');
        return;
      }

      final invoiceData = invoiceSnapshot.data();
      if (invoiceData == null) {
        debugPrint('Invoice data is null during status update');
        return;
      }
      final customerId = invoiceData['customerId']?.toString() ?? '';
      final productId = invoiceData['productId']?.toString() ?? '';
      final quantity = (invoiceData['quantity'] as num?)?.toDouble() ?? 0.0;
      final amount = (invoiceData['amount'] as num?)?.toDouble() ?? 0.0;

      if (customerId.isNotEmpty) {
        // Update the purchase reference in the customer's subcollection
        final customerPurchaseRef = _firestore
            .collection('users')
            .doc(customerId)
            .collection('purchases')
            .doc(invoiceId);

        await customerPurchaseRef.update({'status': newStatus});
        debugPrint('Updated customer purchase status');
      }

      // Update sales analytics if the invoice is marked as 'Paid'
      if (newStatus == 'Paid' && productId.isNotEmpty) {
        try {
          final productDoc =
              await _firestore.collection('products').doc(productId).get();

          if (productDoc.exists) {
            final productData = productDoc.data();
            if (productData != null) {
              final productName = productData['productName']?.toString() ?? '';
              final farmerName = productData['farmerName']?.toString() ?? '';
              final category = productData['category']?.toString() ?? '';
              final unit = productData['unit']?.toString() ?? 'kg';
              final region = productData['region']?.toString() ?? '';

              if (productName.isNotEmpty &&
                  farmerName.isNotEmpty &&
                  category.isNotEmpty &&
                  region.isNotEmpty) {
                await _salesAnalytics.updateProductSales(
                  productId: productId,
                  productName: productName,
                  farmerId: farmerId,
                  farmerName: farmerName,
                  category: category,
                  quantity: quantity,
                  unit: unit,
                  saleAmount: amount,
                  region: region,
                );
              } else {
                debugPrint(
                    'Warning: Missing required product data for sales analytics update');
              }
            }
          }
        } catch (e) {
          debugPrint('Error updating sales analytics on status change: $e');
        }
      }

      // Update the local list
      final index = _invoices.indexWhere((inv) => inv.id == invoiceId);
      if (index != -1) {
        _invoices[index] = _invoices[index].copyWith(status: newStatus);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Delete an invoice
  Future<void> deleteInvoice(String farmerId, String invoiceId) async {
    try {
      // Get the invoice to find the customer ID
      final invoiceDoc = await _firestore
          .collection('users')
          .doc(farmerId)
          .collection('invoices')
          .doc(invoiceId)
          .get();

      if (invoiceDoc.exists) {
        final invoiceData = invoiceDoc.data();
        if (invoiceData != null) {
          // Delete from customer's document
          await _firestore
              .collection('users')
              .doc(invoiceData['customerId'])
              .collection('purchases')
              .doc(invoiceId)
              .delete();
        }
      }

      // Delete from farmer's document
      await _firestore
          .collection('users')
          .doc(farmerId)
          .collection('invoices')
          .doc(invoiceId)
          .delete();

      _invoices.removeWhere((invoice) => invoice.id == invoiceId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Get invoices by status
  List<Invoice> getInvoicesByStatus(String status) {
    return _invoices.where((invoice) => invoice.status == status).toList();
  }

  // Get invoices by date range
  List<Invoice> getInvoicesByDateRange(DateTime start, DateTime end) {
    return _invoices
        .where((invoice) =>
            invoice.date.isAfter(start) && invoice.date.isBefore(end))
        .toList();
  }

  // Get total amount of invoices
  double getTotalAmount() {
    return _invoices.fold(0, (sum, invoice) => sum + invoice.amount);
  }

  // Get total amount by status
  double getTotalAmountByStatus(String status) {
    return _invoices
        .where((invoice) => invoice.status == status)
        .fold(0, (sum, invoice) => sum + invoice.amount);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh invoices without clearing local state (for newly created invoices)
  Future<void> refreshInvoices(String farmerId) async {
    try {
      debugPrint('Refreshing invoices for farmer ID: $farmerId');

      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(farmerId)
          .collection('invoices')
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint('Found ${snapshot.docs.length} invoices in refresh');

      final newInvoices =
          snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();

      // Only update if we have new data and it's different
      if (newInvoices.length != _invoices.length ||
          !_areInvoiceListsEqual(_invoices, newInvoices)) {
        _invoices = newInvoices;
        debugPrint('Updated invoice list. New count: ${_invoices.length}');
        notifyListeners();
      } else {
        debugPrint('No changes detected in invoice list');
      }
    } catch (e) {
      debugPrint('Error refreshing invoices: $e');
      // Don't rethrow to avoid breaking the UI
    }
  }

  // Helper method to compare invoice lists
  bool _areInvoiceListsEqual(List<Invoice> list1, List<Invoice> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  // Update payment status and handle stock accordingly
  Future<void> updatePaymentStatus(String invoiceId, String newStatus) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // First get the invoice details
      final invoiceDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('invoices')
          .doc(invoiceId)
          .get();

      if (!invoiceDoc.exists) {
        throw Exception('Invoice not found');
      }

      final invoiceData = invoiceDoc.data();
      if (invoiceData == null) {
        throw Exception('Invoice data is null');
      }

      // Update invoice status
      await updateInvoiceStatus(currentUser.uid, invoiceId, newStatus);

      // Handle stock updates based on payment status
      if (newStatus == 'Paid') {
        // Deduct stock only when payment is confirmed
        await _updateProductStockForPayment(
          invoiceData['productId'] as String,
          invoiceData['quantity'] as double,
        );
      }
      // For 'Pending' or 'Unpaid', stock remains unchanged
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      rethrow;
    }
  }

  // Helper method to update product stock for payment
  Future<void> _updateProductStockForPayment(
      String productId, double quantity) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final productRef = _firestore.collection('products').doc(productId);
        final productDoc = await transaction.get(productRef);

        if (!productDoc.exists) {
          throw Exception('Product not found');
        }

        final productData = productDoc.data();
        if (productData == null) {
          throw Exception('Product data is null');
        }

        final currentQuantity = (productData['quantity'] as num).toDouble();
        final newQuantity = currentQuantity - quantity;

        if (newQuantity <= 0) {
          // Mark product as sold out
          transaction.update(productRef, {
            'quantity': 0,
            'status': 'sold_out',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Update quantity
          transaction.update(productRef, {
            'quantity': newQuantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      debugPrint('Error updating product stock for payment: $e');
      rethrow;
    }
  }
}
