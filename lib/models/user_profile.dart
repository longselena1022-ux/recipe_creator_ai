import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarId,
    this.goal,
    this.cookingSkill,
    this.dietaryPreferences = const [],
    this.equipment = const [],
    this.onboardingComplete = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarId;

  /// Primary goal, e.g. `weight_loss`, `build_muscle`, `healthy_lifestyle`.
  final String? goal;

  /// Cooking skill level, e.g. `beginner`, `intermediate`, `pro`.
  final String? cookingSkill;

  /// Dietary preference keys, e.g. `vegetarian`, `vegan`.
  final List<String> dietaryPreferences;

  /// Kitchen equipment keys, e.g. `air_fryer`, `oven`.
  final List<String> equipment;

  /// Whether the user has finished (or skipped) the onboarding flow.
  final bool onboardingComplete;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      avatarId: data['avatarId']?.toString(),
      goal: data['goal']?.toString(),
      cookingSkill: data['cookingSkill']?.toString(),
      dietaryPreferences: _stringList(data['dietaryPreferences']),
      equipment: _stringList(data['equipment']),
      onboardingComplete: data['onboardingComplete'] == true,
      createdAt: _dateTimeFromAny(data['createdAt']),
      updatedAt: _dateTimeFromAny(data['updatedAt']),
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static DateTime? _dateTimeFromAny(Object? value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}
