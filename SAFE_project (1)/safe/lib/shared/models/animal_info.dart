class AnimalInfo {
  final String commonName, scientificName, group, characteristics, habitat,
      behavior, diet, risks;
  final List<String> safety;
  const AnimalInfo({
    required this.commonName,
    required this.scientificName,
    required this.group,
    required this.characteristics,
    required this.habitat,
    required this.behavior,
    required this.diet,
    required this.risks,
    required this.safety,
  });

  static const unavailable = 'Unavailable';

  factory AnimalInfo.fromJson(Map<String, dynamic> j) {
    String s(String k) {
      final v = j[k];
      return (v is String && v.trim().isNotEmpty) ? v : unavailable;
    }

    return AnimalInfo(
      commonName: s('commonName'),
      scientificName: s('scientificName'),
      group: s('group'),
      characteristics: s('characteristics'),
      habitat: s('habitat'),
      behavior: s('behavior'),
      diet: s('diet'),
      risks: s('risks'),
      safety: ((j['safety'] as List?) ?? const []).cast<String>(),
    );
  }
}
