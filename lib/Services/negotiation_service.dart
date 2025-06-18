import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/negotiation_model.dart';
import '../Models/cart_model.dart';
import 'auth_service.dart';
import 'cart_service.dart';

class NegotiationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();
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

  // Create a new bid
  Future<String> createBid({
    required String productId,
    required String sellerId,
    required double originalPrice,
    required double bidAmount,
    required double quantity,
    required String productName,
    required String farmerName,
    required String unit,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null)
        throw Exception('User must be logged in to create a bid');

      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final messages = {
        messageId: {
          'message': 'Initial bid of \$$bidAmount for $quantity units',
          'timestamp': Timestamp.now(),
          'senderId': user.uid,
        }
      };

      final bid = Negotiation(
        id: '', // Will be set by Firestore
        productId: productId,
        sellerId: sellerId,
        buyerId: user.uid,
        buyerName: user.displayName ?? user.email?.split('@')[0] ?? 'Buyer',
        farmerName: farmerName,
        unit: unit,
        originalPrice: originalPrice,
        bidAmount: bidAmount,
        quantity: quantity.toDouble(),
        productName: productName,
        status: 'pending',
        timestamp: DateTime.now(),
        messages: messages,
      );

      // First add to seller's bids collection
      final sellerDocRef = await _firestore
          .collection('users')
          .doc(sellerId)
          .collection('bids')
          .add(bid.toMap());

      // Then add to buyer's bids collection with the same ID
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('bids')
          .doc(sellerDocRef.id)
          .set(bid.toMap());

      return sellerDocRef.id;
    } catch (e) {
      print('Error creating bid: $e');
      rethrow;
    }
  }

  // Get bids for current user
  Stream<List<Negotiation>> getBids() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User must be logged in to view bids');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bids')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Negotiation.fromFirestore(doc))
            .toList());
  }

  // Get bids for a specific product
  Stream<List<Negotiation>> getProductBids(String productId) {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User must be logged in to view bids');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bids')
        .where('productId', isEqualTo: productId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Negotiation.fromFirestore(doc))
            .toList());
  }

  // Get a single bid
  Future<Negotiation> getBid(String bidId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User must be logged in to view bid');

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bids')
        .doc(bidId)
        .get();

    if (!doc.exists) throw Exception('Bid not found');
    return Negotiation.fromFirestore(doc);
  }

  // Update bid status (accept/reject/counter)
  Future<void> updateBidStatus({
    required String bidId,
    required String status,
    String? message,
    double? counterAmount,
  }) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final bidRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('bids')
        .doc(bidId);

    final bidDoc = await bidRef.get();
    if (!bidDoc.exists) throw Exception('Bid not found');

    final bid = Negotiation.fromMap(bidDoc.id, bidDoc.data()!);
    final timestamp = Timestamp.now();

    // Create a new message entry
    final newMessage = {
      'senderId': user.uid,
      'message': message ?? 'Bid ${status.toLowerCase()}',
      'timestamp': timestamp,
      if (counterAmount != null) 'price': counterAmount,
    };

    // Generate a unique key for the new message
    final messageKey = DateTime.now().millisecondsSinceEpoch.toString();

    // Create a copy of the existing messages map and add the new message
    final updatedMessages =
        Map<String, Map<String, dynamic>>.from(bid.messages);
    updatedMessages[messageKey] = newMessage;

    // Prepare update data
    final updateData = {
      'messages': updatedMessages,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (counterAmount != null) {
      updateData['bidAmount'] = counterAmount;
    }

    // Create a batch write
    final batch = _firestore.batch();

    // Update both seller's and buyer's bid documents
    final sellerBidRef = _firestore
        .collection('users')
        .doc(bid.sellerId)
        .collection('bids')
        .doc(bidId);
    final buyerBidRef = _firestore
        .collection('users')
        .doc(bid.buyerId)
        .collection('bids')
        .doc(bidId);

    batch.update(sellerBidRef, updateData);
    batch.update(buyerBidRef, updateData);

    // Commit the batch
    await batch.commit();

    // If bid is accepted, add to cart
    if (status == 'accepted') {
      // Retrieve the potentially updated bid after status change
      final acceptedBidDoc = await bidRef.get();
      if (!acceptedBidDoc.exists)
        throw Exception('Accepted bid not found after update');
      final acceptedBid =
          Negotiation.fromMap(acceptedBidDoc.id, acceptedBidDoc.data()!);

      final cartService = CartService();
      await cartService.addToCart(
        CartItem(
          id: '',
          productId: acceptedBid.productId,
          productName: acceptedBid.productName,
          farmerName: acceptedBid.farmerName,
          unit: acceptedBid.unit,
          quantity: acceptedBid.quantity,
          originalPrice: acceptedBid.originalPrice,
          negotiatedPrice: counterAmount ?? acceptedBid.bidAmount,
          negotiationId: acceptedBid.id,
          addedAt: DateTime.now(),
          status: 'pending',
          negotiationMessage: message ??
              'Accepted bid of \$${counterAmount ?? acceptedBid.bidAmount}',
        ),
      );
    }
  }
}
