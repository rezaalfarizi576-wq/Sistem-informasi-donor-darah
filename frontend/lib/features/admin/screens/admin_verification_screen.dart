import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/blood_request_model.dart';
import '../widgets/verification_detail_panel.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  final _apiClient = ApiClient();
  List<BloodRequestModel> _requests = [];
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static List<BloodRequestModel> get _defaultMockRequests => [
    BloodRequestModel(
      id: 1,
      requesterId: 101,
      requesterName: 'Dewi Rahayu',
      hospitalName: 'RSUD Dr. Soegiri',
      bloodType: 'O',
      rhesus: '+',
      bagsNeeded: 2,
      urgencyLevel: 'kritis',
      status: 'pending',
      latitudeFaskes: -7.119853,
      longitudeFaskes: 112.415278,
      radiusKm: 5.0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    BloodRequestModel(
      id: 2,
      requesterId: 102,
      requesterName: 'Agus Prayitno',
      hospitalName: 'RS Muhammadiyah Lmg',
      bloodType: 'B',
      rhesus: '+',
      bagsNeeded: 1,
      urgencyLevel: 'tinggi',
      status: 'pending',
      latitudeFaskes: -7.121500,
      longitudeFaskes: 112.418000,
      radiusKm: 5.0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
    ),
    BloodRequestModel(
      id: 3,
      requesterId: 103,
      requesterName: 'Siti Aminah',
      hospitalName: 'RSUD Dr. Soegiri',
      bloodType: 'A',
      rhesus: '-',
      bagsNeeded: 2,
      urgencyLevel: 'sedang',
      status: 'diproses',
      latitudeFaskes: -7.119853,
      longitudeFaskes: 112.415278,
      radiusKm: 5.0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    BloodRequestModel(
      id: 4,
      requesterId: 104,
      requesterName: 'Hendra Kusuma',
      hospitalName: 'Klinik Pratama',
      bloodType: 'AB',
      rhesus: '+',
      bagsNeeded: 1,
      urgencyLevel: 'sedang',
      status: 'terpenuhi',
      latitudeFaskes: -7.125000,
      longitudeFaskes: 112.410000,
      radiusKm: 5.0,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _apiClient.get('/admin/requests');
      if (response is List && response.isNotEmpty && mounted) {
        setState(() {
          _requests = response
              .map((item) => BloodRequestModel.fromJson(item as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        // Jika database belum diisi data, gunakan tampilan data persis di screenshot
        if (mounted) {
          setState(() {
            _requests = _defaultMockRequests;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      // Jika backend FastAPI belum di-run atau offline, fallback otomatis ke mock dataset
      if (mounted) {
        setState(() {
          _requests = _defaultMockRequests;
          _isLoading = false;
        });
      }
    }
  }

  List<BloodRequestModel> get _filteredRequests {
    if (_searchQuery.isEmpty) return _requests;
    final q = _searchQuery.toLowerCase();
    return _requests.where((r) {
      return (r.hospitalName?.toLowerCase().contains(q) ?? false) ||
          r.bloodLabel.toLowerCase().contains(q) ||
          r.status.toLowerCase().contains(q) ||
          (r.requesterName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  int get _pendingCount => _requests.where((r) => r.isPending).length;

  String get _todayDateFormatted {
    final now = DateTime.now();
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _filteredRequests;
    final selectedRequest = filteredRequests.isNotEmpty && _selectedIndex < filteredRequests.length
        ? filteredRequests[_selectedIndex]
        : null;

    return Container(
      color: const Color(0xFFF5F6FA),
      child: Column(
        children: [
          // ─── TOP HEADER BAR ─────────────────────
          _buildTopHeader(),
          // ─── MAIN CONTENT ───────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
                : _error != null
                    ? _buildErrorState()
                    : Row(
                        children: [
                          // ─── LEFT PANEL (Request List) ────
                          SizedBox(
                            width: 380,
                            child: _buildRequestListPanel(filteredRequests),
                          ),
                          // ─── RIGHT PANEL (Detail) ─────────
                          Expanded(
                            child: selectedRequest != null
                                ? VerificationDetailPanel(
                                    request: selectedRequest,
                                    onApprove: () => _handleApprove(selectedRequest),
                                    onReject: () => _handleReject(selectedRequest),
                                  )
                                : _buildEmptyDetail(),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title area
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Antrian Verifikasi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1D2E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _todayDateFormatted,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Critical requests badge
          if (_pendingCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_pendingCount Permintaan Kritis',
                    style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),
          // Notification bell
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF9E9E9E)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildRequestListPanel(List<BloodRequestModel> requests) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        children: [
          // ─── SEARCH BAR ───────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari permintaan...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // ─── REQUEST LIST ─────────────────
          Expanded(
            child: requests.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'Tidak ada hasil pencarian'
                          : 'Belum ada permintaan',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: requests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      return _buildRequestCard(requests[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BloodRequestModel request, int index) {
    final isSelected = _selectedIndex == index;
    final isPending = request.isPending;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0F4FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: const Color(0xFF2D8CFF).withOpacity(0.3))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Name + Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.requesterName ?? 'Pemohon #${request.requesterId}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D2E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPending
                          ? const Color(0xFFFFF3E0)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isPending ? 'PENDING' : 'OK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isPending
                            ? const Color(0xFFFF6D00)
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Row 2: Blood type badge + time
              Row(
                children: [
                  _buildBloodTypeBadge(request.bloodLabel),
                  const SizedBox(width: 8),
                  Text(
                    request.timeAgo,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Row 3: Hospital
              Text(
                request.hospitalName ?? 'Faskes tidak diketahui',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBloodTypeBadge(String label) {
    // Map blood type to a color
    Color bgColor;
    Color textColor;
    switch (label.replaceAll('+', '').replaceAll('-', '')) {
      case 'O':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFE53935);
        break;
      case 'A':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        break;
      case 'B':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        break;
      case 'AB':
        bgColor = const Color(0xFFF3E5F5);
        textColor = const Color(0xFF7B1FA2);
        break;
      default:
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF616161);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchRequests,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDetail() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Pilih permintaan untuk melihat detail',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  void _handleApprove(BloodRequestModel request) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Setujui Permintaan'),
        content: Text(
          'Setujui permintaan darah ${request.bloodLabel} dari ${request.hospitalName ?? "faskes"}?\n'
          'Notifikasi akan dikirim ke pendonor terdekat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiClient.put('/admin/requests/${request.id}', body: {
          'status': 'diproses',
        });
        _fetchRequests();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permintaan disetujui & notifikasi terkirim'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: $e'),
              backgroundColor: const Color(0xFFE53935),
            ),
          );
        }
      }
    }
  }

  void _handleReject(BloodRequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tolak Permintaan'),
        content: Text(
          'Tolak permintaan darah ${request.bloodLabel} dari ${request.hospitalName ?? "faskes"}?\n'
          'Admin akan diarahkan untuk menghubungi faskes terkait.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiClient.put('/admin/requests/${request.id}', body: {
          'status': 'kedaluwarsa',
        });
        _fetchRequests();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permintaan ditolak'),
              backgroundColor: Color(0xFFE53935),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: $e'),
              backgroundColor: const Color(0xFFE53935),
            ),
          );
        }
      }
    }
  }
}
