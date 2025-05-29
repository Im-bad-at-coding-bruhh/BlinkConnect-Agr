import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/negotiation_model.dart';
import '../Services/cart_service.dart';
import '../Services/product_service.dart';

class NegotiationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null)
        throw Exception('User must be logged in to create a bid');

      final bid = Negotiation(
        id: '', // Will be set by Firestore
        productId: productId,
        sellerId: sellerId,
        buyerId: user.uid,
        buyerName: user.displayName ?? user.email?.split('@')[0] ?? 'Buyer',
        originalPrice: originalPrice,
        bidAmount: bidAmount,
        quantity: quantity,
        productName: productName,
        status: 'pending',
        timestamp: DateTime.now(),
        messages: {
          'initial': {
            'message': 'Initial bid of \$$bidAmount for $quantity units',
            'timestamp': Timestamp.now(),
            'senderId': user.uid,
          }
        },
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
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    try {
      // Get the bid document to check the status
      final bidDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('bids')
          .doc(bidId)
          .get();

      if (!bidDoc.exists) {
        throw Exception('Bid not found');
      }

      final bid = Negotiation.fromFirestore(bidDoc);
      if (bid.status != 'pending' && bid.status != 'countered') {
        throw Exception(
            'Cannot update bid status: Bid is already ${bid.status}');
      }

      // Create a batch to update both users' collections
      final batch = _firestore.batch();

      // Update seller's bid document
      final sellerBidRef = _firestore
          .collection('users')
          .doc(bid.sellerId)
          .collection('bids')
          .doc(bidId);

      // Update buyer's bid document
      final buyerBidRef = _firestore
          .collection('users')
          .doc(bid.buyerId)
          .collection('bids')
          .doc(bidId);

      // Prepare the update data
      final updateData = {
        'status': status,
        'updatedAt': Timestamp.now(),
      };

      // Add message if provided
      if (message != null) {
        final messageKey = 'message_${DateTime.now().millisecondsSinceEpoch}';
        updateData['messages.$messageKey'] = {
          'message': message,
          'senderId': currentUser.uid,
          'timestamp': Timestamp.now(),
          if (counterAmount != null) 'price': counterAmount,
        };
      }

      // Update counter amount if provided
      if (counterAmount != null) {
        updateData['counterAmount'] = counterAmount;
      }

      // Add to both collections
      batch.update(sellerBidRef, updateData);
      batch.update(buyerBidRef, updateData);

      // If the bid is accepted, add the product to the buyer's cart with special pricing
      if (status == 'accepted') {
        try {
          final cartService = CartService();
          final productService = ProductService();

          // Get the product details
          final product = await productService.getProduct(bid.productId);
          if (product == null) {
            throw Exception('Product not found');
          }

          // Calculate the final price (use counter amount if available, otherwise use bid amount)
          final finalPrice = counterAmount ?? bid.bidAmount;

          // Add to cart with special pricing
          await cartService.addToCartWithSpecialPrice(
            productId: bid.productId,
            quantity: bid.quantity.toInt(),
            specialPrice: finalPrice,
            buyerId: bid.buyerId,
          );

          // Update product quantity
          await productService.updateProduct(bid.productId, {
            'quantity': FieldValue.increment(-bid.quantity),
          });

          print(
              'Product added to cart successfully with special price: $finalPrice');
        } catch (e) {
          print('Error adding product to cart: $e');
          // Don't rethrow the error to prevent the bid acceptance from failing
          // Just log it and continue with the bid acceptance
        }
      }

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error updating bid status: $e');
      rethrow;
    }
  }
}
