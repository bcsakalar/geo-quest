import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SocialProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _feed = [];
  List<Map<String, dynamic>> _searchResults = [];
  int _unreadNotifications = 0;
  int _unreadMessages = 0;
  // ignore: prefer_final_fields
  bool _isLoading = false;

  List<Map<String, dynamic>> get friends => _friends;
  List<Map<String, dynamic>> get pendingRequests => _pendingRequests;
  List<Map<String, dynamic>> get conversations => _conversations;
  List<Map<String, dynamic>> get notifications => _notifications;
  List<Map<String, dynamic>> get feed => _feed;
  List<Map<String, dynamic>> get searchResults => _searchResults;
  int get unreadNotifications => _unreadNotifications;
  int get unreadMessages => _unreadMessages;
  int get totalUnread => _unreadNotifications + _unreadMessages;
  bool get isLoading => _isLoading;

  // ──── Arkadaşlar ────

  Future<void> loadFriends() async {
    try {
      final response = await _api.dio.get('/friends');
      _friends = List<Map<String, dynamic>>.from(response.data['friends'] ?? []);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadPendingRequests() async {
    try {
      final response = await _api.dio.get('/friends/requests');
      _pendingRequests = List<Map<String, dynamic>>.from(response.data['requests'] ?? []);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    try {
      final response = await _api.dio.get('/friends/search', queryParameters: {'q': query});
      _searchResults = List<Map<String, dynamic>>.from(response.data['users'] ?? []);
      notifyListeners();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> sendFriendRequest(int userId) async {
    try {
      final response = await _api.dio.post('/friends/request', data: {'user_id': userId});
      await loadFriends();
      await loadPendingRequests();
      return response.data;
    } on DioException catch (e) {
      return {'error': e.response?.data?['error'] ?? 'İstek gönderilemedi'};
    }
  }

  Future<Map<String, dynamic>> acceptRequest(int friendshipId) async {
    try {
      final response = await _api.dio.post('/friends/$friendshipId/accept');
      await loadFriends();
      await loadPendingRequests();
      return response.data;
    } on DioException catch (e) {
      return {'error': e.response?.data?['error'] ?? 'Kabul edilemedi'};
    }
  }

  Future<Map<String, dynamic>> rejectRequest(int friendshipId) async {
    try {
      final response = await _api.dio.post('/friends/$friendshipId/reject');
      await loadPendingRequests();
      return response.data;
    } on DioException catch (e) {
      return {'error': e.response?.data?['error'] ?? 'Reddedilemedi'};
    }
  }

  Future<void> removeFriend(int friendshipId) async {
    try {
      await _api.dio.delete('/friends/$friendshipId');
      await loadFriends();
    } catch (_) {}
  }

  // ──── Mesajlar ────

  Future<void> loadConversations() async {
    try {
      final response = await _api.dio.get('/messages');
      _conversations = List<Map<String, dynamic>>.from(response.data['conversations'] ?? []);
      _unreadMessages = response.data['unread_total'] ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> loadMessages(int userId) async {
    try {
      final response = await _api.dio.get('/messages/$userId');
      return List<Map<String, dynamic>>.from(response.data['messages'] ?? []);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> sendMessage(int userId, String content) async {
    try {
      final response = await _api.dio.post('/messages/$userId', data: {'content': content});
      await loadConversations();
      return response.data['message'];
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> sendChallenge(int userId, int questId) async {
    try {
      final response = await _api.dio.post('/messages/$userId/challenge', data: {'quest_id': questId});
      await loadConversations();
      return response.data;
    } on DioException catch (e) {
      return {'error': e.response?.data?['error'] ?? 'Meydan okuma gönderilemedi'};
    }
  }

  // ──── Bildirimler ────

  Future<void> loadNotifications() async {
    try {
      final response = await _api.dio.get('/social/notifications');
      _notifications = List<Map<String, dynamic>>.from(response.data['notifications'] ?? []);
      _unreadNotifications = response.data['unread_count'] ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markNotificationsRead() async {
    try {
      await _api.dio.post('/social/notifications/read');
      _unreadNotifications = 0;
      for (var n in _notifications) {
        n['is_read'] = true;
      }
      notifyListeners();
    } catch (_) {}
  }

  // ──── Feed ────

  Future<void> loadFeed() async {
    try {
      final response = await _api.dio.get('/social/feed');
      _feed = List<Map<String, dynamic>>.from(response.data['feed'] ?? []);
      notifyListeners();
    } catch (_) {}
  }

  // ──── Unread Counts ────

  Future<void> loadUnreadCounts() async {
    try {
      final response = await _api.dio.get('/social/unread');
      _unreadNotifications = response.data['notifications'] ?? 0;
      _unreadMessages = response.data['messages'] ?? 0;
      notifyListeners();
    } catch (_) {}
  }
}
