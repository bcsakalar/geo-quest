import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final _api = ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _api.setToken(response.data['token']);
    return response.data;
  }

  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    final response = await _api.dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
    });
    await _api.setToken(response.data['token']);
    return response.data;
  }

  Future<User> getProfile() async {
    final response = await _api.dio.get('/users/me');
    return User.fromJson(response.data['user']);
  }

  Future<void> logout() async {
    await _api.clearToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null;
  }
}
