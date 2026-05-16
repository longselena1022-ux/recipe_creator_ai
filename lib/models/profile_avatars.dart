import 'package:flutter/material.dart';

/// A single selectable, emoji-based profile avatar.
class ProfileAvatarOption {
  const ProfileAvatarOption({required this.id, required this.emoji});

  final String id;
  final String emoji;
}

/// Food / chef themed avatars shown in the Netflix-style picker.
const List<ProfileAvatarOption> kProfileAvatars = [
  ProfileAvatarOption(id: 'chef_woman', emoji: '👩‍🍳'),
  ProfileAvatarOption(id: 'chef_man', emoji: '🧑‍🍳'),
  ProfileAvatarOption(id: 'fry', emoji: '🍳'),
  ProfileAvatarOption(id: 'avocado', emoji: '🥑'),
  ProfileAvatarOption(id: 'tomato', emoji: '🍅'),
  ProfileAvatarOption(id: 'chili', emoji: '🌶️'),
  ProfileAvatarOption(id: 'ramen', emoji: '🍜'),
  ProfileAvatarOption(id: 'salad', emoji: '🥗'),
  ProfileAvatarOption(id: 'cake', emoji: '🍰'),
  ProfileAvatarOption(id: 'pizza', emoji: '🍕'),
  ProfileAvatarOption(id: 'carrot', emoji: '🥕'),
  ProfileAvatarOption(id: 'cupcake', emoji: '🧁'),
  ProfileAvatarOption(id: 'burger', emoji: '🍔'),
  ProfileAvatarOption(id: 'sushi', emoji: '🍣'),
  ProfileAvatarOption(id: 'croissant', emoji: '🥐'),
  ProfileAvatarOption(id: 'fondue', emoji: '🫕'),
];

/// Returns the avatar matching [id], or `null` if it is unknown / not set.
ProfileAvatarOption? avatarById(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final a in kProfileAvatars) {
    if (a.id == id) return a;
  }
  return null;
}

/// Deterministic on-theme background tint for a given avatar [id], so tiles
/// look varied while staying within the app's [ColorScheme].
Color avatarBg(ColorScheme cs, String id) {
  final tones = [
    cs.primaryContainer,
    cs.secondaryContainer,
    cs.tertiaryContainer,
  ];
  var hash = 0;
  for (final code in id.codeUnits) {
    hash = (hash + code) & 0x7fffffff;
  }
  return tones[hash % tones.length];
}

/// Foreground tone paired with [avatarBg] for the same [id].
Color avatarFg(ColorScheme cs, String id) {
  final tones = [
    cs.onPrimaryContainer,
    cs.onSecondaryContainer,
    cs.onTertiaryContainer,
  ];
  var hash = 0;
  for (final code in id.codeUnits) {
    hash = (hash + code) & 0x7fffffff;
  }
  return tones[hash % tones.length];
}
