import 'package:flutter/material.dart';

/// A selectable dietary preference. The [key] is what gets persisted to the
/// user's profile; [label] and [icon] are for display.
class DietaryPreference {
  const DietaryPreference(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;
}

/// The canonical list of dietary preferences, shared by onboarding (where the
/// user selects them) and the profile screen (where they are displayed).
const List<DietaryPreference> kDietaryPreferences = [
  DietaryPreference('vegetarian', 'Vegetarian', Icons.restaurant),
  DietaryPreference('vegan', 'Vegan', Icons.spa),
  DietaryPreference('gluten_free', 'Gluten-Free', Icons.grain),
  DietaryPreference('keto', 'Keto', Icons.bolt),
  DietaryPreference('paleo', 'Paleo', Icons.forest),
  DietaryPreference('dairy_free', 'Dairy-Free', Icons.water_drop),
];

/// Renders stored preference [keys] as a comma-separated list of labels,
/// preserving the canonical order. Unknown keys fall back to a title-cased
/// version of the key so nothing is silently dropped.
String formatDietaryPreferences(List<String> keys) {
  if (keys.isEmpty) return '';
  final selected = keys.toSet();
  final labels = <String>[
    for (final pref in kDietaryPreferences)
      if (selected.remove(pref.key)) pref.label,
  ];
  // Any leftover keys weren't in the canonical list — show them readably.
  for (final key in selected) {
    labels.add(_titleCase(key));
  }
  return labels.join(', ');
}

String _titleCase(String key) {
  return key
      .split(RegExp(r'[_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
