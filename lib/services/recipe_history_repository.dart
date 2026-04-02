import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_creator_ai/models/recipe.dart';

class GenerationRecord {
  GenerationRecord({
    required this.id,
    required this.ingredientsText,
    required this.recipes,
    required this.createdAt,
  });

  final String id;
  final String ingredientsText;
  final List<Recipe> recipes;
  final DateTime? createdAt;

  factory GenerationRecord.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final raw = data['recipes'];
    final recipes = <Recipe>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          recipes.add(Recipe.fromJson(item));
        } else if (item is Map) {
          recipes.add(Recipe.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    final ts = data['createdAt'];
    DateTime? created;
    if (ts is Timestamp) {
      created = ts.toDate();
    }
    return GenerationRecord(
      id: doc.id,
      ingredientsText: data['ingredients']?.toString() ?? '',
      recipes: recipes,
      createdAt: created,
    );
  }
}

class RecipeHistoryRepository {
  RecipeHistoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _generations(String userId) {
    return _firestore.collection('users').doc(userId).collection('generations');
  }

  Future<void> saveGeneration({
    required String userId,
    required String ingredientsText,
    required List<Recipe> recipes,
  }) async {
    await _generations(userId).add({
      'userId': userId,
      'ingredients': ingredientsText,
      'recipes': recipes.map((r) => r.toJson()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<GenerationRecord>> watchRecent(
    String userId, {
    int limit = 8,
  }) {
    return _generations(userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(GenerationRecord.fromDoc).toList());
  }
}
