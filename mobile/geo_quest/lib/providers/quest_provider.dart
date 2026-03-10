import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/quest.dart';
import '../models/submission.dart';
import '../models/user.dart';
import '../models/achievement.dart';
import '../services/api_service.dart';

class QuestProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Quest> _quests = [];
  List<Submission> _submissions = [];
  List<User> _leaderboard = [];
  List<Map<String, dynamic>> _recommendations = [];
  List<Achievement> _achievements = [];
  Map<String, dynamic>? _dailyChallenge;
  Map<String, dynamic>? _streakInfo;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  List<Quest> get quests => _quests;
  List<Submission> get submissions => _submissions;
  List<User> get leaderboard => _leaderboard;
  List<Map<String, dynamic>> get recommendations => _recommendations;
  List<Achievement> get achievements => _achievements;
  Map<String, dynamic>? get dailyChallenge => _dailyChallenge;
  Map<String, dynamic>? get streakInfo => _streakInfo;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  Future<void> loadQuests({double? lat, double? lng, int? radius}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, dynamic>{};
      if (lat != null && lng != null) {
        params['lat'] = lat;
        params['lng'] = lng;
        params['radius'] = radius ?? 5000;
      }
      final response = await _api.dio.get('/quests', queryParameters: params);
      _quests = (response.data['quests'] as List)
          .map((q) => Quest.fromJson(q))
          .toList();
    } catch (e) {
      _error = 'Görevler yüklenemedi';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> submitQuest({
    required int questId,
    File? photo,
    String? answerText,
    String? qrScannedData,
  }) async {
    try {
      FormData formData = FormData();

      if (photo != null) {
        formData.files.add(MapEntry(
          'photo',
          await MultipartFile.fromFile(photo.path, filename: 'quest_photo.jpg'),
        ));
      }

      if (answerText != null) {
        formData.fields.add(MapEntry('answer_text', answerText));
      }

      if (qrScannedData != null) {
        formData.fields.add(MapEntry('qr_scanned_data', qrScannedData));
      }

      final response = await _api.dio.post(
        '/quests/$questId/submit',
        data: formData,
      );

      // Refresh lists
      await loadQuests();
      await loadSubmissions();

      return response.data;
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? 'Gönderim başarısız';
      return {'error': msg};
    }
  }

  /// AI ile yeni görevler üret
  Future<Map<String, dynamic>> generateQuests(double lat, double lng) async {
    _isGenerating = true;
    notifyListeners();

    try {
      final response = await _api.dio.post('/quests/generate', data: {
        'lat': lat,
        'lng': lng,
      });

      await loadQuests();

      _isGenerating = false;
      notifyListeners();
      return response.data;
    } on DioException catch (e) {
      _isGenerating = false;
      notifyListeners();
      final msg = e.response?.data?['error'] ?? 'Görev üretimi başarısız';
      return {'error': msg};
    }
  }

  /// Görev için AI ipucu al (2 puan)
  Future<Map<String, dynamic>> getHint(int questId) async {
    try {
      final response = await _api.dio.get('/quests/$questId/hint');
      return response.data;
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? 'İpucu alınamadı';
      return {'error': msg};
    }
  }

  /// AI öneriler
  Future<void> loadRecommendations() async {
    try {
      final response = await _api.dio.get('/quests/recommendations');
      _recommendations =
          List<Map<String, dynamic>>.from(response.data['recommendations'] ?? []);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadSubmissions() async {
    try {
      final response = await _api.dio.get('/submissions/mine');
      _submissions = (response.data['submissions'] as List)
          .map((s) => Submission.fromJson(s))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadLeaderboard() async {
    try {
      final response = await _api.dio.get('/users/leaderboard');
      _leaderboard = (response.data['leaderboard'] as List)
          .map((u) => User.fromJson(u))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  bool isQuestCompleted(int questId) {
    return _submissions.any((s) => s.questId == questId);
  }

  /// Başarımları yükle
  Future<void> loadAchievements() async {
    try {
      final response = await _api.dio.get('/achievements');
      _achievements = (response.data['achievements'] as List)
          .map((a) => Achievement.fromJson(a))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  /// Günlük meydan okuma
  Future<void> loadDailyChallenge() async {
    try {
      final response = await _api.dio.get('/achievements/daily');
      _dailyChallenge = response.data['daily_challenge'];
      notifyListeners();
    } catch (_) {}
  }

  /// Streak bilgisi
  Future<void> loadStreakInfo() async {
    try {
      final response = await _api.dio.get('/achievements/streak');
      _streakInfo = response.data;
      notifyListeners();
    } catch (_) {}
  }
}
