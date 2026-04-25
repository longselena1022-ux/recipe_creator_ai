import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_creator_ai/models/recipe.dart';
import 'package:recipe_creator_ai/models/saved_recipe_entry.dart';
import 'package:recipe_creator_ai/models/user_profile.dart';
import 'package:recipe_creator_ai/services/recipe_generation_service.dart';
import 'package:recipe_creator_ai/services/recipe_history_repository.dart';
import 'package:recipe_creator_ai/services/saved_recipes_repository.dart';
import 'package:recipe_creator_ai/services/user_profile_repository.dart';

/// Design tokens aligned with `stitch_ingredient_recipe_finder 2/ingredients_screen_my_design_system/code.html`.
abstract final class _PantryColors {
  static const Color background = Color(0xFFF9F9FF);
  static const Color primary = Color(0xFF2B5F8D);
  static const Color onSurface = Color(0xFF181C22);
  static const Color onSurfaceVariant = Color(0xFF414753);
  static const Color surfaceContainer = Color(0xFFECEDF7);
  static const Color surfaceContainerLow = Color(0xFFF2F3FD);
  static const Color secondaryContainer = Color(0xFFC4E6C4);
  static const Color onSecondaryContainer = Color(0xFF4A684D);
  static const Color outlineVariant = Color(0xFFC1C6D5);
  static const Color tertiaryContainer = Color(0xFF9161AF);
  static const Color onTertiaryContainer = Color(0xFFFFFBFF);
  static const Color primaryFixed = Color(0xFFD0E4FF);
  static const Color onPrimaryFixedVariant = Color(0xFF0C4A76);
  static const Color topBar = Color(0xFFFFFFFF);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.generationService,
    this.historyRepository,
    this.savedRecipesRepository,
    this.userProfileRepository,
    /// When set (e.g. in tests), used instead of [FirebaseAuth.instance.currentUser].
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
    if (custom != null) {
      return custom();
    }
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
    final raw = _addIngredientController.text.trim();
    if (raw.isEmpty) return;
    _addIngredient(raw);
    _addIngredientController.clear();
  }

  void _addIngredient(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return;
    final lower = name.toLowerCase();
    final exists = _pantryItems.any((e) => e.toLowerCase() == lower);
    if (exists) return;
    setState(() => _pantryItems.add(name));
  }

  void _removeIngredientAt(int index) {
    setState(() => _pantryItems.removeAt(index));
  }

  void _clearPantry() {
    if (_pantryItems.isEmpty) return;
    setState(() => _pantryItems.clear());
  }

  static String _emojiForIngredient(String name) {
    final n = name.toLowerCase();
    if (n.contains('tomato')) return '🍅';
    if (n.contains('pepper') || n.contains('bell')) return '🫑';
    if (n.contains('egg')) return '🥚';
    if (n.contains('cheese') || n.contains('cheddar')) return '🧀';
    if (n.contains('broccoli')) return '🥦';
    if (n.contains('pasta') || n.contains('noodle')) return '🍝';
    if (n.contains('onion')) return '🧅';
    if (n.contains('garlic')) return '🧄';
    if (n.contains('milk')) return '🥛';
    if (n.contains('asparagus')) return '🌿';
    return '🥗';
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list =
          await widget.generationService.generate(_ingredientsPrompt);
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom + 24;
        final user = _currentUser;
        final savedRepo = widget.savedRecipesRepository;
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 8, bottom: bottom),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return _RecipeDetailSheetBody(
                recipe: recipe,
                scrollController: scrollController,
                initialSavedEntry: savedEntry,
                fromIngredients: fromIngredients,
                userId: user?.uid,
                savedRecipesRepository: savedRepo,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteSaved(SavedRecipeEntry entry) async {
    final user = _currentUser;
    final repo = widget.savedRecipesRepository;
    if (user == null || repo == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove saved recipe?'),
        content: Text('Remove “${entry.recipe.title}” from your saved list?'),
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

    return Scaffold(
      backgroundColor: _PantryColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(context, user),
            Expanded(
              child: IndexedStack(
                index: _navIndex,
                children: [
                  _buildInventoryTab(context),
                  _buildRecipesTab(context, user, repo, savedRepo),
                  _buildSavedTab(context, user, savedRepo),
                  _buildProfileTab(context, user),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  BoxDecoration _pantryCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: _PantryColors.outlineVariant.withValues(alpha: 0.3),
      ),
      boxShadow: [
        BoxShadow(
          color: _PantryColors.primary.withValues(alpha: 0.07),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, User? user) {
    final canMenu = widget.userProvider == null && user != null;
    return Material(
      color: _PantryColors.topBar,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _PantryColors.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
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
                  color: _PantryColors.onSurface.withValues(
                    alpha: canMenu ? 1 : 0.35,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Recipe Creator AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: _PantryColors.primary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildProfileAvatar(user),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(User? user) {
    String initialChar(String s) {
      final t = s.trim();
      if (t.isEmpty) return '?';
      return t[0].toUpperCase();
    }

    final initial = (user?.displayName?.trim().isNotEmpty == true)
        ? initialChar(user!.displayName!)
        : (user?.email?.trim().isNotEmpty == true
              ? initialChar(user!.email!)
              : '?');
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        color: const Color(0xFF4778A7),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: NavigationBar(
            height: 64,
            backgroundColor: Colors.transparent,
            indicatorColor: _PantryColors.primaryFixed.withValues(alpha: 0.55),
            selectedIndex: _navIndex,
            onDestinationSelected: (i) => setState(() => _navIndex = i),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.kitchen_outlined),
                selectedIcon: Icon(Icons.kitchen),
                label: 'Inventory',
              ),
              NavigationDestination(
                icon: Icon(Icons.restaurant_outlined),
                selectedIcon: Icon(Icons.restaurant),
                label: 'Recipes',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmark_outline),
                selectedIcon: Icon(Icons.bookmark),
                label: 'Saved',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryTab(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: wide
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Text(
                      "What's in your Kitchen?",
                      textAlign: wide ? TextAlign.start : TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        color: _PantryColors.onSurface,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add the ingredients you have on hand to discover perfect recipes.',
                      textAlign: wide ? TextAlign.start : TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        color: _PantryColors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildAddIngredientsCard(context),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 7,
                            child: _buildInventoryCard(context),
                          ),
                        ],
                      )
                    else ...[
                      _buildAddIngredientsCard(context),
                      const SizedBox(height: 20),
                      _buildInventoryCard(context),
                    ],
                    const SizedBox(height: 28),
                    _buildSeasonalBanner(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddIngredientsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _pantryCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle, color: _PantryColors.primary, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add Ingredients',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _PantryColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _addIngredientController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addIngredientFromField(),
                  decoration: InputDecoration(
                    hintText: 'e.g. Cherry Tomatoes',
                    filled: true,
                    fillColor: _PantryColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    hintStyle: TextStyle(
                      color: _PantryColors.onSurfaceVariant.withValues(
                        alpha: 0.65,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: _PantryColors.primary,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _addIngredientFromField,
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'QUICK ADD SUGGESTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: _PantryColors.onSurfaceVariant.withValues(alpha: 0.85),
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
                backgroundColor: _PantryColors.secondaryContainer,
                side: BorderSide.none,
                labelStyle: const TextStyle(
                  color: _PantryColors.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _pantryCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.kitchen, color: _PantryColors.primary, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Your Inventory',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _PantryColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _PantryColors.primaryFixed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_pantryItems.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _PantryColors.onPrimaryFixedVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _pantryItems.isEmpty ? null : _clearPantry,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                      child: Text(
                        'Add ingredients to build your kitchen.',
                        style: TextStyle(
                          color: _PantryColors.onSurfaceVariant.withValues(
                            alpha: 0.85,
                          ),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _pantryItems.length,
                    separatorBuilder: (_, unusedIndex) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final item = _pantryItems[i];
                      return Material(
                        color: _PantryColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _emojiForIngredient(item),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _PantryColors.onSurface,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remove',
                                icon: Icon(
                                  Icons.close,
                                  color: _PantryColors.onSurfaceVariant
                                      .withValues(alpha: 0.75),
                                ),
                                onPressed: () => _removeIngredientAt(i),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _generate,
              style: FilledButton.styleFrom(
                backgroundColor: _PantryColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    _PantryColors.primary.withValues(alpha: 0.45),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                shadowColor: _PantryColors.primary.withValues(alpha: 0.35),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_loading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(Icons.restaurant),
                  const SizedBox(width: 10),
                  Text(
                    _loading ? 'Finding…' : 'Find Recipes',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
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

  Widget _buildSeasonalBanner(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 160),
        color: _PantryColors.tertiaryContainer,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -24,
              bottom: -24,
              child: Icon(
                Icons.spa_outlined,
                size: 180,
                color: _PantryColors.onTertiaryContainer.withValues(
                  alpha: 0.2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEASONAL PICK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: _PantryColors.onTertiaryContainer.withValues(
                          alpha: 0.85,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cooking with Asparagus',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _PantryColors.onTertiaryContainer,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "It's asparagus season! Add it to your kitchen to unlock fresh spring recipe ideas.",
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: _PantryColors.onTertiaryContainer.withValues(
                          alpha: 0.92,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        foregroundColor: _PantryColors.onTertiaryContainer,
                      ),
                      onPressed: () => _addIngredient('Asparagus'),
                      child: const Text('Add to Kitchen'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipesTab(
    BuildContext context,
    User? user,
    RecipeHistoryRepository? repo,
    SavedRecipesRepository? savedRepo,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (user != null && repo != null) ...[
                _sectionTitle(context, 'Recent'),
                const SizedBox(height: 8),
                StreamBuilder<List<GenerationRecord>>(
                  stream: repo.watchRecent(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'Recent: ${snapshot.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return Text(
                        'Saved generations will appear here.',
                        style: TextStyle(
                          color: _PantryColors.onSurfaceVariant.withValues(
                            alpha: 0.85,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: items.map((g) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showRecentGeneration(g),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            g.ingredientsText.isEmpty
                                                ? '(no ingredients text)'
                                                : g.ingredientsText.length > 56
                                                    ? '${g.ingredientsText.substring(0, 56)}…'
                                                    : g.ingredientsText,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${g.recipes.length} recipe(s)'
                                            '${g.createdAt != null ? ' · ${_formatDate(g.createdAt!)}' : ''}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _PantryColors
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: _PantryColors.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
              _sectionTitle(context, 'Suggestions'),
              const SizedBox(height: 8),
              if (_recipes.isEmpty)
                Text(
                  'Use Find Recipes on the Inventory tab to get ideas from your ingredients.',
                  style: TextStyle(
                    color: _PantryColors.onSurfaceVariant.withValues(
                      alpha: 0.85,
                    ),
                  ),
                )
              else
                ..._recipes.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showRecipeDetail(
                          r,
                          fromIngredients: _ingredientsPrompt,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      r.ingredients.take(3).join(', ') +
                                          (r.ingredients.length > 3 ? '…' : ''),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _PantryColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (user != null && savedRepo != null)
                                IconButton(
                                  tooltip: 'Save recipe',
                                  icon: const Icon(Icons.bookmark_add_outlined),
                                  color: _PantryColors.primary,
                                  onPressed: () async {
                                    try {
                                      await savedRepo.saveRecipe(
                                        userId: user.uid,
                                        recipe: r,
                                        fromIngredients: _ingredientsPrompt,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Recipe saved.'),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('Could not save: $e'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: _PantryColors.onSurface,
      ),
    );
  }

  Widget _buildSavedTab(
    BuildContext context,
    User? user,
    SavedRecipesRepository? savedRepo,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: user == null || savedRepo == null
              ? Text(
                  'Sign in to save and view recipes here.',
                  style: TextStyle(
                    color: _PantryColors.onSurfaceVariant.withValues(
                      alpha: 0.85,
                    ),
                  ),
                )
              : StreamBuilder<List<SavedRecipeEntry>>(
                  stream: savedRepo.watchSaved(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'Saved: ${snapshot.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return Text(
                        'Save recipes from suggestions or history to find them here.',
                        style: TextStyle(
                          color: _PantryColors.onSurfaceVariant.withValues(
                            alpha: 0.85,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: items.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showRecipeDetail(
                                entry.recipe,
                                savedEntry: entry,
                                fromIngredients: entry.fromIngredients,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      entry.liked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: entry.liked
                                          ? _PantryColors.primary
                                          : _PantryColors.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.recipe.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            entry.liked ? 'Liked' : 'Saved',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _PantryColors
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: entry.liked ? 'Unlike' : 'Like',
                                      icon: Icon(
                                        entry.liked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                      ),
                                      onPressed: () async {
                                        try {
                                          await savedRepo.setLiked(
                                            user.uid,
                                            entry.id,
                                            !entry.liked,
                                          );
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Could not update: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'Remove from saved',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () =>
                                          _confirmDeleteSaved(entry),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

  Widget _buildProfileTab(BuildContext context, User? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: user == null
              ? Text(
                  'Profile is available when signed in.',
                  style: TextStyle(
                    color: _PantryColors.onSurfaceVariant.withValues(
                      alpha: 0.85,
                    ),
                  ),
                )
              : widget.userProfileRepository == null
                  ? Text(
                      'Profile sync is unavailable.',
                      style: TextStyle(
                        color: _PantryColors.onSurfaceVariant.withValues(
                          alpha: 0.85,
                        ),
                      ),
                    )
                  : StreamBuilder<UserProfile?>(
                      stream: widget.userProfileRepository!.watchProfile(
                        user.uid,
                      ),
                      builder: (context, snapshot) {
                        final profile = snapshot.data;
                        final labelName =
                            (profile?.name.trim().isNotEmpty == true)
                                ? profile!.name.trim()
                                : (user.displayName?.trim().isNotEmpty == true
                                      ? user.displayName!.trim()
                                      : 'Chef');
                        final labelEmail =
                            (profile?.email.trim().isNotEmpty == true)
                                ? profile!.email.trim()
                                : (user.email ?? '');
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: _pantryCardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildProfileAvatar(user),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          labelName,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if (labelEmail.isNotEmpty)
                                          Text(
                                            labelEmail,
                                            style: TextStyle(
                                              color: _PantryColors
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.userProvider == null) ...[
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        FirebaseAuth.instance.signOut(),
                                    icon: const Icon(Icons.logout),
                                    label: const Text('Sign out'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _showRecentGeneration(GenerationRecord g) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.paddingOf(ctx).bottom + 16,
          ),
          child: ListView(
            children: [
              Text(
                g.ingredientsText.isEmpty ? 'Saved run' : g.ingredientsText,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Divider(height: 24),
              ...g.recipes.map(
                (r) => ListTile(
                  title: Text(r.title),
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
                                const SnackBar(
                                  content: Text('Recipe saved.'),
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Could not save: $e'),
                                ),
                              );
                            }
                          },
                        ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showRecipeDetail(
                      r,
                      fromIngredients: g.ingredientsText,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecipeDetailSheetBody extends StatefulWidget {
  const _RecipeDetailSheetBody({
    required this.recipe,
    required this.scrollController,
    this.initialSavedEntry,
    this.fromIngredients,
    this.userId,
    this.savedRecipesRepository,
  });

  final Recipe recipe;
  final ScrollController scrollController;
  final SavedRecipeEntry? initialSavedEntry;
  final String? fromIngredients;
  final String? userId;
  final SavedRecipesRepository? savedRecipesRepository;

  @override
  State<_RecipeDetailSheetBody> createState() => _RecipeDetailSheetBodyState();
}

class _RecipeDetailSheetBodyState extends State<_RecipeDetailSheetBody> {
  SavedRecipeEntry? _entry;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.initialSavedEntry;
  }

  Future<void> _save() async {
    final uid = widget.userId;
    final repo = widget.savedRecipesRepository;
    if (uid == null || repo == null || _saving) return;
    setState(() => _saving = true);
    try {
      final id = await repo.saveRecipe(
        userId: uid,
        recipe: widget.recipe,
        fromIngredients: widget.fromIngredients,
      );
      if (!mounted) return;
      setState(() {
        _entry = SavedRecipeEntry(
          id: id,
          recipe: widget.recipe,
          liked: false,
          savedAt: DateTime.now(),
          fromIngredients: widget.fromIngredients?.isNotEmpty == true
              ? widget.fromIngredients
              : null,
        );
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe saved.')),
      );
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
    final entry = _entry;
    if (uid == null || repo == null || entry == null) return;
    final next = !entry.liked;
    try {
      await repo.setLiked(uid, entry.id, next);
      if (!mounted) return;
      setState(() => _entry = entry.copyWith(liked: next));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update: $e')),
        );
      }
    }
  }

  Future<void> _delete() async {
    final uid = widget.userId;
    final repo = widget.savedRecipesRepository;
    final entry = _entry;
    if (uid == null || repo == null || entry == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove saved recipe?'),
        content: Text('Remove “${widget.recipe.title}” from your saved list?'),
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
      await repo.deleteSavedRecipe(uid, entry.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe removed from saved.')),
      );
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
    final recipe = widget.recipe;
    final canLibrary =
        widget.userId != null && widget.savedRecipesRepository != null;

    return ListView(
      controller: widget.scrollController,
      children: [
        Text(
          recipe.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (canLibrary) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_entry == null)
                FilledButton.tonalIcon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bookmark_add_outlined),
                  label: Text(_saving ? 'Saving…' : 'Save recipe'),
                )
              else ...[
                IconButton.filledTonal(
                  tooltip: _entry!.liked ? 'Unlike' : 'Like',
                  onPressed: _toggleLike,
                  icon: Icon(
                    _entry!.liked ? Icons.favorite : Icons.favorite_border,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove from saved',
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Ingredients',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...recipe.ingredients.map(
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $i'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Steps',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < recipe.steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('${i + 1}. ${recipe.steps[i]}'),
          ),
      ],
    );
  }
}

