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
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF456C62),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFBCE6D9),
          onPrimaryContainer: Color(0xFF2F554C),
          secondary: Color(0xFF915700),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFFFDCBC),
          onSecondaryContainer: Color(0xFF774600),
          tertiary: Color(0xFF7D600D),
          onTertiary: Colors.white,
          surface: Color(0xFFFEFDF1),
          onSurface: Color(0xFF353A26),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Color(0xFFFAFAEB),
          surfaceContainer: Color(0xFFF4F5E2),
          surfaceContainerHigh: Color(0xFFEDF0D8),
          surfaceContainerHighest: Color(0xFFE7EBCF),
          onSurfaceVariant: Color(0xFF626750),
          outline: Color(0xFF7E836B),
          outlineVariant: Color(0xFFB7BCA2),
          error: Color(0xFFB33938),
          onError: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
