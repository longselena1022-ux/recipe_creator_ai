import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_creator_ai/models/fridge_item.dart';
import 'package:recipe_creator_ai/services/inventory_repository.dart';

class FridgeScreen extends StatefulWidget {
  const FridgeScreen({
    super.key,
    this.onMoveToPrep,
    this.pantryItems = const [],
    this.inventoryRepository,
    this.userId,
  });

  final void Function(String ingredient)? onMoveToPrep;
  final List<String> pantryItems;
  final InventoryRepository? inventoryRepository;
  final String? userId;

  @override
  State<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen> {
  final _searchController = TextEditingController();

  // Hardcoded demo list used only when no repository/userId is provided.
  static const List<FridgeItem> _demoItems = [
    FridgeItem(
      name: 'Bell Peppers',
      category: FridgeCategory.produce,
      emoji: '🫑',
      subtitle: '3 units',
      expiresInDays: 4,
    ),
    FridgeItem(
      name: 'Organic Kale',
      category: FridgeCategory.produce,
      emoji: '🥬',
      subtitle: '1 bunch',
      expiresInDays: 1,
    ),
    FridgeItem(
      name: 'Cherry Tomatoes',
      category: FridgeCategory.produce,
      emoji: '🍅',
      subtitle: '1 pint',
      expiresInDays: 5,
    ),
    FridgeItem(
      name: 'Whole Milk',
      category: FridgeCategory.dairy,
      emoji: '🥛',
      subtitle: 'Remaining: 200ml',
      lowStock: true,
    ),
    FridgeItem(
      name: 'Organic Eggs',
      category: FridgeCategory.dairy,
      emoji: '🥚',
      subtitle: '10 units',
    ),
    FridgeItem(
      name: 'Atlantic Salmon',
      category: FridgeCategory.protein,
      emoji: '🐟',
      subtitle: '2 fillets · Freshly stocked',
    ),
    FridgeItem(
      name: 'Chicken Breast',
      category: FridgeCategory.protein,
      emoji: '🍗',
      subtitle: '4 pieces',
      expiresInDays: 2,
    ),
    FridgeItem(
      name: 'Olive Oil',
      category: FridgeCategory.pantry,
      emoji: '🫒',
      subtitle: '500ml bottle',
    ),
  ];

  // Local list used only in demo mode (no repository).
  late List<FridgeItem> _localItems;

  bool get _hasRepo =>
      widget.inventoryRepository != null && widget.userId != null;

  @override
  void initState() {
    super.initState();
    _localItems = List<FridgeItem>.from(_demoItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _quickAdd(List<FridgeItem> currentItems) {
    final raw = _searchController.text.trim();
    if (raw.isEmpty) return;
    final newItem = FridgeItem(
      name: raw,
      category: FridgeCategory.pantry,
      emoji: '🧺',
      subtitle: 'Just added',
    );
    if (_hasRepo) {
      widget.inventoryRepository!.addItem(widget.userId!, newItem);
    } else {
      setState(() {
        _localItems.add(newItem);
      });
    }
    _searchController.clear();
  }

  void _removeItem(FridgeItem item) {
    if (_hasRepo) {
      widget.inventoryRepository!.removeItem(widget.userId!, item.name);
    } else {
      setState(() {
        _localItems.removeWhere((e) => e.name == item.name);
      });
    }
  }

  void _moveToPrep(FridgeItem item) {
    widget.onMoveToPrep?.call(item.name);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.name} added to your prep list.')),
    );
  }

  bool _isInPantry(FridgeItem item) {
    final lower = item.name.toLowerCase();
    return widget.pantryItems.any((e) => e.toLowerCase() == lower);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasRepo) {
      return StreamBuilder<List<FridgeItem>>(
        stream: widget.inventoryRepository!.watchItems(widget.userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load inventory.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
          final items = snapshot.data ?? [];
          return _buildContent(context, items);
        },
      );
    }
    return _buildContent(context, _localItems);
  }

  Widget _buildContent(BuildContext context, List<FridgeItem> items) {
    final cs = Theme.of(context).colorScheme;
    final byCategory = <FridgeCategory, List<FridgeItem>>{};
    for (final item in items) {
      byCategory.putIfAbsent(item.category, () => []).add(item);
    }

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
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBentoHero(cs, items),
              const SizedBox(height: 32),
              for (final category in FridgeCategory.values)
                if (byCategory[category]?.isNotEmpty ?? false) ...[
                  _buildCategorySection(cs, category, byCategory[category]!),
                  const SizedBox(height: 32),
                ],
              if (items.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Text(
                      'Your inventory is empty.\nAdd your first item above!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: cs.onSurfaceVariant,
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

  Widget _buildBentoHero(ColorScheme cs, List<FridgeItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        final title = _buildTitleCard(cs, items);
        final add = _buildAddCard(cs, items);
        if (wide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 7, child: title),
                const SizedBox(width: 20),
                Expanded(flex: 5, child: add),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [title, const SizedBox(height: 16), add],
        );
      },
    );
  }

  Widget _buildTitleCard(ColorScheme cs, List<FridgeItem> items) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            Color.lerp(cs.primary, cs.primaryContainer, 0.6)!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Fridge',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your fresh essentials',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${items.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'ITEMS TOTAL',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddCard(ColorScheme cs, List<FridgeItem> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add New Item',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _quickAdd(items),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: cs.outline, size: 20),
              hintText: 'Scan or type item…',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: cs.outline,
              ),
              filled: true,
              fillColor: cs.surfaceContainerLow,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
            style: GoogleFonts.inter(fontSize: 14, color: cs.onSurface),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: () => _quickAdd(items),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Quick Add'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.secondaryContainer,
                foregroundColor: cs.onSecondaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    ColorScheme cs,
    FridgeCategory category,
    List<FridgeItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(category.icon, color: cs.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              category.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${items.length} ITEMS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final item in items) ...[
          _buildItemCard(cs, item),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildItemCard(ColorScheme cs, FridgeItem item) {
    final inPantry = _isInPantry(item);
    final exp = item.expiresInDays;
    final subtitleColor = item.expiringSoon ? cs.error : cs.onSurfaceVariant;
    final subtitle = item.expiringSoon
        ? 'Expires tomorrow'
        : exp != null
            ? '${item.subtitle ?? ''}${item.subtitle != null ? ' · ' : ''}Exp. in $exp days'
            : item.subtitle ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(item.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.lowStock) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'LOW STOCK',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: cs.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: subtitleColor,
                    fontWeight:
                        item.expiringSoon ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: inPantry ? null : () => _moveToPrep(item),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.secondaryContainer,
                  foregroundColor: cs.onSecondaryContainer,
                  disabledBackgroundColor: cs.surfaceContainerHigh,
                  disabledForegroundColor: cs.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                child: Text(inPantry ? 'IN PREP' : 'MOVE TO PREP'),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _removeItem(item),
                icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
                tooltip: 'Remove item',
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
