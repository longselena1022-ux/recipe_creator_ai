import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_creator_ai/models/recipe.dart';
import 'package:recipe_creator_ai/models/saved_recipe_entry.dart';
import 'package:recipe_creator_ai/services/saved_recipes_repository.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.fromIngredients,
    this.initialSavedEntry,
    this.userId,
    this.savedRecipesRepository,
  });

  final Recipe recipe;
  final String? fromIngredients;
  final SavedRecipeEntry? initialSavedEntry;
  final String? userId;
  final SavedRecipesRepository? savedRecipesRepository;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late final List<bool> _checked;
  SavedRecipeEntry? _savedEntry;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _checked = List.filled(widget.recipe.ingredients.length, false);
    _savedEntry = widget.initialSavedEntry;
  }

  String _estimatePrepTime() {
    final mins = (widget.recipe.steps.length * 7).clamp(10, 90);
    return '$mins min';
  }

  Future<void> _toggleSave() async {
    final uid = widget.userId;
    final repo = widget.savedRecipesRepository;
    if (uid == null || repo == null || _saving || _savedEntry != null) return;
    setState(() => _saving = true);
    try {
      final id = await repo.saveRecipe(
        userId: uid,
        recipe: widget.recipe,
        fromIngredients: widget.fromIngredients,
      );
      if (!mounted) return;
      setState(() {
        _savedEntry = SavedRecipeEntry(
          id: id,
          recipe: widget.recipe,
          liked: false,
          savedAt: DateTime.now(),
          fromIngredients: widget.fromIngredients,
        );
        _saving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    final uid = widget.userId;
    final repo = widget.savedRecipesRepository;
    final entry = _savedEntry;
    if (uid == null || repo == null || entry == null) return;
    final next = !entry.liked;
    try {
      await repo.setLiked(uid, entry.id, next);
      if (!mounted) return;
      setState(() => _savedEntry = entry.copyWith(liked: next));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update: $e')),
        );
      }
    }
  }

  void _startCooking() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => _CookingModeSheet(steps: widget.recipe.steps),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final recipe = widget.recipe;
    final canSave =
        widget.userId != null && widget.savedRecipesRepository != null;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (canSave)
                if (_savedEntry != null)
                  IconButton(
                    tooltip: _savedEntry!.liked ? 'Unlike' : 'Like',
                    icon: Icon(
                      _savedEntry!.liked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _savedEntry!.liked
                          ? Colors.red.shade300
                          : Colors.white,
                    ),
                    onPressed: _toggleLike,
                  )
                else
                  IconButton(
                    tooltip: 'Save recipe',
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.bookmark_add_outlined),
                    onPressed: _toggleSave,
                  ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 72, 20),
              title: Text(
                recipe.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: Colors.white,
                  shadows: const [
                    Shadow(blurRadius: 12, color: Colors.black38),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Sage-to-sage-light gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primary,
                          Color.lerp(cs.primary, cs.primaryContainer, 0.55)!,
                        ],
                      ),
                    ),
                  ),
                  // Decorative food icon
                  Positioned(
                    right: -28,
                    top: -28,
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 220,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Positioned(
                    left: -16,
                    bottom: 40,
                    child: Icon(
                      Icons.spa_outlined,
                      size: 100,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                  // Bottom fade so title is readable
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            cs.primary.withValues(alpha: 0.85),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Meta chips row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                        icon: Icons.schedule_outlined,
                        label: _estimatePrepTime(),
                        cs: cs,
                      ),
                      _MetaChip(
                        icon: Icons.restaurant_outlined,
                        label: '${recipe.ingredients.length} ingredients',
                        cs: cs,
                      ),
                      _MetaChip(
                        icon: Icons.format_list_numbered,
                        label: '${recipe.steps.length} steps',
                        cs: cs,
                      ),
                      if (_savedEntry != null)
                        _MetaChip(
                          icon: _savedEntry!.liked
                              ? Icons.favorite
                              : Icons.bookmark,
                          label: _savedEntry!.liked ? 'Liked' : 'Saved',
                          cs: cs,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Start Cooking CTA
                  FilledButton.icon(
                    onPressed: _startCooking,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Cooking'),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.secondary,
                      foregroundColor: cs.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                      elevation: 0,
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // ── Ingredients ───────────────────────────────────────────
                  Row(
                    children: [
                      Text(
                        'Ingredients',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${recipe.ingredients.length} items',
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap to check off as you gather ingredients.',
                    style: GoogleFonts.workSans(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...List.generate(recipe.ingredients.length, (i) {
                    final done = _checked[i];
                    return GestureDetector(
                      onTap: () => setState(() => _checked[i] = !done),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: done
                              ? cs.surfaceContainerHigh
                              : cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: done
                              ? []
                              : [
                                  BoxShadow(
                                    color: cs.onSurface.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done ? cs.primary : Colors.transparent,
                                border: Border.all(
                                  color: done
                                      ? cs.primary
                                      : cs.outlineVariant,
                                  width: 2,
                                ),
                              ),
                              child: done
                                  ? Icon(
                                      Icons.check,
                                      size: 13,
                                      color: cs.onPrimary,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                recipe.ingredients[i],
                                style: GoogleFonts.workSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: done
                                      ? cs.onSurface.withValues(alpha: 0.4)
                                      : cs.onSurface,
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : null,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  // Chef's tip
                  if (widget.fromIngredients?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9D377).withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: Color(0xFF7D600D),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Chef's Tip",
                                  style: GoogleFonts.workSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: const Color(0xFF7D600D),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Generated from: ${widget.fromIngredients}',
                                  style: GoogleFonts.workSans(
                                    fontSize: 13,
                                    color: cs.onSurface.withValues(alpha: 0.7),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 36),
                  // ── Preparation Steps ─────────────────────────────────────
                  Text(
                    'Preparation\nSteps',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      letterSpacing: -0.4,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(recipe.steps.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: cs.onSurface.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 7),
                                child: Text(
                                  recipe.steps[i],
                                  style: GoogleFonts.workSans(
                                    fontSize: 15,
                                    color: cs.onSurface,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.cs,
  });

  final IconData icon;
  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.workSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CookingModeSheet extends StatefulWidget {
  const _CookingModeSheet({required this.steps});
  final List<String> steps;

  @override
  State<_CookingModeSheet> createState() => _CookingModeSheetState();
}

class _CookingModeSheetState extends State<_CookingModeSheet> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = widget.steps.length;
    final isDone = _current >= total;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isDone ? 'All done!' : 'Step ${_current + 1} of $total',
                    style: GoogleFonts.workSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Text(
                  '${((_current / total) * 100).round()}%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: isDone ? 1.0 : _current / total,
                backgroundColor: cs.surfaceContainerHighest,
                color: cs.primary,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 24),
            if (!isDone) ...[
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  widget.steps[_current],
                  style: GoogleFonts.workSans(
                    fontSize: 16,
                    height: 1.6,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (_current > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _current--),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: cs.outlineVariant),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('← Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => setState(() => _current++),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        _current < total - 1 ? 'Next Step →' : 'Finish!',
                        style: GoogleFonts.workSans(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, Color.lerp(cs.primary, cs.primaryContainer, 0.5)!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Your dish is ready!\nEnjoy your meal. 🍽️',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.workSans(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
