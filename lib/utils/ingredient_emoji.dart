String emojiForIngredient(String name) {
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
