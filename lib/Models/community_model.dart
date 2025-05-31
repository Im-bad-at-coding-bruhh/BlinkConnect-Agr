import 'package:cloud_firestore/cloud_firestore.dart';

class Community {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final String creatorName;
  final DateTime createdAt;
  final String status; // 'pending', 'approved', 'rejected'
  final String? adminNote; // Optional note from admin for rejection/approval

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    required this.status,
    this.adminNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'createdAt': createdAt,
      'status': status,
      'adminNote': adminNote,
    };
  }

  factory Community.fromMap(String id, Map<String, dynamic> map) {
    return Community(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      adminNote: map['adminNote'],
    );
  }
}
