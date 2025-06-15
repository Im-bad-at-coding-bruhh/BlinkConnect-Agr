import 'package:cloud_firestore/cloud_firestore.dart';

class Invoice {
  final String id;
  final String customerName;
  final String customerId;
  final String farmerId;
  final double amount;
  final DateTime date;
  final String status; // 'Paid', 'Pending', 'Unpaid'
  final String paymentMethod;
  final String? notes;
  final String? invoiceNumber;

  Invoice({
    required this.id,
    required this.customerName,
    required this.customerId,
    required this.farmerId,
    required this.amount,
    required this.date,
    required this.status,
    required this.paymentMethod,
    this.notes,
    this.invoiceNumber,
  });

  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Invoice(
      id: doc.id,
      customerName: data['customerName'] ?? '',
      customerId: data['customerId'] ?? '',
      farmerId: data['farmerId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      status: data['status'] ?? 'Pending',
      paymentMethod: data['paymentMethod'] ?? '',
      notes: data['notes'],
      invoiceNumber: data['invoiceNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'customerId': customerId,
      'farmerId': farmerId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'status': status,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'invoiceNumber': invoiceNumber,
    };
  }

  Invoice copyWith({
    String? id,
    String? customerName,
    String? customerId,
    String? farmerId,
    double? amount,
    DateTime? date,
    String? status,
    String? paymentMethod,
    String? notes,
    String? invoiceNumber,
  }) {
    return Invoice(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerId: customerId ?? this.customerId,
      farmerId: farmerId ?? this.farmerId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    );
  }
}
