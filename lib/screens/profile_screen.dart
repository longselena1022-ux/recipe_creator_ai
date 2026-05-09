import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_creator_ai/models/user_profile.dart';
import 'package:recipe_creator_ai/services/recipe_history_repository.dart';
import 'package:recipe_creator_ai/services/saved_recipes_repository.dart';
import 'package:recipe_creator_ai/services/user_profile_repository.dart';
import 'package:recipe_creator_ai/widgets/home/profile_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    this.userProfileRepository,
    this.savedRecipesRepository,
    this.historyRepository,
    this.canSignOut = true,
    this.embedded = false,
  });

  final User? user;
  final UserProfileRepository? userProfileRepository;
  final SavedRecipesRepository? savedRecipesRepository;
  final RecipeHistoryRepository? historyRepository;
  final bool canSignOut;

  /// When true the screen does not render its own Scaffold/AppBar so it can
  /// be dropped into an existing tabbed shell (e.g. HomeScreen).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final body = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        embedded ? 24 : 28,
        20,
        MediaQuery.paddingOf(context).bottom + (embedded ? 80 : 28),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _buildContent(context, cs),
        ),
      ),
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme cs) {
    final u = user;
    if (u == null) {
      return _emptyState(
        cs,
        icon: Icons.person_outline,
        title: 'Not signed in',
        message: 'Sign in to access your chef profile.',
      );
    }

    final profileStream = userProfileRepository?.watchProfile(u.uid);

    return StreamBuilder<UserProfile?>(
      stream: profileStream,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = (profile?.name.trim().isNotEmpty == true)
            ? profile!.name.trim()
            : (u.displayName?.trim().isNotEmpty == true
                ? u.displayName!.trim()
                : 'Chef');
        final email = (profile?.email.trim().isNotEmpty == true)
            ? profile!.email.trim()
            : (u.email ?? '');
        final memberSince = profile?.createdAt;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _heroCard(context, cs, name: name, email: email, user: u),
            const SizedBox(height: 20),
            _statsRow(context, cs, u),
            const SizedBox(height: 20),
            _sectionLabel('ACCOUNT', cs),
            const SizedBox(height: 10),
            _settingsCard(context, cs, [
              _SettingsRow(
                icon: Icons.edit_outlined,
                label: 'Edit display name',
                value: name,
                onTap: userProfileRepository == null
                    ? null
                    : () => _editName(context, u, name, email),
              ),
              _SettingsRow(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: email.isEmpty ? '—' : email,
              ),
              if (memberSince != null)
                _SettingsRow(
                  icon: Icons.cake_outlined,
                  label: 'Member since',
                  value: _formatMonthYear(memberSince),
                ),
            ]),
            const SizedBox(height: 20),
            _sectionLabel('PREFERENCES', cs),
            const SizedBox(height: 10),
            _settingsCard(context, cs, [
              _SettingsRow(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                value: 'Coming soon',
              ),
              _SettingsRow(
                icon: Icons.tune_rounded,
                label: 'Dietary preferences',
                value: 'Coming soon',
              ),
              _SettingsRow(
                icon: Icons.info_outline_rounded,
                label: 'About Recipe Creator AI',
                onTap: () => _showAbout(context),
              ),
            ]),
            if (canSignOut) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: Icon(Icons.logout_rounded, color: cs.error),
                  label: Text(
                    'Sign out',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: cs.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _heroCard(
    BuildContext context,
    ColorScheme cs, {
    required String name,
    required String email,
    required User user,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, Color.lerp(cs.primary, cs.primaryContainer, 0.5)!],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.28),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -28,
            bottom: -28,
            child: Icon(
              Icons.restaurant_menu_rounded,
              size: 160,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ProfileAvatar(user: user),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Home Chef',
                          style: GoogleFonts.workSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                  height: 1.1,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.workSans(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsRow(BuildContext context, ColorScheme cs, User u) {
    final saved = savedRecipesRepository;
    final history = historyRepository;
    return Row(
      children: [
        Expanded(
          child: _statTile(
            cs,
            icon: Icons.bookmark_rounded,
            label: 'Saved',
            stream: saved?.watchSaved(u.uid).map((l) => l.length),
            tone: _StatTone.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statTile(
            cs,
            icon: Icons.history_rounded,
            label: 'Generations',
            stream: history?.watchRecent(u.uid).map((l) => l.length),
            tone: _StatTone.secondary,
          ),
        ),
      ],
    );
  }

  Widget _statTile(
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required Stream<int>? stream,
    required _StatTone tone,
  }) {
    final bg = tone == _StatTone.primary
        ? cs.primaryContainer
        : cs.secondaryContainer;
    final fg = tone == _StatTone.primary
        ? cs.onPrimaryContainer
        : cs.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: fg),
          ),
          const SizedBox(height: 14),
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snap) {
              final value = stream == null ? '—' : (snap.data?.toString() ?? '–');
              return Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: fg,
                  letterSpacing: -0.8,
                  height: 1,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.workSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: fg.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.workSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _settingsCard(
    BuildContext context,
    ColorScheme cs,
    List<_SettingsRow> rows,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            _settingsRowWidget(context, cs, rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _settingsRowWidget(
    BuildContext context,
    ColorScheme cs,
    _SettingsRow row,
  ) {
    final clickable = row.onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: row.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(row.icon, size: 20, color: cs.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    if (row.value != null && row.value!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        row.value!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.workSans(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (clickable)
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(icon, size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.workSans(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(
    BuildContext context,
    User user,
    String currentName,
    String email,
  ) async {
    final controller = TextEditingController(text: currentName);
    final cs = Theme.of(context).colorScheme;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Display name',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'How should we call you?'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: FilledButton.styleFrom(shape: const StadiumBorder()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || result == currentName) return;
    try {
      await userProfileRepository?.ensureProfile(
        userId: user.uid,
        email: email,
        name: result,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update: $e')),
        );
      }
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Recipe Creator AI',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Crafted with calm capability.',
    );
  }

  static String _formatMonthYear(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

enum _StatTone { primary, secondary }

class _SettingsRow {
  _SettingsRow({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
}
