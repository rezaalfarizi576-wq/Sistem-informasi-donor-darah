class DonorLocationModel {
  final int id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? contactNumber;
  final String? operatingHours;
  final bool isActive;

  DonorLocationModel({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.contactNumber,
    this.operatingHours,
    required this.isActive,
  });

  factory DonorLocationModel.fromJson(Map<String, dynamic> json) {
    return DonorLocationModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      contactNumber: json['contact_number'] as String?,
      operatingHours: json['operating_hours'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'contact_number': contactNumber,
      'operating_hours': operatingHours,
      'is_active': isActive,
    };
  }
}
