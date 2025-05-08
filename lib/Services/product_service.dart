// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProductService {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection reference
  // final CollectionReference _productsCollection =
  //     FirebaseFirestore.instance.collection('products');

  // Get all products
  Stream<dynamic> getProducts() {
    // return _productsCollection
    //     .orderBy('createdAt', descending: true)
    //     .snapshots();
    return Stream.empty();
  }

  // Get products by category
  Stream<dynamic> getProductsByCategory(String category) {
    // return _productsCollection
    //     .where('category', isEqualTo: category)
    //     .orderBy('createdAt', descending: true)
    //     .snapshots();
    return Stream.empty();
  }

  // Search products
  Stream<dynamic> searchProducts(String query) {
    // String searchQuery = query.toLowerCase();
    // return _productsCollection
    //     .where('searchKeywords', arrayContains: searchQuery)
    //     .orderBy('createdAt', descending: true)
    //     .snapshots();
    return Stream.empty();
  }

  // Get farmer's products
  Stream<dynamic> getFarmerProducts(String farmerId) {
    // return _productsCollection
    //     .where('farmerId', isEqualTo: farmerId)
    //     .orderBy('createdAt', descending: true)
    //     .snapshots();
    return Stream.empty();
  }

  // Add a new product
  Future<void> addProduct({
    required String name,
    required double price,
    required String description,
    required String farmerId,
    required String farmerName,
    required File image,
    required String category,
    List<String>? tags,
  }) async {
    // try {
    //   // Upload image to Firebase Storage
    //   String imageUrl = await _uploadImage(image);

    //   // Generate search keywords
    //   List<String> searchKeywords =
    //       _generateSearchKeywords(name, description, category, tags);

    //   // Add product to Firestore
    //   await _productsCollection.add({
    //     'name': name,
    //     'price': price,
    //     'description': description,
    //     'farmerId': farmerId,
    //     'farmerName': farmerName,
    //     'imageUrl': imageUrl,
    //     'category': category,
    //     'tags': tags ?? [],
    //     'searchKeywords': searchKeywords,
    //     'rating': 0.0,
    //     'totalRatings': 0,
    //     'createdAt': FieldValue.serverTimestamp(),
    //     'updatedAt': FieldValue.serverTimestamp(),
    //   });
    // } catch (e) {
    //   throw 'Failed to add product. Please try again.';
    // }
  }

  // Update a product
  Future<void> updateProduct({
    required String productId,
    String? name,
    double? price,
    String? description,
    File? image,
    String? category,
    List<String>? tags,
  }) async {
    // try {
    //   Map<String, dynamic> updateData = {};

    //   if (name != null) updateData['name'] = name;
    //   if (price != null) updateData['price'] = price;
    //   if (description != null) updateData['description'] = description;
    //   if (category != null) updateData['category'] = category;
    //   if (tags != null) updateData['tags'] = tags;

    //   if (name != null ||
    //       description != null ||
    //       category != null ||
    //       tags != null) {
    //     updateData['searchKeywords'] = _generateSearchKeywords(
    //       name ?? '',
    //       description ?? '',
    //       category ?? '',
    //       tags,
    //     );
    //   }

    //   if (image != null) {
    //     String imageUrl = await _uploadImage(image);
    //     updateData['imageUrl'] = imageUrl;
    //   }

    //   updateData['updatedAt'] = FieldValue.serverTimestamp();

    //   await _productsCollection.doc(productId).update(updateData);
    // } catch (e) {
    //   throw 'Failed to update product. Please try again.';
    // }
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    // try {
    //   // Get product data to delete image
    //   DocumentSnapshot doc = await _productsCollection.doc(productId).get();
    //   Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    //   if (data != null && data['imageUrl'] != null) {
    //     // Delete image from storage
    //     try {
    //       await _storage.refFromURL(data['imageUrl']).delete();
    //     } catch (e) {
    //       print('Failed to delete product image: $e');
    //     }
    //   }

    //   // Delete product document
    //   await _productsCollection.doc(productId).delete();
    // } catch (e) {
    //   throw 'Failed to delete product. Please try again.';
    // }
  }

  // Rate a product
  Future<void> rateProduct(String productId, double rating) async {
    // try {
    //   DocumentSnapshot doc = await _productsCollection.doc(productId).get();
    //   Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    //   if (data == null) throw 'Product not found.';

    //   double currentRating = data['rating'] ?? 0.0;
    //   int totalRatings = data['totalRatings'] ?? 0;

    //   double newRating =
    //       ((currentRating * totalRatings) + rating) / (totalRatings + 1);

    //   await _productsCollection.doc(productId).update({
    //     'rating': newRating,
    //     'totalRatings': totalRatings + 1,
    //     'updatedAt': FieldValue.serverTimestamp(),
    //   });
    // } catch (e) {
    //   throw 'Failed to rate product. Please try again.';
    // }
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(File image) async {
    // try {
    //   String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    //   Reference ref = _storage.ref().child('products/$fileName');

    //   UploadTask uploadTask = ref.putFile(image);
    //   TaskSnapshot taskSnapshot = await uploadTask;

    //   return await taskSnapshot.ref.getDownloadURL();
    // } catch (e) {
    //   throw 'Failed to upload image. Please try again.';
    // }
    return '';
  }

  // Generate search keywords
  List<String> _generateSearchKeywords(
    String name,
    String description,
    String category,
    List<String>? tags,
  ) {
    Set<String> keywords = {};

    // Add name words
    keywords.addAll(name.toLowerCase().split(' '));
    keywords.addAll(description.toLowerCase().split(' '));
    keywords.add(category.toLowerCase());
    if (tags != null) {
      keywords.addAll(tags.map((tag) => tag.toLowerCase()));
    }

    return keywords.toList();
  }
}
