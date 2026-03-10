class Achievement {
  final int id;
  final String key;
  final String title;
  final String description;
  final String icon;
  final String color;
  final int requiredCount;
  final int pointsReward;
  final bool unlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.requiredCount,
    required this.pointsReward,
    this.unlocked = false,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      key: json['key'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'] ?? 'star',
      color: json['color'] ?? '#FFD700',
      requiredCount: json['required_count'] ?? 1,
      pointsReward: json['points_reward'] ?? 0,
      unlocked: json['unlocked'] ?? false,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'])
          : null,
    );
  }
}
