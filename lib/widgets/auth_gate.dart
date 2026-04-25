import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_creator_ai/screens/home_screen.dart';
import 'package:recipe_creator_ai/screens/login_screen.dart';
import 'package:recipe_creator_ai/services/recipe_generation_service.dart';
import 'package:recipe_creator_ai/services/recipe_history_repository.dart';
import 'package:recipe_creator_ai/services/saved_recipes_repository.dart';
import 'package:recipe_creator_ai/services/user_profile_repository.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return LoginScreen(
            userProfileRepository: UserProfileRepository(FirebaseFirestore.instance),
          );
        }
        return HomeScreen(
          generationService: RecipeGenerationService(),
          historyRepository: RecipeHistoryRepository(FirebaseFirestore.instance),
          savedRecipesRepository:
              SavedRecipesRepository(FirebaseFirestore.instance),
          userProfileRepository: UserProfileRepository(FirebaseFirestore.instance),
        );
      },
    );
  }
}
