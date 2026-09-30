class Validators {
  static String? required(String? value, {String fieldName = 'Bidang ini'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? nik(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NIK wajib diisi';
    }
    if (value.trim().length != 16) {
      return 'NIK harus terdiri dari 16 digit';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
      return 'NIK hanya boleh berisi angka';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // optional
    }
    if (!RegExp(r'^[0-9\-\+]+$').hasMatch(value.trim())) {
      return 'Nomor telepon tidak valid';
    }
    return null;
  }
}
