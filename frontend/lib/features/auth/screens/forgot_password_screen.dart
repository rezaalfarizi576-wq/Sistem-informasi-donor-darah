import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/url_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authRepo = AuthRepository();

  // Step state: 0 = Input Identitas, 1 = Verifikasi OTP, 2 = Set Password Baru
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers Step 0
  final _identifierController = TextEditingController();

  // Data from OTP request
  String _targetPhone = '';
  String _phonePreview = '';
  String _emailPreview = '';
  String _userName = '';
  String _latestOtp = '';

  // Controllers Step 1 (4 Digit OTP)
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  // Timer Step 1
  Timer? _countdownTimer;
  int _resendCountdown = 60;
  bool _canResend = false;

  // Controllers Step 2
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _identifierController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _countdownTimer?.cancel();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  // --- STEP 0: Request OTP ---
  Future<void> _handleRequestOtp({bool isResend = false}) async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      _showError('Silakan masukkan Email, Nomor HP, atau NIK Anda');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _authRepo.requestPasswordResetOtp(identifier);
      if (!mounted) return;

      setState(() {
        _latestOtp = res['otp_code'] ?? '';
        _targetPhone = res['phone'] ?? '';
        _phonePreview = res['phone_preview'] ?? '';
        _emailPreview = res['email_preview'] ?? '';
        _userName = res['user_name'] ?? '';
        _currentStep = 1;
      });

      _startResendTimer();

      // Show notification banner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, color: Color(0xFF4ADE80), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isResend ? 'OTP Baru Telah Dikirim' : 'Kode OTP PMI Diterima',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Halo $_userName, kode verifikasi Anda: $_latestOtp',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  _fillOtp(_latestOtp);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF60A5FA),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Isi Cepat', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fillOtp(String code) {
    if (code.length < 4) return;
    for (int i = 0; i < 4; i++) {
      _otpControllers[i].text = code[i];
    }
    _otpFocusNodes[3].requestFocus();
    setState(() {});
  }

  // --- STEP 1: Verify OTP & Advance ---
  void _handleVerifyOtp() {
    final enteredOtp = _otpControllers.map((c) => c.text.trim()).join();
    if (enteredOtp.length < 4) {
      _showError('Masukkan 4 digit kode OTP secara lengkap');
      return;
    }

    if (enteredOtp != _latestOtp) {
      _showError('Kode OTP tidak sesuai. Silakan periksa kembali!');
      return;
    }

    // OTP Valid -> Pindah ke Step 2 (Reset Password)
    setState(() {
      _currentStep = 2;
    });
  }

  // --- STEP 2: Submit New Password ---
  Future<void> _handleResetPassword() async {
    final newPass = _passwordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass.length < 6) {
      _showError('Password minimal harus terdiri dari 6 karakter');
      return;
    }

    if (newPass != confirmPass) {
      _showError('Konfirmasi password tidak cocok');
      return;
    }

    final enteredOtp = _otpControllers.map((c) => c.text.trim()).join();
    final identifier = _identifierController.text.trim();

    setState(() => _isLoading = true);
    try {
      final res = await _authRepo.resetPasswordWithOtp(
        identifier: identifier,
        otpCode: enteredOtp,
        newPassword: newPass,
      );

      if (!mounted) return;

      // Sukses!
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Reset Berhasil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            res['message'] ?? 'Password Anda telah berhasil diperbarui. Silakan masuk kembali menggunakan password baru.',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop(); // Tutup dialog
                Navigator.of(context).pop(); // Balik ke Login Screen
              },
              child: const Text('Masuk Sekarang'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openWhatsAppOtp() {
    final phone = _targetPhone.isNotEmpty ? _targetPhone : _identifierController.text.trim();
    final message =
        'Halo PMI Kabupaten Lamongan, ini permintaan reset password untuk akun saya ($_userName). '
        'Kode OTP verifikasi saya adalah: $_latestOtp (berlaku 5 menit).';
    UrlHelper.openWhatsApp(context, rawPhone: phone, message: message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pemulihan Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  // Progress Step Header
                  _buildStepIndicator(),
                  const SizedBox(height: 24),

                  // Step Content Card
                  if (_currentStep == 0) _buildStep0InputIdentifier(),
                  if (_currentStep == 1) _buildStep1VerifyOtp(),
                  if (_currentStep == 2) _buildStep2NewPassword(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepItem(0, '1. Akun', Icons.person_search_rounded),
          _buildStepDivider(0),
          _buildStepItem(1, '2. Kode OTP', Icons.sms_outlined),
          _buildStepDivider(1),
          _buildStepItem(2, '3. Password', Icons.lock_reset_rounded),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepIndex, String title, IconData icon) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    Color color;
    if (isActive) {
      color = const Color(0xFFD32F2F);
    } else if (isDone) {
      color = const Color(0xFF16A34A);
    } else {
      color = Colors.grey.shade400;
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(
            isDone ? Icons.check : icon,
            size: 15,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFFD32F2F) : (isDone ? const Color(0xFF16A34A) : Colors.grey.shade500),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int stepIndex) {
    final isDone = _currentStep > stepIndex;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: isDone ? const Color(0xFF16A34A) : Colors.grey.shade200,
      ),
    );
  }

  // ================= STEP 0: Masukkan Identitas =================
  Widget _buildStep0InputIdentifier() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_clock_rounded, size: 34, color: Color(0xFFD32F2F)),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Lupa Kata Sandi?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Masukkan No. HP, Email, atau NIK yang terdaftar pada sistem PMI Kabupaten Lamongan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
            ),
          ),
          const SizedBox(height: 28),

          const Text(
            'Identitas Akun',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _identifierController,
            label: 'No. HP / Email / NIK',
            hint: 'Contoh: 08123456789 atau user@gmail.com',
            prefixIcon: Icons.account_circle_outlined,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 12),

          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sistem akan memverifikasi akun Anda dan mengirimkan 4-digit kode OTP langsung secara aman.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          CustomButton(
            text: 'Kirim Kode OTP',
            icon: Icons.send_rounded,
            isLoading: _isLoading,
            onPressed: () => _handleRequestOtp(),
          ),
          const SizedBox(height: 12),

          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Kembali ke Login'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= STEP 1: Verifikasi OTP =================
  Widget _buildStep1VerifyOtp() {
    return Column(
      children: [
        // Live Notification Banner Style (Push Notification Simulator)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security_rounded, color: Color(0xFFF87171), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'SIMULASI NOTIFIKASI PMI LAMONGAN',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'AKTIF',
                      style: TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Halo, $_userName!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  text: 'Kode verifikasi reset password Anda adalah: ',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  children: [
                    TextSpan(
                      text: _latestOtp,
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _fillOtp(_latestOtp),
                      icon: const Icon(Icons.flash_on_rounded, size: 16),
                      label: const Text('Terapkan Kode Otomatis', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _openWhatsAppOtp,
                    icon: const Icon(Icons.chat_outlined, size: 16),
                    label: const Text('Buka WA', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // OTP Input Form Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Masukkan 4 Digit Kode OTP',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              Text(
                'Kode verifikasi telah dikirim untuk akun:\n${_phonePreview.isNotEmpty ? _phonePreview : _emailPreview}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 28),

              // 4 OTP Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => _buildOtpBox(index)),
              ),
              const SizedBox(height: 28),

              // Countdown / Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: _canResend ? const Color(0xFFD32F2F) : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  if (!_canResend)
                    Text(
                      'Kirim ulang dalam $_resendCountdown detik',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    )
                  else
                    TextButton(
                      onPressed: _isLoading ? null : () => _handleRequestOtp(isResend: true),
                      child: const Text(
                        'Kirim Ulang Kode OTP',
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              CustomButton(
                text: 'Verifikasi Kode',
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isLoading,
                onPressed: _handleVerifyOtp,
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  setState(() => _currentStep = 0);
                },
                child: const Text('Ubah Nomor / Email'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 58,
      height: 64,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 3) {
              _otpFocusNodes[index + 1].requestFocus();
            } else {
              _otpFocusNodes[index].unfocus();
              // Otomatis verifikasi jika digit ke-4 sudah diisi
              _handleVerifyOtp();
            }
          } else {
            if (index > 0) {
              _otpFocusNodes[index - 1].requestFocus();
            }
          }
          setState(() {});
        },
      ),
    );
  }

  // ================= STEP 2: Password Baru =================
  Widget _buildStep2NewPassword() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_rounded, size: 34, color: Color(0xFF16A34A)),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Buat Kata Sandi Baru',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Silakan tentukan kata sandi baru untuk akun $_userName.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Password Baru',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _passwordController,
            label: 'Password Baru',
            hint: 'Minimal 6 karakter',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: Validators.password,
          ),
          const SizedBox(height: 18),

          const Text(
            'Konfirmasi Password Baru',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Konfirmasi Password',
            hint: 'Ulangi password baru',
            prefixIcon: Icons.lock_reset_rounded,
            obscureText: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: Validators.password,
          ),
          const SizedBox(height: 28),

          CustomButton(
            text: 'Simpan Password Baru',
            icon: Icons.check_circle_rounded,
            isLoading: _isLoading,
            onPressed: _handleResetPassword,
          ),
          const SizedBox(height: 12),

          Center(
            child: TextButton(
              onPressed: () {
                setState(() => _currentStep = 1);
              },
              child: const Text('Kembali ke Verifikasi OTP'),
            ),
          ),
        ],
      ),
    );
  }
}

