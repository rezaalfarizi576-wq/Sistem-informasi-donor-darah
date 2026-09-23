import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<UserModel> register(Map<String, dynamic> userData) async {
    final response = await _apiClient.post('/auth/register', body: userData);
    return UserModel.fromJson(response);
  }

  Future<UserModel> login(String email, String password) async {
    final response = await _apiClient.post(
      '/auth/login',
      isFormData: true,
      body: {
        'username': email,
        'password': password,
      },
    );

    final token = response['access_token'] as String;
    final user = UserModel.fromJson(response['user']);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    await prefs.setString('user_role', user.role);
    await prefs.setInt('user_id', user.id);

    return user;
  }

  Future<UserModel> activateAccount({
    required String nik,
    required String email,
    required String password,
    required String phone,
  }) async {
    final response = await _apiClient.post('/auth/activate', body: {
      'nik': nik,
      'email': email,
      'password': password,
      'phone': phone,
    });
    return UserModel.fromJson(response);
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me');
      return UserModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_role');
    await prefs.remove('user_id');
  }

  Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('access_token');
  }
}
