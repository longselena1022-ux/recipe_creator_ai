import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_creator_ai/models/recipe.dart';
import 'package:recipe_creator_ai/models/saved_recipe_entry.dart';

class SavedRecipesRepository {
  SavedRecipesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _saved(String userId) {
    return _firestore.collection('users').doc(userId).collection('savedRecipes');
  }

  Future<String> saveRecipe({
    required String userId,
    required Recipe recipe,
    String? fromIngredients,
  }) async {
    final doc = await _saved(userId).add({
      'userId': userId,
      'recipe': recipe.toJson(),
      'liked': false,
      if (fromIngredients != null && fromIngredients.isNotEmpty)
        'fromIngredients': fromIngredients,
      'savedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> deleteSavedRecipe(String userId, String docId) async {
    await _saved(userId).doc(docId).delete();
  }

  Future<void> setLiked(String userId, String docId, bool liked) async {
    await _saved(userId).doc(docId).update({'liked': liked});
  }

  Stream<List<SavedRecipeEntry>> watchSaved(
    String userId, {
    int limit = 50,
  }) {
    return _saved(userId)
        .orderBy('savedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(SavedRecipeEntry.fromDoc).toList());
  }
}
