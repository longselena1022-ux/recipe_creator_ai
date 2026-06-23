import 'package:flutter/material.dart';
import 'package:recipe_creator_ai/theme/app_theme.dart';

/// A single selectable colour theme for the app.
class AppThemeOption {
  const AppThemeOption({
    required this.id,
    required this.name,
    required this.description,
    required this.colorScheme,
  });

  /// Stable identifier persisted to disk. Never change once shipped.
  final String id;
  final String name;
  final String description;
  final ColorScheme colorScheme;

  Brightness get brightness => colorScheme.brightness;
}

/// Theme used before the user has picked one (and the fallback if a stored id
/// is no longer recognised).
const String kDefaultThemeId = 'light';

ColorScheme _seeded(Color seed, Brightness brightness) =>
    ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

/// All ten selectable themes, in display order.
final List<AppThemeOption> kAppThemes = [
  AppThemeOption(
    id: 'light',
    name: 'Light',
    description: 'Bright surfaces and warm whites.',
    colorScheme: lightColorScheme,
  ),
  AppThemeOption(
    id: 'dark',
    name: 'Dark',
    description: 'Low-light tones, easy on the eyes.',
    colorScheme: darkColorScheme,
  ),
  AppThemeOption(
    id: 'rose_gold',
    name: 'Rose Gold',
    description: 'Soft copper and blush highlights.',
    colorScheme: _seeded(const Color(0xFFB76E79), Brightness.light),
  ),
  AppThemeOption(
    id: 'lavender_dream',
    name: 'Lavender Dream',
    description: 'Calm lilacs and muted violets.',
    colorScheme: _seeded(const Color(0xFF9F86C0), Brightness.light),
  ),
  AppThemeOption(
    id: 'sapphire_blue',
    name: 'Sapphire Blue',
    description: 'Deep jewel-toned midnight blues.',
    colorScheme: _seeded(const Color(0xFF1A4FB8), Brightness.dark),
  ),
  AppThemeOption(
    id: 'emerald_luxe',
    name: 'Emerald Luxe',
    description: 'Rich forest greens with gold warmth.',
    colorScheme: _seeded(const Color(0xFF1E8C5A), Brightness.dark),
  ),
  AppThemeOption(
    id: 'sunset_peach',
    name: 'Sunset Peach',
    description: 'Warm corals and golden-hour glow.',
    colorScheme: _seeded(const Color(0xFFFF8A5C), Brightness.light),
  ),
  AppThemeOption(
    id: 'champagne_gold',
    name: 'Champagne Gold',
    description: 'Creamy golds and elegant neutrals.',
    colorScheme: _seeded(const Color(0xFFC9A227), Brightness.light),
  ),
  AppThemeOption(
    id: 'ocean_pearl',
    name: 'Ocean Pearl',
    description: 'Fresh aquas and pearly teal.',
    colorScheme: _seeded(const Color(0xFF2BA6A0), Brightness.light),
  ),
  AppThemeOption(
    id: 'velvet_ruby',
    name: 'Velvet Ruby',
    description: 'Dramatic crimson on deep charcoal.',
    colorScheme: _seeded(const Color(0xFFB31336), Brightness.dark),
  ),
];

/// Resolves a stored id to a theme, falling back to the default when unknown.
AppThemeOption themeById(String? id) {
  return kAppThemes.firstWhere(
    (t) => t.id == id,
    orElse: () => kAppThemes.firstWhere((t) => t.id == kDefaultThemeId),
  );
}
