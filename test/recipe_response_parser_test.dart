import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_creator_ai/utils/recipe_response_parser.dart';

void main() {
  group('stripMarkdownFences', () {
    test('returns plain JSON unchanged', () {
      expect(stripMarkdownFences('[{"title":"a"}]'), '[{"title":"a"}]');
    });

    test('strips json code fence', () {
      const raw = '```json\n[{"title":"Eggs","ingredients":["egg"],"steps":["boil"]}]\n```';
      expect(
        stripMarkdownFences(raw),
        '[{"title":"Eggs","ingredients":["egg"],"steps":["boil"]}]',
      );
    });

    test('strips generic fence without language tag', () {
      const raw = '```\n[]\n```';
      expect(stripMarkdownFences(raw), '[]');
    });
  });

  group('parseRecipesFromModelText', () {
    test('parses valid array', () {
      const json =
          '[{"title":"Toast","ingredients":["bread"],"steps":["toast"]}]';
      final recipes = parseRecipesFromModelText(json);
      expect(recipes, hasLength(1));
      expect(recipes.first.title, 'Toast');
      expect(recipes.first.ingredients, ['bread']);
      expect(recipes.first.steps, ['toast']);
    });

    test('parses after stripping fences', () {
      const raw =
          '```json\n[{"title":"X","ingredients":[],"steps":[]}]\n```';
      final recipes = parseRecipesFromModelText(raw);
      expect(recipes.single.title, 'X');
    });

    test('throws when not an array', () {
      expect(
        () => parseRecipesFromModelText('{"title":"bad"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('uses defaults for missing fields', () {
      const json = '[{}]';
      final recipes = parseRecipesFromModelText(json);
      expect(recipes.single.title, 'Untitled');
      expect(recipes.single.ingredients, isEmpty);
      expect(recipes.single.steps, isEmpty);
    });

    test('skips non-map elements', () {
      const json = '[1, "x", {"title":"Only"}]';
      final recipes = parseRecipesFromModelText(json);
      expect(recipes, hasLength(1));
      expect(recipes.single.title, 'Only');
    });
  });
}
