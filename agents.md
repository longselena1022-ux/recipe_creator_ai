# Agent notes — Recipe Creator AI

Concise context for coding agents working in this repo. Read this at the start of a session when touching app logic, Firebase, or AI features.

## What this app is

Flutter app: user signs in, enters ingredients they have, gets **3–5 recipe suggestions** from an LLM. Signed-in users get **Firestore-backed history** of past generations.

## Tech stack

- **Flutter** / **Dart** `^3.10.8` (`pubspec.yaml`)
- **Firebase**: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_ai`
- **AI**: Firebase AI SDK → Google AI, model **`gemini-2.5-flash-lite`** (`RecipeGenerationService`)

## Entry and navigation

- `lib/main.dart`: `WidgetsFlutterBinding.ensureInitialized()`, `Firebase.initializeApp(name: 'Recipe Creator AI', options: DefaultFirebaseOptions.currentPlatform)`, `MaterialApp` → `home: AuthGate()`.
- `lib/widgets/auth_gate.dart`: `StreamBuilder` on `FirebaseAuth.instance.authStateChanges()`. No user → `AuthScreen`; signed in → `HomeScreen` with **new** `RecipeGenerationService()`, `RecipeHistoryRepository(FirebaseFirestore.instance)`, and `SavedRecipesRepository(FirebaseFirestore.instance)` each build (no global DI).

## Authentication

- `lib/screens/auth_screen.dart`: email/password **sign in** and **create account** (`SegmentedButton`), validation, `FirebaseAuthException` → user-facing `SnackBar`s. No social providers in code.

## Core user flow (home)

- `lib/screens/home_screen.dart`: multiline ingredients field → **Generate recipes** → `RecipeGenerationService.generate(text)`. Optional `savedRecipesRepository` for saved/liked recipes (also injected from `AuthGate` when signed in).
- On success, if `user` + `historyRepository` exist and list non-empty → `saveGeneration` (errors shown via `SnackBar`, generation still shown).
- **Recent**: `StreamBuilder` on `repo.watchRecent(user.uid)` (cards → bottom sheet → tap recipe → detail sheet; per-recipe save action).
- **Saved**: when `savedRecipesRepository` is set, `StreamBuilder` on `watchSaved(user.uid)` — users can **save** individual recipes (bookmark on suggestion/history rows or **Save recipe** in the detail sheet), **like** (`liked` on Firestore docs), and **delete** (remove doc, with confirm on list and in detail).
- **Suggestions**: current run’s `List<Recipe>` as cards → detail bottom sheet (bookmark to save without opening).
- **Test hook**: optional `userProvider` overrides `FirebaseAuth.instance.currentUser`. Sign-out in the AppBar appears only when `userProvider` is **unset** and `currentUser` is non-null (normal signed-in app use).

## Recipe generation

- `lib/services/recipe_generation_service.dart`: builds `FirebaseAI.googleAI(auth: …).generativeModel` with a **system instruction** requiring **only** a JSON **array** of objects `{ title, ingredients[], steps[] }`. User message includes ingredients or a fallback when empty.
- On `FormatException` from parsing, **one retry** with a stricter “JSON only” suffix.
- Constructor accepts optional `FirebaseAI?` and `FirebaseAuth?` for tests/overrides.

## Parsing model output

- `lib/utils/recipe_response_parser.dart`: `stripMarkdownFences`, `parseRecipesFromModelText` → `jsonDecode` → `Recipe.fromJson` per element. Throws `FormatException` if not a JSON array.

## Data model

- `lib/models/recipe.dart`: `title`, `ingredients` (`List<String>`), `steps` (`List<String>`), `fromJson` / `toJson`.
- `lib/models/saved_recipe_entry.dart`: Firestore row for a user-saved recipe (`id`, `recipe`, `liked`, `savedAt`, optional `fromIngredients`).
- `lib/services/recipe_history_repository.dart`: `GenerationRecord` (id, ingredientsText, recipes, createdAt from `Timestamp`).
- `lib/services/saved_recipes_repository.dart`: `saveRecipe` (returns new doc id), `deleteSavedRecipe`, `setLiked`, `watchSaved` (`orderBy('savedAt', descending: true)`).

## Firestore shape

- Path: `users/{userId}/generations` (subcollection).
- Document fields on save: `userId`, `ingredients` (string), `recipes` (list of maps from `Recipe.toJson()`), `createdAt` (`FieldValue.serverTimestamp()`).
- `watchRecent`: `orderBy('createdAt', descending: true)`, `limit(8)`. **Requires a Firestore index** if not auto-created for this composite query.
- Path: `users/{userId}/savedRecipes` (subcollection). Document fields: `userId`, `recipe` (map from `Recipe.toJson()`), `liked` (bool), `savedAt` (`FieldValue.serverTimestamp()`), optional `fromIngredients` (string). `watchSaved` orders by `savedAt` descending.

## Firebase configuration

- `lib/firebase_options.dart`: file comment says values may be **placeholders** until `dart run flutterfire_cli:flutterfire configure`. Agents should not assume production keys are present.

## Tests

- `test/recipe_response_parser_test.dart`: fence stripping and JSON parsing.
- `test/widget_test.dart`: default Flutter template (may not reflect current UI).

## Repo extras (non-Dart)

- `stitch_ingredient_recipe_finder 2/`: HTML/screenshots and `DESIGN.md` — **design reference**, not wired into the Flutter app unless integrated explicitly.

## Commands (verify locally)

- `flutter pub get`
- `flutter analyze`
- `flutter test`

## Conventions for edits

- Prefer **constructor injection** where it already exists (`HomeScreen`, `RecipeGenerationService`) for testability.
- Keep **system prompt and JSON contract** in `RecipeGenerationService` aligned with `Recipe.fromJson` and `parseRecipesFromModelText`.
- UI strings and SnackBars are user-facing; match existing tone and error handling patterns.
