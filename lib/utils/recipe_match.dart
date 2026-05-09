import 'package:recipe_creator_ai/models/recipe.dart';

const _staples = ['salt', 'pepper', 'oil', 'butter', 'water', 'flour'];

int matchPercent(Recipe recipe, List<String> pantryItems) {
  if (pantryItems.isEmpty || recipe.ingredients.isEmpty) return 85;
  int matches = 0;
  for (final ing in recipe.ingredients) {
    final low = ing.toLowerCase();
    if (_staples.any((s) => low.contains(s))) {
      matches++;
      continue;
    }
    if (pantryItems.any((p) {
      final pl = p.toLowerCase();
      return low.contains(pl) || pl.contains(low.split(' ').first);
    })) {
      matches++;
    }
  }
  return ((matches / recipe.ingredients.length) * 100).round().clamp(60, 99);
}

String statusText(Recipe recipe, List<String> pantryItems) {
  if (pantryItems.isEmpty) return 'Add ingredients to match';
  final missing = recipe.ingredients.where((ing) {
    final low = ing.toLowerCase();
    if (_staples.any((s) => low.contains(s))) return false;
    return !pantryItems.any((p) {
      final pl = p.toLowerCase();
      return low.contains(pl) || pl.contains(low.split(' ').first);
    });
  }).length;
  if (missing == 0) return 'All Ingredients at Home';
  return 'Need $missing item${missing > 1 ? 's' : ''}';
}

String estimateTime(Recipe recipe) {
  final mins = (recipe.steps.length * 7).clamp(10, 90);
  return '$mins min';
}
