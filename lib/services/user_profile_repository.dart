import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_creator_ai/models/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  Future<void> ensureProfile({
    required String userId,
    required String email,
    String? name,
  }) async {
    final now = FieldValue.serverTimestamp();
    await _userDoc(userId).set({
      'userId': userId,
      'email': email,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      'updatedAt': now,
      'createdAt': now,
    }, SetOptions(merge: true));
  }

  Stream<UserProfile?> watchProfile(String userId) {
    return _userDoc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromDoc(doc);
    });
  }
}
