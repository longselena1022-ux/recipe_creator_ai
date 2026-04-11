import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_creator_ai/models/recipe.dart';
import 'package:recipe_creator_ai/models/saved_recipe_entry.dart';
import 'package:recipe_creator_ai/services/recipe_generation_service.dart';
import 'package:recipe_creator_ai/services/recipe_history_repository.dart';
import 'package:recipe_creator_ai/services/saved_recipes_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.generationService,
    this.historyRepository,
    this.savedRecipesRepository,
    /// When set (e.g. in tests), used instead of [FirebaseAuth.instance.currentUser].
    this.userProvider,
  });

  final RecipeGenerationService generationService;
  final RecipeHistoryRepository? historyRepository;
  final SavedRecipesRepository? savedRecipesRepository;
  final User? Function()? userProvider;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _ingredientsController = TextEditingController();
  List<Recipe> _recipes = [];
  bool _loading = false;
  String? _error;

  User? get _currentUser {
    final custom = widget.userProvider;
    if (custom != null) {
      return custom();
    }
    return FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _ingredientsController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list =
          await widget.generationService.generate(_ingredientsController.text);
      if (!mounted) return;
      setState(() {
        _recipes = list;
        _loading = false;
      });
      final user = _currentUser;
      final repo = widget.historyRepository;
      if (user != null && repo != null && list.isNotEmpty) {
        try {
          await repo.saveGeneration(
            userId: user.uid,
            ingredientsText: _ingredientsController.text.trim(),
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
      appBar: AppBar(
        title: const Text('Recipe Creator AI'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.userProvider == null && user != null)
            IconButton(
              tooltip: 'Sign out',
              onPressed: () => FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'What do you have?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ingredientsController,
              decoration: const InputDecoration(
                hintText: 'e.g. eggs, spinach, feta, olive oil',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loading ? null : _generate,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restaurant_menu),
              label: Text(_loading ? 'Generating…' : 'Generate recipes'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (user != null && repo != null) ...[
              const SizedBox(height: 28),
              Text(
                'Recent',
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    );
                  }
                  return Column(
                    children: items.map((g) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            g.ingredientsText.isEmpty
                                ? '(no ingredients text)'
                                : g.ingredientsText.length > 48
                                    ? '${g.ingredientsText.substring(0, 48)}…'
                                    : g.ingredientsText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${g.recipes.length} recipe(s)'
                            '${g.createdAt != null ? ' · ${_formatDate(g.createdAt!)}' : ''}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showRecentGeneration(g),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
            if (user != null && savedRepo != null) ...[
              const SizedBox(height: 28),
              Text(
                'Saved',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<SavedRecipeEntry>>(
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    );
                  }
                  return Column(
                    children: items.map((entry) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(entry.recipe.title),
                          subtitle: Text(
                            entry.liked ? 'Liked' : 'Saved',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          leading: Icon(
                            entry.liked ? Icons.favorite : Icons.favorite_border,
                            color: entry.liked
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                          content: Text('Could not update: $e'),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              IconButton(
                                tooltip: 'Remove from saved',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDeleteSaved(entry),
                              ),
                            ],
                          ),
                          onTap: () => _showRecipeDetail(
                            entry.recipe,
                            savedEntry: entry,
                            fromIngredients: entry.fromIngredients,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
            if (_recipes.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                'Suggestions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._recipes.map(
                (r) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(r.title),
                    subtitle: Text(
                      r.ingredients.take(3).join(', ') +
                          (r.ingredients.length > 3 ? '…' : ''),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (user != null && savedRepo != null)
                          IconButton(
                            tooltip: 'Save recipe',
                            icon: const Icon(Icons.bookmark_add_outlined),
                            onPressed: () async {
                              try {
                                await savedRepo.saveRecipe(
                                  userId: user.uid,
                                  recipe: r,
                                  fromIngredients:
                                      _ingredientsController.text.trim(),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Recipe saved.'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Could not save: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        const Icon(Icons.open_in_new),
                      ],
                    ),
                    onTap: () => _showRecipeDetail(
                      r,
                      fromIngredients: _ingredientsController.text.trim(),
                    ),
                  ),
                ),
              ),
            ],
          ],
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

