import 'dart:ui';

import 'package:flutter/material.dart';

class BlurredBottomNav extends StatelessWidget {
  const BlurredBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: cs.surface.withValues(alpha: 0.72),
          child: SafeArea(
            top: false,
            child: NavigationBar(
              height: 64,
              backgroundColor: Colors.transparent,
              indicatorColor: cs.primaryFixed.withValues(alpha: 0.55),
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome),
                  label: 'Generate',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
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
      ),
    );
  }
}
