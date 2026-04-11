import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_creator_ai/models/recipe.dart';
import 'package:recipe_creator_ai/services/recipe_generation_service.dart';
import 'package:recipe_creator_ai/services/recipe_history_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.generationService,
    this.historyRepository,
    /// When set (e.g. in tests), used instead of [FirebaseAuth.instance.currentUser].
    this.userProvider,
  });

  final RecipeGenerationService generationService;
  final RecipeHistoryRepository? historyRepository;
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

  void _showRecipeDetail(Recipe recipe) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.paddingOf(ctx).bottom + 24,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return ListView(
                controller: scrollController,
                children: [
                  Text(
                    recipe.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
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
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    final repo = widget.historyRepository;

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
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _showRecipeDetail(r),
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
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showRecipeDetail(r);
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
