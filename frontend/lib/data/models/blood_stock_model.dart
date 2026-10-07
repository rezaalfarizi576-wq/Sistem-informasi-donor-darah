class BloodStockResponseModel {
  final UddInfoModel uddInfo;
  final int totalBags;
  final List<BloodStockItemModel> stocks;

  BloodStockResponseModel({
    required this.uddInfo,
    required this.totalBags,
    required this.stocks,
  });

  factory BloodStockResponseModel.fromJson(Map<String, dynamic> json) {
    return BloodStockResponseModel(
      uddInfo: UddInfoModel.fromJson(json['udd_info'] ?? {}),
      totalBags: json['total_bags'] ?? 0,
      stocks: (json['stocks'] as List<dynamic>? ?? [])
          .map((item) => BloodStockItemModel.fromJson(item))
          .toList(),
    );
  }
}

class UddInfoModel {
  final String name;
  final String address;
  final String phone;
  final String callCenter;
  final String operatingHours;

  UddInfoModel({
    required this.name,
    required this.address,
    required this.phone,
    required this.callCenter,
    required this.operatingHours,
  });

  factory UddInfoModel.fromJson(Map<String, dynamic> json) {
    return UddInfoModel(
      name: json['name'] ?? 'UDD PMI Kab. Lamongan',
      address: json['address'] ?? 'Jl. Kombespol M. Duryat No. 42, Jetis, Lamongan',
      phone: json['phone'] ?? '(0322) 321118',
      callCenter: json['call_center'] ?? '(0322) 321118',
      operatingHours: json['operating_hours'] ?? 'Buka 24 Jam',
    );
  }
}

class BloodStockItemModel {
  final int id;
  final String bloodType;
  final String rhesus;
  final String label;
  final int bags;
  final String status;
  final String? updatedAt;

  BloodStockItemModel({
    required this.id,
    required this.bloodType,
    required this.rhesus,
    required this.label,
    required this.bags,
    required this.status,
    this.updatedAt,
  });

  factory BloodStockItemModel.fromJson(Map<String, dynamic> json) {
    return BloodStockItemModel(
      id: json['id'] ?? 0,
      bloodType: json['blood_type'] ?? 'O',
      rhesus: json['rhesus'] ?? '+',
      label: json['label'] ?? 'Golongan ${json['blood_type'] ?? 'O'}+',
      bags: json['bags'] ?? 0,
      status: json['status'] ?? 'Aman',
      updatedAt: json['updated_at'],
    );
  }
}
