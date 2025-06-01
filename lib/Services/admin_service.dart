import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/admin_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if current user is an admin
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      print('AdminService: Current user: ${user?.uid}'); // Debug print
      if (user == null) return false;

      final adminDoc =
          await _firestore.collection('admins').doc(user.uid).get();
      print(
          'AdminService: Admin doc exists: ${adminDoc.exists}'); // Debug print
      if (!adminDoc.exists) return false;

      final adminData = adminDoc.data();
      print('AdminService: Admin data: $adminData'); // Debug print
      return adminData != null;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Get current admin's data
  Future<Admin?> getCurrentAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final adminDoc = await _firestore.collection('admins').doc(user.uid).get();

    if (!adminDoc.exists) return null;
    return Admin.fromMap(adminDoc.data()!);
  }

  // Get all pending community requests
  Stream<List<Map<String, dynamic>>> getPendingCommunities() {
    return _firestore
        .collection('communities')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Approve a community request
  Future<void> approveCommunity(String communityId, {String? note}) async {
    final admin = await getCurrentAdmin();
    if (admin == null || !admin.hasPermission('manage_communities')) {
      throw Exception('Unauthorized: Insufficient permissions');
    }

    await _firestore.collection('communities').doc(communityId).update({
      'status': 'approved',
      'adminNote': note,
      'approvedBy': admin.userId,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  // Reject a community request
  Future<void> rejectCommunity(String communityId, String note) async {
    final admin = await getCurrentAdmin();
    if (admin == null || !admin.hasPermission('manage_communities')) {
      throw Exception('Unauthorized: Insufficient permissions');
    }

    await _firestore.collection('communities').doc(communityId).update({
      'status': 'rejected',
      'adminNote': note,
      'rejectedBy': admin.userId,
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  // Assign a new admin (only super admins can do this)
  Future<void> assignAdmin({
    required String userId,
    required String email,
    required String name,
    required List<String> permissions,
    required String role,
  }) async {
    final admin = await getCurrentAdmin();
    if (admin == null || !admin.isSuperAdmin) {
      throw Exception('Unauthorized: Only super admins can assign new admins');
    }

    await _firestore.collection('admins').doc(userId).set({
      'userId': userId,
      'email': email,
      'name': name,
      'permissions': permissions,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'assignedBy': admin.userId,
    });
  }

  // Remove an admin (only super admins can do this)
  Future<void> removeAdmin(String userId) async {
    final admin = await getCurrentAdmin();
    if (admin == null || !admin.isSuperAdmin) {
      throw Exception('Unauthorized: Only super admins can remove admins');
    }

    await _firestore.collection('admins').doc(userId).delete();
  }
}
