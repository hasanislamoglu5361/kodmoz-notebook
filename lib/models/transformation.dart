class Transformation {
  Transformation({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.prompt,
  });

  final String id;
  final String name;
  final String title;
  final String description;
  final String prompt;

  factory Transformation.fromJson(Map<String, dynamic> j) => Transformation(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        prompt: (j['prompt'] ?? '').toString(),
      );

  String get cleanId {
    final i = id.indexOf(':');
    return i >= 0 ? id.substring(i + 1) : id;
  }
}
