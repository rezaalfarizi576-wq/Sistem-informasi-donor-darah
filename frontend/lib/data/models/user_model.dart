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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      nik: json['nik'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'donor',
      phone: json['phone'] as String?,
      bloodType: json['blood_type'] as String?,
      rhesus: json['rhesus'] as String?,
      address: json['address'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nik': nik,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'blood_type': bloodType,
      'rhesus': rhesus,
      'address': address,
      'is_active': isActive,
    };
  }
}
