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

  Future<Map<String, dynamic>> respondToRequest(int requestId) async {
    final response = await _apiClient.post('/requests/$requestId/respond');
    return response as Map<String, dynamic>;
  }
}
