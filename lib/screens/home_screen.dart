import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_creator_ai/models/recipe.dart';
import 'package:recipe_creator_ai/models/saved_recipe_entry.dart';
import 'package:recipe_creator_ai/screens/profile_screen.dart';
import 'package:recipe_creator_ai/screens/recipe_detail_screen.dart';
import 'package:recipe_creator_ai/services/recipe_generation_service.dart';
import 'package:recipe_creator_ai/services/recipe_history_repository.dart';
import 'package:recipe_creator_ai/services/saved_recipes_repository.dart';
import 'package:recipe_creator_ai/services/user_profile_repository.dart';
import 'package:recipe_creator_ai/utils/ingredient_emoji.dart';
import 'package:recipe_creator_ai/utils/recipe_match.dart';
import 'package:recipe_creator_ai/widgets/home/blurred_bottom_nav.dart';
import 'package:recipe_creator_ai/widgets/home/profile_avatar.dart';
import 'package:recipe_creator_ai/widgets/home/recent_generation_tile.dart';
import 'package:recipe_creator_ai/widgets/home/saved_recipe_tile.dart';
import 'package:recipe_creator_ai/widgets/home/seasonal_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.generationService,
    this.historyRepository,
    this.savedRecipesRepository,
    this.userProfileRepository,
    this.userProvider,
  });

  final RecipeGenerationService generationService;
  final RecipeHistoryRepository? historyRepository;
  final SavedRecipesRepository? savedRecipesRepository;
  final UserProfileRepository? userProfileRepository;
  final User? Function()? userProvider;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _addIngredientController = TextEditingController();
  final List<String> _pantryItems = [];
  List<Recipe> _recipes = [];
  bool _loading = false;
  String? _error;
  int _navIndex = 0;

  static const List<String> _quickAddSuggestions = [
    'Onion',
    'Garlic',
    'Eggs',
    'Milk',
  ];

  User? get _currentUser {
    final custom = widget.userProvider;
    if (custom != null) return custom();
    return FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _addIngredientController.dispose();
    super.dispose();
  }

  String get _ingredientsPrompt =>
      _pantryItems.map((e) => e.trim()).where((e) => e.isNotEmpty).join(', ');

  void _addIngredientFromField() {
    final raw = _addIngredientController.text;
    if (raw.trim().isEmpty) return;
    for (final part in raw.split(',')) {
      _addIngredient(part);
    }
    _addIngredientController.clear();
  }

  void _addIngredient(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return;
    final lower = name.toLowerCase();
    if (_pantryItems.any((e) => e.toLowerCase() == lower)) return;
    setState(() => _pantryItems.add(name));
  }

  void _removeIngredientAt(int index) {
    setState(() => _pantryItems.removeAt(index));
  }

  void _clearPantry() {
    if (_pantryItems.isEmpty) return;
    setState(() => _pantryItems.clear());
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.generationService.generate(_ingredientsPrompt);
      if (!mounted) return;
      setState(() {
        _recipes = list;
        _loading = false;
        _navIndex = 1;
      });
      final user = _currentUser;
      final repo = widget.historyRepository;
      if (user != null && repo != null && list.isNotEmpty) {
        try {
          await repo.saveGeneration(
            userId: user.uid,
            ingredientsText: _ingredientsPrompt,
            recipes: list,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not save history: $e')),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showRecipeDetail(
    Recipe recipe, {
    SavedRecipeEntry? savedEntry,
    String? fromIngredients,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecipeDetailScreen(
          recipe: recipe,
          fromIngredients: fromIngredients,
          initialSavedEntry: savedEntry,
          userId: _currentUser?.uid,
          savedRecipesRepository: widget.savedRecipesRepository,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteSaved(SavedRecipeEntry entry) async {
    final user = _currentUser;
    final repo = widget.savedRecipesRepository;
    if (user == null || repo == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        title: const Text('Remove saved recipe?'),
        content: Text('Remove "${entry.recipe.title}" from your saved list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await repo.deleteSavedRecipe(user.uid, entry.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe removed from saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    final repo = widget.historyRepository;
    final savedRepo = widget.savedRecipesRepository;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(context, user, cs),
            Expanded(
              child: IndexedStack(
                index: _navIndex,
                children: [
                  _buildInventoryTab(context, cs),
                  _buildRecipesTab(context, user, repo, savedRepo, cs),
                  _buildSavedTab(context, user, savedRepo, cs),
                  _buildProfileTab(context, user, cs),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BlurredBottomNav(
        selectedIndex: _navIndex,
        onSelect: (i) => setState(() => _navIndex = i),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, User? user, ColorScheme cs) {
    final canMenu = widget.userProvider == null && user != null;
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Menu',
              onPressed: canMenu
                  ? () {
                      showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        builder: (ctx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.logout),
                                title: const Text('Sign out'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  FirebaseAuth.instance.signOut();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  : null,
              icon: Icon(
                Icons.menu,
                color: cs.onSurface.withValues(alpha: canMenu ? 1.0 : 0.35),
              ),
            ),
            Expanded(
              child: Text(
                'Recipe Creator AI',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: cs.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ProfileAvatar(user: user),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Inventory Tab ──────────────────────────────────────────────────────────

  Widget _buildInventoryTab(BuildContext context, ColorScheme cs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            28,
            20,
            MediaQuery.paddingOf(context).bottom + 80,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: wide
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "What's in your\nKitchen?",
                      textAlign: wide ? TextAlign.start : TextAlign.start,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        color: cs.onSurface,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Add the ingredients you have on hand\nto discover perfect recipes.',
                      style: GoogleFonts.workSans(
                        fontSize: 16,
                        color: cs.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildAddIngredientsCard(context, cs),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 7,
                            child: _buildInventoryCard(context, cs),
                          ),
                        ],
                      )
                    else ...[
                      _buildAddIngredientsCard(context, cs),
                      const SizedBox(height: 16),
                      _buildInventoryCard(context, cs),
                    ],
                    const SizedBox(height: 28),
                    SeasonalBanner(onAdd: () => _addIngredient('Asparagus')),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddIngredientsCard(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add_circle_outline, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Add Ingredients',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _addIngredientController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addIngredientFromField(),
                  style: GoogleFonts.workSans(
                    fontSize: 15,
                    color: cs.onSurface,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Cherry Tomatoes',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _addIngredientFromField,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'QUICK ADD',
            style: GoogleFonts.workSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAddSuggestions.map((s) {
              return ActionChip(
                label: Text(s),
                onPressed: () => _addIngredient(s),
                backgroundColor: cs.secondaryContainer,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                labelStyle: GoogleFonts.workSans(
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.kitchen, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Your Inventory',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.primaryFixed,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_pantryItems.length}',
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: cs.onPrimaryFixedVariant,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _pantryItems.isEmpty ? null : _clearPantry,
                style: TextButton.styleFrom(
                  foregroundColor: cs.error,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: GoogleFonts.workSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                child: const Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: _pantryItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.kitchen_outlined,
                            size: 40,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Add ingredients to build\nyour kitchen.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.workSans(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _pantryItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final item = _pantryItems[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                emojiForIngredient(item),
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.workSans(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _removeIngredientAt(i),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHigh,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error!,
                style: GoogleFonts.workSans(
                  color: cs.error,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _generate,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: cs.primary.withValues(alpha: 0.45),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(Icons.auto_awesome, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _loading ? 'Finding Recipes…' : 'Find Recipes',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Recipes Tab ────────────────────────────────────────────────────────────

  Widget _buildRecipesTab(
    BuildContext context,
    User? user,
    RecipeHistoryRepository? repo,
    SavedRecipesRepository? savedRepo,
    ColorScheme cs,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        MediaQuery.paddingOf(context).bottom + 80,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: GoogleFonts.workSans(color: cs.error),
                  ),
                ),
              if (_recipes.isEmpty) ...[
                const SizedBox(height: 48),
                Icon(
                  Icons.restaurant_menu_outlined,
                  size: 64,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 20),
                Text(
                  'No recipes yet',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add ingredients on the Inventory tab\nand tap Find Recipes.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.workSans(
                    fontSize: 15,
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _navIndex = 0),
                    icon: const Icon(Icons.kitchen_outlined),
                    label: const Text('Go to Inventory'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.outline),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Curated\nFor You',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    color: cs.onSurface,
                    height: 1.1,
                  ),
                ),
                if (_ingredientsPrompt.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Based on: $_ingredientsPrompt',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.workSans(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _buildFeaturedCard(context, _recipes.first, savedRepo, user, cs),
                const SizedBox(height: 12),
                ..._recipes.skip(1).map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildRecipeCard(context, r, savedRepo, user, cs),
                      ),
                    ),
              ],
              if (user != null && repo != null) ...[
                const SizedBox(height: 32),
                _sectionTitle('Recent', cs),
                const SizedBox(height: 12),
                StreamBuilder<List<GenerationRecord>>(
                  stream: repo.watchRecent(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'Recent: ${snapshot.error}',
                        style: GoogleFonts.workSans(color: cs.error),
                      );
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return Text(
                        'Saved generations will appear here.',
                        style: GoogleFonts.workSans(
                          color: cs.onSurfaceVariant,
                        ),
                      );
                    }
                    return Column(
                      children: items.map((g) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RecentGenerationTile(
                            record: g,
                            onTap: () => _showRecentGeneration(g),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(
    BuildContext context,
    Recipe recipe,
    SavedRecipesRepository? savedRepo,
    User? user,
    ColorScheme cs,
  ) {
    final pct = matchPercent(recipe, _pantryItems);
    final status = statusText(recipe, _pantryItems);
    final allHome = status == 'All Ingredients at Home';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => _showRecipeDetail(recipe, fromIngredients: _ingredientsPrompt),
        child: Container(
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
          padding: const EdgeInsets.all(24),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -28,
                bottom: -28,
                child: Icon(
                  Icons.star_rounded,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: cs.secondary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              "Chef's Choice",
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
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$pct% match',
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    recipe.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        estimateTime(recipe),
                        style: GoogleFonts.workSans(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(
                        allHome
                            ? Icons.check_circle_outline
                            : Icons.shopping_bag_outlined,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          status,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.workSans(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _showRecipeDetail(
                            recipe,
                            fromIngredients: _ingredientsPrompt,
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: const Text('View Recipe'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: cs.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const StadiumBorder(),
                            textStyle: GoogleFonts.workSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      if (user != null && savedRepo != null) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () async {
                            try {
                              await savedRepo.saveRecipe(
                                userId: user.uid,
                                recipe: recipe,
                                fromIngredients: _ingredientsPrompt,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Recipe saved.')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Could not save: $e')),
                                );
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(
                              Icons.bookmark_add_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(
    BuildContext context,
    Recipe recipe,
    SavedRecipesRepository? savedRepo,
    User? user,
    ColorScheme cs,
  ) {
    final pct = matchPercent(recipe, _pantryItems);
    final status = statusText(recipe, _pantryItems);
    final allHome = status == 'All Ingredients at Home';

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showRecipeDetail(recipe, fromIngredients: _ingredientsPrompt),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      recipe.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: cs.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$pct%',
                      style: GoogleFonts.workSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recipe.ingredients.take(4).join(', ') +
                    (recipe.ingredients.length > 4 ? '…' : ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.workSans(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 13,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    estimateTime(recipe),
                    style: GoogleFonts.workSans(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: allHome
                          ? cs.primaryContainer
                          : cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          allHome
                              ? Icons.check_circle_outline
                              : Icons.shopping_bag_outlined,
                          size: 11,
                          color: allHome
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          status,
                          style: GoogleFonts.workSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: allHome
                                ? cs.onPrimaryContainer
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (user != null && savedRepo != null)
                    GestureDetector(
                      onTap: () async {
                        try {
                          await savedRepo.saveRecipe(
                            userId: user.uid,
                            recipe: recipe,
                            fromIngredients: _ingredientsPrompt,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Recipe saved.')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not save: $e')),
                            );
                          }
                        }
                      },
                      child: Icon(
                        Icons.bookmark_add_outlined,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(width: 10),
                  Text(
                    'View',
                    style: GoogleFonts.workSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: cs.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, ColorScheme cs) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: cs.onSurface,
        letterSpacing: -0.3,
      ),
    );
  }

  // ─── Saved Tab ──────────────────────────────────────────────────────────────

  Widget _buildSavedTab(
    BuildContext context,
    User? user,
    SavedRecipesRepository? savedRepo,
    ColorScheme cs,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        MediaQuery.paddingOf(context).bottom + 80,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: user == null || savedRepo == null
              ? Text(
                  'Sign in to save and view recipes here.',
                  style: GoogleFonts.workSans(color: cs.onSurfaceVariant),
                )
              : StreamBuilder<List<SavedRecipeEntry>>(
                  stream: savedRepo.watchSaved(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'Saved: ${snapshot.error}',
                        style: GoogleFonts.workSans(color: cs.error),
                      );
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 48),
                          Icon(
                            Icons.bookmark_outline,
                            size: 56,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No saved recipes yet',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Save recipes from suggestions to find them here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.workSans(
                              color: cs.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: items.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SavedRecipeTile(
                            entry: entry,
                            onTap: () => _showRecipeDetail(
                              entry.recipe,
                              savedEntry: entry,
                              fromIngredients: entry.fromIngredients,
                            ),
                            onToggleLike: () async {
                              try {
                                await savedRepo.setLiked(
                                  user.uid,
                                  entry.id,
                                  !entry.liked,
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Could not update: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            onDelete: () => _confirmDeleteSaved(entry),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
        ),
      ),
    );
  }

  // ─── Profile Tab ────────────────────────────────────────────────────────────

  Widget _buildProfileTab(BuildContext context, User? user, ColorScheme cs) {
    return ProfileScreen(
      user: user,
      userProfileRepository: widget.userProfileRepository,
      savedRecipesRepository: widget.savedRecipesRepository,
      historyRepository: widget.historyRepository,
      canSignOut: widget.userProvider == null,
      embedded: true,
    );
  }

  // ─── Utilities ──────────────────────────────────────────────────────────────

  void _showRecentGeneration(GenerationRecord g) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.paddingOf(ctx).bottom + 20,
          ),
          child: ListView(
            children: [
              Text(
                g.ingredientsText.isEmpty ? 'Saved run' : g.ingredientsText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...g.recipes.map(
                (r) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text(
                      r.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_currentUser != null &&
                            widget.savedRecipesRepository != null)
                          IconButton(
                            tooltip: 'Save recipe',
                            icon: const Icon(Icons.bookmark_add_outlined),
                            onPressed: () async {
                              final u = _currentUser!;
                              final sr = widget.savedRecipesRepository!;
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await sr.saveRecipe(
                                  userId: u.uid,
                                  recipe: r,
                                  fromIngredients: g.ingredientsText,
                                );
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Recipe saved.')),
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Could not save: $e')),
                                );
                              }
                            },
                          ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showRecipeDetail(r, fromIngredients: g.ingredientsText);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
