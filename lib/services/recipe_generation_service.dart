import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipe_creator_ai/models/recipe.dart';
import 'package:recipe_creator_ai/utils/recipe_response_parser.dart';

class RecipeGenerationService {
  RecipeGenerationService({FirebaseAI? firebaseAI, FirebaseAuth? auth})
    : _firebaseAIOverride = firebaseAI,
      _authOverride = auth;

  final FirebaseAI? _firebaseAIOverride;
  final FirebaseAuth? _authOverride;

  FirebaseAI get _firebaseAI =>
      _firebaseAIOverride ??
      FirebaseAI.googleAI(auth: _authOverride ?? FirebaseAuth.instance);

  static const _modelName = 'gemini-2.5-flash-lite';

  static const _systemInstruction = '''
You are a helpful cooking assistant. The user lists ingredients they already have.
Suggest 3 to 5 easy, realistic recipes that use primarily those ingredients.
Allow common pantry staples (salt, pepper, oil, butter) without requiring the user to list them.

Respond with ONLY valid JSON: a single JSON array. No markdown fences, no commentary before or after.
Each array element must be an object with exactly these keys:
- "title": string
- "ingredients": array of strings (what to use, including small pantry items if needed)
- "steps": array of strings (one short instruction per step)
''';

  Future<List<Recipe>> generate(
    String ingredientsText, {
    List<String> dietaryPreferences = const [],
    String? cookingSkill,
    String? goal,
    List<String> equipment = const [],
  }) async {
    final model = _firebaseAI.generativeModel(
      model: _modelName,
      systemInstruction: Content.system(_systemInstruction),
    );

    final trimmed = ingredientsText.trim();
    final prefs = _preferencesBlock(
      dietaryPreferences,
      cookingSkill,
      goal,
      equipment,
    );
    final userMessage =
        'Ingredients I have:\n${trimmed.isEmpty ? "(none listed — suggest very simple pantry ideas)" : trimmed}'
        '$prefs\n\nReturn only the JSON array.';

    Future<List<Recipe>> runPrompt(String message) async {
      final response = await model.generateContent([Content.text(message)]);
      final text = response.text;
      if (text == null || text.isEmpty) {
        throw const FormatException('The model returned an empty response.');
      }
      return parseRecipesFromModelText(text);
    }

    try {
      return await runPrompt(userMessage);
    } on FormatException {
      return await runPrompt(
        '$userMessage\n\nReply with JSON only: one JSON array. No markdown, no explanation.',
      );
    }
  }

  /// Builds the natural-language constraints appended to the prompt from the
  /// user's stored profile. Returns an empty string when nothing is set.
  static String _preferencesBlock(
    List<String> dietaryPreferences,
    String? cookingSkill,
    String? goal,
    List<String> equipment,
  ) {
    final lines = <String>[];

    final diets = dietaryPreferences
        .map(_dietLabel)
        .where((d) => d.isNotEmpty)
        .toList();
    if (diets.isNotEmpty) {
      lines.add(
        'Dietary requirements (every recipe MUST comply): ${diets.join(', ')}.',
      );
    }

    final goalLine = _goalGuidance(goal);
    if (goalLine.isNotEmpty) lines.add(goalLine);

    final skill = _skillGuidance(cookingSkill);
    if (skill.isNotEmpty) lines.add(skill);

    final tools = equipment.map(_equipmentLabel).where((e) => e.isNotEmpty);
    if (tools.isNotEmpty) {
      lines.add(
        'Available kitchen equipment (prefer recipes that use these): '
        '${tools.join(', ')}.',
      );
    }

    if (lines.isEmpty) return '';
    return '\n\n${lines.join('\n')}';
  }

  static String _goalGuidance(String? goal) {
    switch (goal) {
      case 'weight_loss':
        return 'Goal: weight loss — favour lighter, lower-calorie recipes with '
            'plenty of vegetables and lean protein.';
      case 'build_muscle':
        return 'Goal: build muscle — favour high-protein recipes.';
      case 'healthy_lifestyle':
        return 'Goal: healthy lifestyle — favour balanced, wholesome recipes.';
      default:
        return '';
    }
  }

  static String _equipmentLabel(String key) {
    switch (key) {
      case 'air_fryer':
        return 'air fryer';
      case 'slow_cooker':
        return 'slow cooker';
      case 'blender':
        return 'blender';
      case 'cast_iron_skillet':
        return 'cast iron skillet';
      case 'food_processor':
        return 'food processor';
      case 'oven':
        return 'oven';
      case 'microwave':
        return 'microwave';
      default:
        return key.replaceAll('_', ' ').trim();
    }
  }

  static String _dietLabel(String key) {
    switch (key) {
      case 'vegetarian':
        return 'vegetarian (no meat, poultry, or fish)';
      case 'vegan':
        return 'vegan (no animal products at all)';
      case 'gluten_free':
        return 'gluten-free';
      case 'keto':
        return 'keto (very low carb)';
      case 'paleo':
        return 'paleo';
      case 'dairy_free':
        return 'dairy-free';
      default:
        return key.replaceAll('_', ' ').trim();
    }
  }

  static String _skillGuidance(String? cookingSkill) {
    switch (cookingSkill) {
      case 'beginner':
        return 'Cook skill level: beginner — keep steps simple with basic '
            'techniques and minimal equipment.';
      case 'intermediate':
        return 'Cook skill level: intermediate — standard home-cooking '
            'techniques are fine.';
      case 'pro':
        return 'Cook skill level: advanced — more involved techniques and '
            'gourmet touches are welcome.';
      default:
        return '';
    }
  }
}
