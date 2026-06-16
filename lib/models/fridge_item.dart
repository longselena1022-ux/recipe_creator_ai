import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum FridgeCategory {
  produce(label: 'Produce', icon: Icons.eco),
  dairy(label: 'Dairy & Eggs', icon: Icons.egg_outlined),
  protein(label: 'Protein', icon: Icons.set_meal_outlined),
  pantry(label: 'Pantry', icon: Icons.inventory_2_outlined);

  const FridgeCategory({required this.label, required this.icon});

  final String label;
  final IconData icon;

  static FridgeCategory fromName(String? name) {
    return FridgeCategory.values.firstWhere(
      (c) => c.name == name,
      orElse: () => FridgeCategory.pantry,
    );
  }
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

  factory FridgeItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FridgeItem(
      name: data['name'] as String? ?? '',
      category: FridgeCategory.fromName(data['category'] as String?),
      emoji: data['emoji'] as String? ?? '🧺',
      subtitle: data['subtitle'] as String?,
      expiresInDays: data['expiresInDays'] as int?,
      lowStock: data['lowStock'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category.name,
      'emoji': emoji,
      if (subtitle != null) 'subtitle': subtitle,
      if (expiresInDays != null) 'expiresInDays': expiresInDays,
      'lowStock': lowStock,
    };
  }
}
