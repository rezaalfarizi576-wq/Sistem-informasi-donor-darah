class DonorStatsModel {
  final int donorId;
  final int totalDonations;
  final String totalDonationsDisplay;
  final int totalBags;
  final double totalLiters;
  final String totalLitersDisplay;
  final String lastDonationDisplay;
  final String lastDonationYear;
  final bool eligibleToDonate;
  final int daysSinceLast;
  final String pmiStatus;
  final DonationHistoryItemModel? latestDonation;

  DonorStatsModel({
    required this.donorId,
    required this.totalDonations,
    required this.totalDonationsDisplay,
    required this.totalBags,
    required this.totalLiters,
    required this.totalLitersDisplay,
    required this.lastDonationDisplay,
    required this.lastDonationYear,
    required this.eligibleToDonate,
    required this.daysSinceLast,
    required this.pmiStatus,
    this.latestDonation,
  });

  factory DonorStatsModel.fromJson(Map<String, dynamic> json) {
    return DonorStatsModel(
      donorId: json['donor_id'] ?? 0,
      totalDonations: json['total_donations'] ?? 0,
      totalDonationsDisplay: json['total_donations_display'] ?? '0 kali donasi',
      totalBags: json['total_bags'] ?? 0,
      totalLiters: (json['total_liters'] as num?)?.toDouble() ?? 0.0,
      totalLitersDisplay: json['total_liters_display'] ?? '0.0 L',
      lastDonationDisplay: json['last_donation_display'] ?? '-',
      lastDonationYear: json['last_donation_year'] ?? '-',
      eligibleToDonate: json['eligible_to_donate'] ?? true,
      daysSinceLast: json['days_since_last'] ?? 0,
      pmiStatus: json['pmi_status'] ?? 'Relawan Aktif',
      latestDonation: json['latest_donation'] != null
          ? DonationHistoryItemModel.fromJson(json['latest_donation'])
          : null,
    );
  }
}

class DonationHistoryItemModel {
  final int id;
  final String date;
  final String? rawDate;
  final String location;
  final String type;
  final String bags;
  final int volumeMl;
  final String status;

  DonationHistoryItemModel({
    required this.id,
    required this.date,
    this.rawDate,
    required this.location,
    required this.type,
    required this.bags,
    required this.volumeMl,
    required this.status,
  });

  factory DonationHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return DonationHistoryItemModel(
      id: json['id'] ?? 0,
      date: json['formatted_date'] ?? json['date'] ?? '-',
      rawDate: json['raw_date'],
      location: json['location'] ?? 'UDD PMI Kabupaten Lamongan',
      type: json['type'] ?? 'Donor Darah Biasa (Whole Blood)',
      bags: json['bags_display'] ?? json['bags']?.toString() ?? '1 Kantong',
      volumeMl: json['volume_ml'] ?? 350,
      status: json['status'] ?? 'Berhasil',
    );
  }
}
