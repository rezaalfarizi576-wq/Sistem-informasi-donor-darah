import '../../core/network/api_client.dart';
import '../models/donor_stats_model.dart';
import '../models/blood_stock_model.dart';

class DonorRepository {
  final ApiClient _apiClient;

  DonorRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Mengambil statistik donor (total liter, total donasi, donor terakhir, dll)
  Future<DonorStatsModel> getDonorStats() async {
    final response = await _apiClient.get('/donor/stats');
    return DonorStatsModel.fromJson(response);
  }

  /// Mengambil riwayat lengkap donasi donor
  Future<List<DonationHistoryItemModel>> getDonationHistory() async {
    final response = await _apiClient.get('/donor/history');
    if (response is List) {
      return response
          .map((item) => DonationHistoryItemModel.fromJson(item))
          .toList();
    }
    return [];
  }

  /// Mengambil stok kantong darah live dari UDD PMI Lamongan
  Future<BloodStockResponseModel> getBloodStock() async {
    final response = await _apiClient.get('/donor/blood-stock');
    return BloodStockResponseModel.fromJson(response);
  }

  /// Mencatat riwayat donor baru
  Future<Map<String, dynamic>> addDonationHistory({
    String lokasi = 'UDD PMI Kabupaten Lamongan',
    int bags = 1,
  }) async {
    final response = await _apiClient.post('/donor/history', body: {
      'lokasi': lokasi,
      'bags': bags,
    });
    return response as Map<String, dynamic>;
  }

  /// Mengambil data live tracking terintegrasi
  Future<Map<String, dynamic>> getTrackingStatus(int requestId, {double? lat, double? lng}) async {
    final queryParams = <String, String>{};
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lng != null) queryParams['lng'] = lng.toString();
    final queryString = queryParams.isNotEmpty ? '?${Uri(queryParameters: queryParams).query}' : '';
    final response = await _apiClient.get('/donor/requests/$requestId/tracking$queryString');
    return response as Map<String, dynamic>;
  }

  /// Konfirmasi kedatangan donor di faskes ("Saya Sudah Sampai")
  Future<Map<String, dynamic>> confirmArrival(int requestId) async {
    final response = await _apiClient.post('/donor/requests/$requestId/arrive');
    return response as Map<String, dynamic>;
  }
}
