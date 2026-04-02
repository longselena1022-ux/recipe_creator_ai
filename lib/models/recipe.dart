class Recipe {
  const Recipe({
    required this.title,
    required this.ingredients,
    required this.steps,
  });

  final String title;
  final List<String> ingredients;
  final List<String> steps;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      title: json['title']?.toString().trim().isNotEmpty == true
          ? json['title'].toString().trim()
          : 'Untitled',
      ingredients: _stringList(json['ingredients']),
      steps: _stringList(json['steps']),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'ingredients': ingredients,
        'steps': steps,
      };

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
