import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipe_creator_ai/services/user_profile_repository.dart';

/// A single selectable option backed by a stored key.
class _Option {
  const _Option(this.key, this.label, this.icon, {this.subtitle});

  final String key;
  final String label;
  final IconData icon;
  final String? subtitle;
}

const List<_Option> _goals = [
  _Option('weight_loss', 'Weight Loss', Icons.trending_down),
  _Option('build_muscle', 'Build Muscle', Icons.fitness_center),
  _Option('healthy_lifestyle', 'Healthy Lifestyle', Icons.eco),
];

const List<_Option> _diets = [
  _Option('vegetarian', 'Vegetarian', Icons.restaurant),
  _Option('vegan', 'Vegan', Icons.spa),
  _Option('gluten_free', 'Gluten-Free', Icons.grain),
  _Option('keto', 'Keto', Icons.bolt),
  _Option('paleo', 'Paleo', Icons.forest),
  _Option('dairy_free', 'Dairy-Free', Icons.water_drop),
];

const List<_Option> _skills = [
  _Option(
    'beginner',
    'Beginner',
    Icons.egg_alt,
    subtitle: 'Basic techniques, quick meals',
  ),
  _Option(
    'intermediate',
    'Intermediate',
    Icons.soup_kitchen,
    subtitle: 'Comfortable with most recipes',
  ),
  _Option(
    'pro',
    'Pro',
    Icons.restaurant_menu,
    subtitle: 'Complex techniques, gourmet experiments',
  ),
];

const List<_Option> _equipment = [
  _Option('air_fryer', 'Air Fryer', Icons.air),
  _Option('slow_cooker', 'Slow Cooker', Icons.soup_kitchen),
  _Option('blender', 'Blender', Icons.blender),
  _Option('cast_iron_skillet', 'Cast Iron Skillet', Icons.outdoor_grill),
  _Option('food_processor', 'Food Processor', Icons.kitchen),
  _Option('oven', 'Oven', Icons.local_fire_department),
  _Option('microwave', 'Microwave', Icons.microwave),
];

/// Sequential 3-step onboarding shown to a signed-in user the first time they
/// reach the app. Choices are persisted to the user's profile; completing or
/// skipping sets `onboardingComplete`, which routes them onward.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.userId,
    required this.userProfileRepository,
  });

  final String userId;
  final UserProfileRepository userProfileRepository;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const int _stepCount = 3;

  int _step = 0;
  String? _goal;
  String? _skill;
  final Set<String> _selectedDiets = {};
  final Set<String> _selectedEquipment = {};
  bool _saving = false;

  void _next() {
    if (_step < _stepCount - 1) {
      setState(() => _step++);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  Future<void> _persist({required bool markComplete}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.userProfileRepository.saveOnboarding(
        userId: widget.userId,
        goal: _goal,
        cookingSkill: _skill,
        dietaryPreferences: _selectedDiets.toList(),
        equipment: _selectedEquipment.toList(),
        markComplete: markComplete,
      );
      // On completion AuthGate observes `onboardingComplete` and swaps to the
      // home screen, so no manual navigation is needed here.
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save your preferences: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLast = _step == _stepCount - 1;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(cs),
            _buildProgress(cs),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: SingleChildScrollView(
                  key: ValueKey<int>(_step),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: _buildStepBody(cs),
                    ),
                  ),
                ),
              ),
            ),
            _buildActionBar(cs, isLast),
          ],
        ),
      ),
    );
  }

  // ─── Chrome ─────────────────────────────────────────────────────────────────

  Widget _buildTopBar(ColorScheme cs) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: _step > 0
                  ? IconButton(
                      tooltip: 'Back',
                      icon: Icon(Icons.arrow_back, color: cs.primary),
                      onPressed: _saving ? null : _back,
                    )
                  : null,
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, color: cs.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'PantryChef',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(ColorScheme cs) {
    final percent = (_step + 1) / _stepCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP ${_step + 1} OF $_stepCount',
                style: GoogleFonts.workSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: cs.primary,
                ),
              ),
              Text(
                _step == _stepCount - 1
                    ? 'FINAL STRETCH'
                    : '${(percent * 100).round()}% COMPLETE',
                style: GoogleFonts.workSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(ColorScheme cs, bool isLast) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving
                  ? null
                  : isLast
                      ? () => _persist(markComplete: true)
                      : _next,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                disabledBackgroundColor: cs.primary.withValues(alpha: 0.45),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLast ? 'Finish Setup' : 'Continue',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isLast ? Icons.check_rounded : Icons.arrow_forward,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _saving
                ? null
                : _step == 0
                    ? () => _persist(markComplete: true)
                    : _back,
            style: TextButton.styleFrom(foregroundColor: cs.onSurfaceVariant),
            child: Text(
              _step == 0 ? 'Skip for now' : 'Back',
              style: GoogleFonts.workSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step bodies ──────────────────────────────────────────────────────────

  Widget _buildStepBody(ColorScheme cs) {
    switch (_step) {
      case 0:
        return _buildGoalsStep(cs);
      case 1:
        return _buildSkillStep(cs);
      default:
        return _buildEquipmentStep(cs);
    }
  }

  Widget _stepHeader(ColorScheme cs, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.15,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.workSans(
            fontSize: 15,
            height: 1.5,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildGoalsStep(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          cs,
          'Personalize your journey',
          'Help us tailor your experience by sharing your goals and preferences.',
        ),
        Text(
          'What is your primary goal?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        for (final option in _goals) ...[
          _GoalCard(
            option: option,
            selected: _goal == option.key,
            onTap: () => setState(() => _goal = option.key),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        Text(
          'Dietary preferences',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in _diets)
              _SelectableChip(
                option: option,
                selected: _selectedDiets.contains(option.key),
                onTap: () => setState(() {
                  if (!_selectedDiets.add(option.key)) {
                    _selectedDiets.remove(option.key);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _InfoBanner(
          cs: cs,
          icon: Icons.auto_awesome,
          title: "We'll find the perfect recipes for you.",
          body: 'Your goals shape every suggestion we make.',
        ),
      ],
    );
  }

  Widget _buildSkillStep(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          cs,
          "What's your cooking expertise?",
          'This helps us suggest recipes that match your comfort level in the kitchen.',
        ),
        for (final option in _skills) ...[
          _SkillCard(
            option: option,
            selected: _skill == option.key,
            onTap: () => setState(() => _skill = option.key),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildEquipmentStep(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          cs,
          "What's in your kitchen?",
          'Select the tools you have so we can suggest recipes you can actually '
              'make without a trip to the store.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 480 ? 3 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1,
              children: [
                for (final option in _equipment)
                  _EquipmentCard(
                    option: option,
                    selected: _selectedEquipment.contains(option.key),
                    onTap: () => setState(() {
                      if (!_selectedEquipment.add(option.key)) {
                        _selectedEquipment.remove(option.key);
                      }
                    }),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _InfoBanner(
          cs: cs,
          icon: Icons.workspace_premium,
          title: 'Equipped for success',
          body: "Better tools lead to better results. We'll prioritize recipes "
              'that use what you already have.',
        ),
      ],
    );
  }
}

// ─── Reusable option widgets ──────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _Option option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primaryContainer.withValues(alpha: 0.3) : cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: selected ? cs.primary : cs.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  option.icon,
                  color: selected ? cs.onPrimary : cs.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: cs.primary, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _Option option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primaryContainer.withValues(alpha: 0.3) : cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: selected ? cs.primary : cs.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  option.icon,
                  color: selected ? cs.onPrimary : cs.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    if (option.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle!,
                        style: GoogleFonts.workSans(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? cs.primary : cs.outlineVariant,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _Option option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primaryContainer.withValues(alpha: 0.3) : cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, size: 14, color: cs.onPrimary),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primary.withValues(alpha: 0.15)
                            : cs.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(option.icon, color: cs.primary, size: 28),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      option.label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.workSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _Option option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primary : cs.surfaceContainerLowest,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? cs.primary : cs.outlineVariant,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                option.icon,
                size: 18,
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                option.label,
                style: GoogleFonts.workSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.cs,
    required this.icon,
    required this.title,
    required this.body,
  });

  final ColorScheme cs;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.workSans(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
