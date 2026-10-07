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
}
