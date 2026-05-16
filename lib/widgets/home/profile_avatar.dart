import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_creator_ai/models/profile_avatars.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.user,
    this.avatarId,
    this.size = 38,
  });

  final User? user;
  final String? avatarId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avatar = avatarById(avatarId);

    final BoxDecoration decoration;
    final Widget content;
    if (avatar != null) {
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        color: avatarBg(cs, avatar.id),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
      content = Text(
        avatar.emoji,
        style: TextStyle(fontSize: size * 0.52),
      );
    } else {
      String initial(String s) {
        final t = s.trim();
        return t.isEmpty ? '?' : t[0].toUpperCase();
      }

      final letter = (user?.displayName?.trim().isNotEmpty == true)
          ? initial(user!.displayName!)
          : (user?.email?.trim().isNotEmpty == true
                ? initial(user!.email!)
                : '?');

      decoration = BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
      content = Text(
        letter,
        style: GoogleFonts.plusJakartaSans(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.4,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      alignment: Alignment.center,
      child: content,
    );
  }
}
