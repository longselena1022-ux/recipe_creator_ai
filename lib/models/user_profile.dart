import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      createdAt: _dateTimeFromAny(data['createdAt']),
      updatedAt: _dateTimeFromAny(data['updatedAt']),
    );
  }

  static DateTime? _dateTimeFromAny(Object? value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}
