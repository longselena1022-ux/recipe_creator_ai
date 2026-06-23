import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_creator_ai/main.dart';
import 'package:recipe_creator_ai/theme/app_themes.dart';

/// Lets the user browse and instantly apply any of the ten colour themes.
/// The selection is persisted by [ThemeController] so it survives restarts.
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppThemeScope.of(context);
    final cs = Theme.of(context).colorScheme;

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
          'Theme',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.paddingOf(context).bottom + 28,
          ),
          children: [
            Text(
              'Pick a look',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap any theme to apply it instantly. Your choice is saved '
              'automatically.',
              style: GoogleFonts.workSans(
                fontSize: 14,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.82,
              children: [
                for (final theme in kAppThemes)
                  _ThemeCard(
                    option: theme,
                    selected: controller.themeId == theme.id,
                    onTap: () => controller.setTheme(theme.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppThemeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outerCs = Theme.of(context).colorScheme;
    final cs = option.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: outerCs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? outerCs.primary
                  : outerCs.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: outerCs.onSurface.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Preview(cs: cs, selected: selected, accent: outerCs.primary),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      option.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: outerCs.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: outerCs.primary,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  option.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.workSans(
                    fontSize: 11.5,
                    color: outerCs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A miniature mock of the app rendered with the theme's own colours.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.cs,
    required this.selected,
    required this.accent,
  });

  final ColorScheme cs;
  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title bar.
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // A couple of "cards".
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Swatch row + chip.
            Row(
              children: [
                _swatch(cs.secondary),
                const SizedBox(width: 5),
                _swatch(cs.tertiary),
                const SizedBox(width: 5),
                _swatch(cs.secondaryContainer),
                const Spacer(),
                Container(
                  height: 12,
                  width: 26,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
