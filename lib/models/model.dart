class Model {
  Model({
    required this.id,
    required this.name,
    required this.provider,
    required this.type,
    this.credential,
  });

  final String id;
  final String name;
  final String provider;
  final String type; // 'language' | 'embedding' | 'text_to_speech'
  final String? credential;

  factory Model.fromJson(Map<String, dynamic> j) => Model(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        provider: (j['provider'] ?? '').toString(),
        type: (j['type'] ?? 'language').toString(),
        credential: j['credential']?.toString(),
      );

  bool get isLanguage => type == 'language';
  bool get isEmbedding => type == 'embedding';
  bool get isTts => type == 'text_to_speech';
}
