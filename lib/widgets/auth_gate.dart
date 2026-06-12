import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_creator_ai/models/user_profile.dart';
import 'package:recipe_creator_ai/screens/home_screen.dart';
import 'package:recipe_creator_ai/screens/login_screen.dart';
import 'package:recipe_creator_ai/screens/onboarding/onboarding_flow.dart';
import 'package:recipe_creator_ai/services/recipe_generation_service.dart';
import 'package:recipe_creator_ai/services/recipe_history_repository.dart';
import 'package:recipe_creator_ai/services/saved_recipes_repository.dart';
import 'package:recipe_creator_ai/services/user_profile_repository.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfileRepository =
        UserProfileRepository(FirebaseFirestore.instance);

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
          return LoginScreen(userProfileRepository: userProfileRepository);
        }
        return _SignedInRouter(
          user: user,
          userProfileRepository: userProfileRepository,
        );
      },
    );
  }
}

/// Routes a signed-in user to onboarding or the home screen based on whether
/// their profile has completed onboarding.
class _SignedInRouter extends StatelessWidget {
  const _SignedInRouter({
    required this.user,
    required this.userProfileRepository,
  });

  final User user;
  final UserProfileRepository userProfileRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: userProfileRepository.watchProfile(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = snapshot.data;
        if (profile == null || !profile.onboardingComplete) {
          return OnboardingFlow(
            userId: user.uid,
            userProfileRepository: userProfileRepository,
          );
        }
        return HomeScreen(
          generationService: RecipeGenerationService(),
          historyRepository:
              RecipeHistoryRepository(FirebaseFirestore.instance),
          savedRecipesRepository:
              SavedRecipesRepository(FirebaseFirestore.instance),
          userProfileRepository: userProfileRepository,
        );
      },
    );
  }
}
