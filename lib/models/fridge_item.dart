import 'package:flutter/material.dart';

enum FridgeCategory {
  produce(label: 'Produce', icon: Icons.eco),
  dairy(label: 'Dairy & Eggs', icon: Icons.egg_outlined),
  protein(label: 'Protein', icon: Icons.set_meal_outlined),
  pantry(label: 'Pantry', icon: Icons.inventory_2_outlined);

  const FridgeCategory({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class FridgeItem {
  const FridgeItem({
    required this.name,
    required this.category,
    required this.emoji,
    this.subtitle,
    this.expiresInDays,
    this.lowStock = false,
  });

  final String name;
  final FridgeCategory category;
  final String emoji;
  final String? subtitle;
  final int? expiresInDays;
  final bool lowStock;

  bool get expiringSoon => expiresInDays != null && expiresInDays! <= 1;
}
