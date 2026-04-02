import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:recipe_creator_ai/firebase_options.dart';
import 'package:recipe_creator_ai/screens/home_screen.dart';
import 'package:recipe_creator_ai/services/recipe_generation_service.dart';
import 'package:recipe_creator_ai/services/recipe_history_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e, st) {
    debugPrint('Anonymous sign-in failed (enable Anonymous in Firebase Console): $e');
    debugPrint('$st');
  }
  runApp(const RecipeCreatorApp());
}

class RecipeCreatorApp extends StatelessWidget {
  const RecipeCreatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Creator AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: HomeScreen(
        generationService: RecipeGenerationService(),
        historyRepository: RecipeHistoryRepository(FirebaseFirestore.instance),
      ),
    );
  }
}
