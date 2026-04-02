import 'dart:convert';

import 'package:recipe_creator_ai/models/recipe.dart';

/// Removes leading ```json / ``` fences some models wrap around JSON.
String stripMarkdownFences(String raw) {
  var s = raw.trim();
  if (!s.startsWith('```')) {
    return s;
  }
  final firstNl = s.indexOf('\n');
  if (firstNl != -1) {
    s = s.substring(firstNl + 1);
  } else {
    s = s.substring(3);
  }
  s = s.trim();
  if (s.endsWith('```')) {
    s = s.substring(0, s.length - 3).trim();
  }
  return s;
}

/// Parses model output into [Recipe] list. Throws [FormatException] on invalid JSON.
List<Recipe> parseRecipesFromModelText(String text) {
  final cleaned = stripMarkdownFences(text.trim());
  final decoded = jsonDecode(cleaned);
  if (decoded is! List) {
    throw FormatException('Expected a JSON array of recipes, got ${decoded.runtimeType}');
  }
  final out = <Recipe>[];
  for (final item in decoded) {
    if (item is Map) {
      out.add(Recipe.fromJson(Map<String, dynamic>.from(item)));
    }
  }
  return out;
}
