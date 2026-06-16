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

  Future<void> setAvatar({
    required String userId,
    required String? avatarId,
  }) async {
    await _userDoc(userId).set({
      'avatarId': avatarId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Persists the onboarding selections and marks onboarding as finished.
  ///
  /// Passing `markComplete: false` records progress without ending the flow.
  Future<void> saveOnboarding({
    required String userId,
    String? goal,
    String? cookingSkill,
    List<String>? dietaryPreferences,
    List<String>? equipment,
    bool markComplete = true,
  }) async {
    await _userDoc(userId).set({
      'goal': ?goal,
      'cookingSkill': ?cookingSkill,
      'dietaryPreferences': ?dietaryPreferences,
      'equipment': ?equipment,
      'onboardingComplete': markComplete,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<UserProfile?> watchProfile(String userId) {
    return _userDoc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromDoc(doc);
    });
  }

  /// Deletes all Firestore data for the given user: subcollections
  /// (savedRecipes, inventory, generations) and the profile document itself.
  ///
  /// Each subcollection is deleted independently so one failure does not
  /// prevent the others from being attempted. The profile document is deleted
  /// last. Throws only if the final profile-doc deletion fails.
  Future<void> deleteAllUserData(String userId) async {
    final subcollections = ['savedRecipes', 'inventory', 'generations'];

    for (final sub in subcollections) {
      try {
        final colRef = _userDoc(userId).collection(sub);
        // Firestore does not support recursive deletes on the client, so we
        // fetch all docs and delete them in a WriteBatch.
        bool hasMore = true;
        while (hasMore) {
          final snap = await colRef.limit(500).get();
          if (snap.docs.isEmpty) {
            hasMore = false;
            break;
          }
          final batch = _firestore.batch();
          for (final doc in snap.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          if (snap.docs.length < 500) hasMore = false;
        }
      } catch (_) {
        // Best-effort: continue deleting remaining subcollections.
      }
    }

    await _userDoc(userId).delete();
  }
}
