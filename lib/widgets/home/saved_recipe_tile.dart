import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_creator_ai/models/saved_recipe_entry.dart';

class SavedRecipeTile extends StatelessWidget {
  const SavedRecipeTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onToggleLike,
    required this.onDelete,
  });

  final SavedRecipeEntry entry;
  final VoidCallback onTap;
  final VoidCallback onToggleLike;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: entry.liked
                      ? cs.secondaryContainer
                      : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  entry.liked ? Icons.favorite : Icons.bookmark,
                  color: entry.liked ? cs.secondary : cs.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.recipe.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      entry.liked ? 'Liked' : 'Saved',
                      style: GoogleFonts.workSans(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: entry.liked ? 'Unlike' : 'Like',
                icon: Icon(
                  entry.liked ? Icons.favorite : Icons.favorite_border,
                  color: entry.liked ? cs.secondary : cs.onSurfaceVariant,
                ),
                onPressed: onToggleLike,
              ),
              IconButton(
                tooltip: 'Remove from saved',
                icon: const Icon(Icons.delete_outline),
                color: cs.onSurfaceVariant,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
