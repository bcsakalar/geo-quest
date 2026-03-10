class Submission {
  final int id;
  final int questId;
  final String status;
  final String? photoUrl;
  final String? answerText;
  final String? qrScannedData;
  final String questTitle;
  final String questType;
  final int questPoints;
  final DateTime submittedAt;

  Submission({
    required this.id,
    required this.questId,
    required this.status,
    this.photoUrl,
    this.answerText,
    this.qrScannedData,
    required this.questTitle,
    required this.questType,
    required this.questPoints,
    required this.submittedAt,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'],
      questId: json['quest_id'],
      status: json['status'],
      photoUrl: json['photo_url'],
      answerText: json['answer_text'],
      qrScannedData: json['qr_scanned_data'],
      questTitle: json['quest_title'] ?? '',
      questType: json['quest_type'] ?? '',
      questPoints: json['quest_points'] ?? 0,
      submittedAt: DateTime.parse(json['submitted_at']),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Bekliyor';
      case 'approved':
        return 'Onaylandı';
      case 'rejected':
        return 'Reddedildi';
      default:
        return status;
    }
  }
}
