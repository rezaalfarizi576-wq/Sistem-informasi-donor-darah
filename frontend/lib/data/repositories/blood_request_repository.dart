import '../../core/network/api_client.dart';
import '../models/blood_request_model.dart';

class BloodRequestRepository {
  final ApiClient _apiClient;

  BloodRequestRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<BloodRequestModel> createRequest(Map<String, dynamic> requestData) async {
    final response = await _apiClient.post('/admin/requests', body: requestData);
    return BloodRequestModel.fromJson(response);
  }

  Future<List<BloodRequestModel>> getRequests({String? status}) async {
    final endpoint = status != null ? '/admin/requests?status=$status' : '/admin/requests';
    final response = await _apiClient.get(endpoint);
    if (response is List) {
      return response.map((item) => BloodRequestModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<BloodRequestModel> getRequestById(int requestId) async {
    final response = await _apiClient.get('/requests/$requestId');
    return BloodRequestModel.fromJson(response);
  }

  Future<Map<String, dynamic>> respondToRequest(int requestId) async {
    final response = await _apiClient.post('/requests/$requestId/respond');
    return response as Map<String, dynamic>;
  }

  /// Mengambil permohonan darah darurat yang berada dalam radius 5 - 10 km dari posisi donor
  Future<List<BloodRequestModel>> getNearbyRequests({
    double? lat,
    double? lng,
    double maxRadius = 10.0,
  }) async {
    try {
      final params = <String>[];
      if (lat != null) params.add('lat=$lat');
      if (lng != null) params.add('lng=$lng');
      params.add('max_radius=$maxRadius');

      final endpoint = '/donor/nearby-requests?${params.join('&')}';
      final response = await _apiClient.get(endpoint);
      if (response is Map<String, dynamic> && response['requests'] is List) {
        final list = response['requests'] as List;
        return list.map((item) => BloodRequestModel.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }
}
