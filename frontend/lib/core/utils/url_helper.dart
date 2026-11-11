import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlHelper {
  /// Membuka aplikasi dialer / panggilan telepon
  static Future<bool> makePhoneCall(BuildContext context, String rawPhone) async {
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      _showToast(context, 'Nomor telepon tidak valid');
      return false;
    }

    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (e) {
      if (context.mounted) {
        _showToast(context, 'Gagal membuka telepon: $e');
      }
      return false;
    }
  }

  /// Membuka obrolan WhatsApp dengan nomor dan pesan otomatis (opsional)
  static Future<bool> openWhatsApp(
    BuildContext context, {
    required String rawPhone,
    String? message,
  }) async {
    // Bersihkan karakter non-angka
    var digitsOnly = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');

    // Format nomor WhatsApp internasional: ganti prefix 08xx jadi 628xx
    if (digitsOnly.startsWith('0')) {
      digitsOnly = '62${digitsOnly.substring(1)}';
    } else if (digitsOnly.startsWith('8')) {
      digitsOnly = '62$digitsOnly';
    }

    if (digitsOnly.length < 8) {
      _showToast(context, 'Nomor WhatsApp tidak valid');
      return false;
    }

    final encodedMsg = message != null && message.trim().isNotEmpty
        ? Uri.encodeComponent(message.trim())
        : null;

    final waUrlString = encodedMsg != null
        ? 'https://wa.me/$digitsOnly?text=$encodedMsg'
        : 'https://wa.me/$digitsOnly';

    final uri = Uri.parse(waUrlString);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showToast(context, 'Tidak dapat membuka WhatsApp');
      }
      return launched;
    } catch (e) {
      if (context.mounted) {
        _showToast(context, 'Gagal membuka WhatsApp: $e');
      }
      return false;
    }
  }

  static void _showToast(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

