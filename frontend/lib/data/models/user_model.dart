class UserModel {
  final int id;
  final String nik;
  final String name;
  final String email;
  final String role; // 'admin', 'donor', 'requester'
  final String? phone;
  final String? bloodType;
  final String? rhesus;
  final String? address;
  final bool isActive;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.nik,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.bloodType,
    this.rhesus,
    this.address,
    required this.isActive,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      nik: json['nik'] as String? ?? json['id_pmi'] as String? ?? '',
      name: json['nama'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'donor',
      phone: json['no_hp'] as String? ?? json['phone'] as String?,
      bloodType: json['blood_type'] as String?,
      rhesus: json['rhesus'] as String?,
      address: json['address'] as String?,
      isActive: json['status_aktif'] as bool? ?? json['is_activated'] as bool? ?? json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nik': nik,
      'nama': name,
      'email': email,
      'role': role,
      'no_hp': phone,
      'blood_type': bloodType,
      'rhesus': rhesus,
      'address': address,
      'status_aktif': isActive,
    };
  }

  /// Display label: blood type + rhesus
  String get bloodLabel {
    if (bloodType == null || bloodType!.isEmpty) return '-';
    return '$bloodType${rhesus ?? "+"}';
  }
}

