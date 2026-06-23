import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_creator_ai/models/recipe.dart';
import 'package:recipe_creator_ai/screens/home_screen.dart';
import 'package:recipe_creator_ai/services/recipe_generation_service.dart';

class _FakeRecipeGenerationService extends RecipeGenerationService {
  _FakeRecipeGenerationService() : super();

  @override
  Future<List<Recipe>> generate(
    String ingredientsText, {
    List<String> dietaryPreferences = const [],
    String? cookingSkill,
    String? goal,
    List<String> equipment = const [],
  }) async {
    return [
      Recipe(
        title: 'Test toast',
        ingredients: const ['bread'],
        steps: const ['Toast the bread.'],
      ),
    ];
  }
}

void main() {
  testWidgets('HomeScreen shows recipes after generate', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          generationService: _FakeRecipeGenerationService(),
          historyRepository: null,
          userProvider: () => null,
        ),
      ),
    );

    await tester.ensureVisible(find.text('Find Recipes'));
    await tester.tap(find.text('Find Recipes'));
    await tester.pumpAndSettle();

    expect(find.text('Test toast'), findsOneWidget);
    expect(find.text('Curated\nFor You'), findsOneWidget);
  });
}
