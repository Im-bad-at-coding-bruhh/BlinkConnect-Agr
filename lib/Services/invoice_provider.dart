import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/invoice_model.dart';

class InvoiceProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(farmerId)
          .collection('invoices')
          .orderBy('date', descending: true)
          .get();

      _invoices =
          snapshot.docs.map((doc) => Invoice.fromFirestore(doc)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
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

      // First verify that the farmer exists in the users collection
      final farmerDoc =
          await _firestore.collection('users').doc(invoice.farmerId).get();
      debugPrint('Farmer document exists: ${farmerDoc.exists}');

      if (!farmerDoc.exists) {
        throw Exception('Farmer not found with ID: ${invoice.farmerId}');
      }

      // Create the invoice in the user's document (since farmer is also a user)
      final docRef = await _firestore
          .collection('users')
          .doc(invoice.farmerId)
          .collection('invoices')
          .add(invoice.toMap());

      debugPrint('Created invoice with ID: ${docRef.id}');

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

      final newInvoice = invoice.copyWith(id: docRef.id);
      _invoices.insert(0, newInvoice);
      notifyListeners();
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
      // Update in user's document
      await _firestore
          .collection('users')
          .doc(farmerId)
          .collection('invoices')
          .doc(invoiceId)
          .update({'status': newStatus});

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
          // Update in customer's document
          await _firestore
              .collection('users')
              .doc(invoiceData['customerId'])
              .collection('purchases')
              .doc(invoiceId)
              .update({'status': newStatus});
        }
      }

      final index = _invoices.indexWhere((invoice) => invoice.id == invoiceId);
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
}
