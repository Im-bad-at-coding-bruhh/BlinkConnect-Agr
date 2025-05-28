import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/negotiation_model.dart';

class NegotiationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'negotiations';

  // Start a new negotiation
  Future<String> startNegotiation({
    required String productId,
    required String sellerId,
    required String buyerId,
    required double originalPrice,
    required double proposedPrice,
    required String initialMessage,
  }) async {
    final docRef = await _firestore.collection(_collection).add({
      'productId': productId,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'originalPrice': originalPrice,
      'proposedPrice': proposedPrice,
      'status': 'pending',
      'messages': [
        {
          'senderId': buyerId,
          'message': initialMessage,
          'price': proposedPrice,
          'timestamp': FieldValue.serverTimestamp(),
        }
      ],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // Send a message in a negotiation
  Future<void> sendMessage({
    required String negotiationId,
    required String senderId,
    required String message,
    double? proposedPrice,
  }) async {
    await _firestore.collection(_collection).doc(negotiationId).update({
      'messages': FieldValue.arrayUnion([
        {
          'senderId': senderId,
          'message': message,
          'price': proposedPrice,
          'timestamp': FieldValue.serverTimestamp(),
        }
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
      if (proposedPrice != null) 'proposedPrice': proposedPrice,
    });
  }

  // Update negotiation status
  Future<void> updateStatus({
    required String negotiationId,
    required String status,
  }) async {
    await _firestore.collection(_collection).doc(negotiationId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all negotiations for a user (as buyer or seller)
  Stream<List<Negotiation>> getUserNegotiations(String userId) {
    return _firestore
        .collection(_collection)
        .where(Filter.or(
          Filter('buyerId', isEqualTo: userId),
          Filter('sellerId', isEqualTo: userId),
        ))
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Negotiation.fromFirestore(doc))
          .toList();
    });
  }

  // Get a single negotiation
  Stream<Negotiation?> getNegotiation(String negotiationId) {
    return _firestore
        .collection(_collection)
        .doc(negotiationId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Negotiation.fromFirestore(doc);
    });
  }

  // Get negotiations for a specific product
  Stream<List<Negotiation>> getProductNegotiations(String productId) {
    return _firestore
        .collection(_collection)
        .where('productId', isEqualTo: productId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Negotiation.fromFirestore(doc))
          .toList();
    });
  }
}
