import '../../core/network/api_client.dart';
import '../models/user_model.dart';
import '../models/blood_request_model.dart';

class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // ── Dashboard Stats ──
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _apiClient.get('/admin/stats');
    return Map<String, dynamic>.from(response);
  }

  // ── Users (Relawan/Donor) ──
  Future<List<UserModel>> getAllUsers() async {
    final response = await _apiClient.get('/admin/users');
    if (response is List) {
      return response.map((item) => UserModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<UserModel>> getDonors() async {
    final users = await getAllUsers();
    return users.where((u) => u.role == 'donor').toList();
  }

  Future<List<UserModel>> getRequesters() async {
    final users = await getAllUsers();
    return users.where((u) => u.role == 'requester').toList();
  }

  // ── Blood Requests ──
  Future<List<BloodRequestModel>> getBloodRequests({String? status}) async {
    final endpoint = status != null
        ? '/admin/requests?status=$status'
        : '/admin/requests';
    final response = await _apiClient.get(endpoint);
    if (response is List) {
      return response.map((item) => BloodRequestModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<BloodRequestModel> updateRequestStatus(int requestId, String newStatus) async {
    final response = await _apiClient.put(
      '/admin/requests/$requestId',
      body: {'status': newStatus},
    );
    return BloodRequestModel.fromJson(response);
  }

  // ── Donor Locations ──
  Future<List<Map<String, dynamic>>> getDonorLocations() async {
    final response = await _apiClient.get('/admin/locations');
    if (response is List) {
      return response.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    return [];
  }

  // ── Health Facilities (Faskes) ──
  Future<List<Map<String, dynamic>>> getHealthFacilities() async {
    final response = await _apiClient.get('/admin/facilities');
    if (response is List) {
      return response.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createHealthFacility(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/admin/facilities', body: data);
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> updateHealthFacility(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('/admin/facilities/$id', body: data);
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> toggleVerifyFacility(int id) async {
    final response = await _apiClient.patch('/admin/facilities/$id/verify');
    return Map<String, dynamic>.from(response);
  }

  Future<void> deleteHealthFacility(int id) async {
    await _apiClient.delete('/admin/facilities/$id');
  }

  // ── Reports & Summary ──
  Future<Map<String, dynamic>> getReportsSummary() async {
    final response = await _apiClient.get('/admin/reports/summary');
    return Map<String, dynamic>.from(response);
  }

  // ── System Settings ──
  Future<Map<String, dynamic>> getSystemSettings() async {
    final response = await _apiClient.get('/admin/settings');
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> updateSystemSettings(Map<String, dynamic> settings) async {
    final response = await _apiClient.post('/admin/settings', body: settings);
    return Map<String, dynamic>.from(response);
  }
}
