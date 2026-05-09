import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_creator_ai/services/recipe_history_repository.dart';
import 'package:recipe_creator_ai/utils/format_date.dart';

class RecentGenerationTile extends StatelessWidget {
  const RecentGenerationTile({
    super.key,
    required this.record,
    required this.onTap,
  });

  final GenerationRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final preview = record.ingredientsText.isEmpty
        ? '(no ingredients text)'
        : record.ingredientsText.length > 56
            ? '${record.ingredientsText.substring(0, 56)}…'
            : record.ingredientsText;
    final subtitle =
        '${record.recipes.length} recipe(s)'
        '${record.createdAt != null ? ' · ${formatDate(record.createdAt!)}' : ''}';

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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.workSans(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
