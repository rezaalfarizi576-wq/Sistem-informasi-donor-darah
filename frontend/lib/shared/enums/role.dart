enum UserRole {
  admin,
  donor,
  requester;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'requester':
        return UserRole.requester;
      case 'donor':
      default:
        return UserRole.donor;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Petugas Admin PMI';
      case UserRole.donor:
        return 'Pendonor Darah';
      case UserRole.requester:
        return 'Pemohon Darah';
    }
  }
}
