import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_creator_ai/models/recipe.dart';

class SavedRecipeEntry {
  const SavedRecipeEntry({
    required this.id,
    required this.recipe,
    required this.liked,
    required this.savedAt,
    this.fromIngredients,
  });

  final String id;
  final Recipe recipe;
  final bool liked;
  final DateTime? savedAt;
  final String? fromIngredients;

  SavedRecipeEntry copyWith({bool? liked}) {
    return SavedRecipeEntry(
      id: id,
      recipe: recipe,
      liked: liked ?? this.liked,
      savedAt: savedAt,
      fromIngredients: fromIngredients,
    );
  }

  factory SavedRecipeEntry.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final raw = data['recipe'];
    final Recipe recipe;
    if (raw is Map<String, dynamic>) {
      recipe = Recipe.fromJson(raw);
    } else if (raw is Map) {
      recipe = Recipe.fromJson(Map<String, dynamic>.from(raw));
    } else {
      recipe = const Recipe(title: 'Untitled', ingredients: [], steps: []);
    }
    final ts = data['savedAt'];
    DateTime? savedAt;
    if (ts is Timestamp) {
      savedAt = ts.toDate();
    }
    return SavedRecipeEntry(
      id: doc.id,
      recipe: recipe,
      liked: data['liked'] == true,
      savedAt: savedAt,
      fromIngredients: data['fromIngredients']?.toString().isNotEmpty == true
          ? data['fromIngredients'].toString()
          : null,
    );
  }
}
