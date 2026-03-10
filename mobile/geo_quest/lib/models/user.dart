class User {
  final int id;
  final String email;
  final String name;
  final String role;
  final int totalPoints;
  final int currentStreak;
  final int maxStreak;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.totalPoints,
    this.currentStreak = 0,
    this.maxStreak = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
      totalPoints: json['total_points'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      maxStreak: json['max_streak'] ?? 0,
    );
  }
}
