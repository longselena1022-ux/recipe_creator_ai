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

  Future<List<Recipe>> generate(String ingredientsText) async {
    final model = _firebaseAI.generativeModel(
      model: _modelName,
      systemInstruction: Content.system(_systemInstruction),
    );

    final trimmed = ingredientsText.trim();
    final userMessage =
        'Ingredients I have:\n${trimmed.isEmpty ? "(none listed — suggest very simple pantry ideas)" : trimmed}\n\nReturn only the JSON array.';

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
}
