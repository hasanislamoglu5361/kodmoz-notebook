class Credential {
  Credential({
    required this.id,
    required this.name,
    required this.provider,
    required this.modalities,
    this.baseUrl,
    this.modelCount = 0,
    this.hasApiKey = false,
  });

  final String id;
  final String name;
  final String provider;
  final List<String> modalities;
  final String? baseUrl;
  final int modelCount;
  final bool hasApiKey;

  factory Credential.fromJson(Map<String, dynamic> j) => Credential(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        provider: (j['provider'] ?? '').toString(),
        modalities: (j['modalities'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        baseUrl: j['base_url']?.toString(),
        modelCount: (j['model_count'] is num)
            ? (j['model_count'] as num).toInt()
            : 0,
        hasApiKey: j['has_api_key'] == true,
      );
}
