import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:recipe_creator_ai/firebase_options.dart';
import 'package:recipe_creator_ai/widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    name: 'Recipe Creator AI',
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: const AuthGate(),
    );
  }
}
