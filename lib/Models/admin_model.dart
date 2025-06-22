import 'package:cloud_firestore/cloud_firestore.dart';

class Admin {
  final String userId;
  final String email;
  final String? name;
  final List<String>
      permissions; // ['manage_communities', 'manage_users', etc.]
  final String role; // 'super_admin', 'community_admin', etc.
  final DateTime createdAt;
  final String? assignedBy; // ID of the admin who assigned this admin

  Admin({
    required this.userId,
    required this.email,
    this.name,
    required this.permissions,
    required this.role,
    required this.createdAt,
    this.assignedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'permissions': permissions,
      'role': role,
      'createdAt': createdAt,
      'assignedBy': assignedBy,
    };
  }

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      userId: map['userId'] ?? '',
      email: map['email'] ?? '',
      name: map['name'],
      permissions: List<String>.from(map['permissions'] ?? []),
      role: map['role'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      assignedBy: map['assignedBy'],
    );
  }

  // Helper method to check if admin has specific permission
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  // Helper method to check if admin is super admin
  bool get isSuperAdmin => role == 'super_admin';
}
