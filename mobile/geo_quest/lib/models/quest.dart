class Quest {
  final int id;
  final String title;
  final String description;
  final String type;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final int points;
  final String? question;
  final bool isActive;
  final double? distanceMeters;
  final String source;
  final int? generatedFor;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.points,
    this.question,
    required this.isActive,
    this.distanceMeters,
    this.source = 'manual',
    this.generatedFor,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      type: json['type'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: json['radius_meters'] ?? 100,
      points: json['points'] ?? 10,
      question: json['question'],
      isActive: json['is_active'] ?? true,
      distanceMeters: json['distance_meters'] != null
          ? (json['distance_meters'] as num).toDouble()
          : null,
      source: json['source'] ?? 'manual',
      generatedFor: json['generated_for'],
    );
  }

  bool get isAI => source == 'ai';

  String get typeLabel {
    switch (type) {
      case 'photo':
        return 'Fotoğraf';
      case 'question':
        return 'Soru';
      case 'qr_code':
        return 'QR Kod';
      default:
        return type;
    }
  }
}
