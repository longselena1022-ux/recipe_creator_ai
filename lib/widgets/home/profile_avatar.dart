import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    String initial(String s) {
      final t = s.trim();
      return t.isEmpty ? '?' : t[0].toUpperCase();
    }

    final letter = (user?.displayName?.trim().isNotEmpty == true)
        ? initial(user!.displayName!)
        : (user?.email?.trim().isNotEmpty == true
              ? initial(user!.email!)
              : '?');

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.plusJakartaSans(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}
