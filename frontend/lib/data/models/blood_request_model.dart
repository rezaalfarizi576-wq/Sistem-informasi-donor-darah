class BloodRequestModel {
  final int id;
  final int requesterId;
  final int? facilityId;
  final String bloodType;
  final String rhesus;
  final int bagsNeeded;
  final String urgencyLevel; // 'sedang', 'tinggi', 'kritis'
  final double latitudeFaskes;
  final double longitudeFaskes;
  final double radiusKm;
  final String? notes;
  final String? hospitalName;
  final String status; // 'menunggu', 'diproses', 'terpenuhi', 'kedaluwarsa'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Fields for UI display (populated locally)
  final String? requesterName;
  final String? requesterPhone;

  BloodRequestModel({
    required this.id,
    required this.requesterId,
    this.facilityId,
    required this.bloodType,
    required this.rhesus,
    required this.bagsNeeded,
    required this.urgencyLevel,
    required this.latitudeFaskes,
    required this.longitudeFaskes,
    required this.radiusKm,
    this.notes,
    this.hospitalName,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.requesterName,
    this.requesterPhone,
  });

  factory BloodRequestModel.fromJson(Map<String, dynamic> json) {
    return BloodRequestModel(
      id: json['id'] as int,
      requesterId: json['requester_id'] as int,
      facilityId: json['facility_id'] as int?,
      bloodType: json['blood_type'] as String? ?? '',
      rhesus: json['rhesus'] as String? ?? '+',
      bagsNeeded: json['bags_needed'] as int? ?? 1,
      urgencyLevel: json['urgency_level'] as String? ?? 'sedang',
      latitudeFaskes: (json['latitude_faskes'] as num?)?.toDouble() ?? 0.0,
      longitudeFaskes: (json['longitude_faskes'] as num?)?.toDouble() ?? 0.0,
      radiusKm: (json['radius_km'] as num?)?.toDouble() ?? 5.0,
      notes: json['notes'] as String?,
      hospitalName: json['hospital_name'] as String?,
      status: json['status'] as String? ?? 'menunggu',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      requesterName: json['requester_name'] as String?,
      requesterPhone: json['requester_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'facility_id': facilityId,
      'blood_type': bloodType,
      'rhesus': rhesus,
      'bags_needed': bagsNeeded,
      'urgency_level': urgencyLevel,
      'latitude_faskes': latitudeFaskes,
      'longitude_faskes': longitudeFaskes,
      'radius_km': radiusKm,
      'notes': notes,
      'hospital_name': hospitalName,
      'status': status,
    };
  }

  /// Backward-compatibility getters
  String get patientName => requesterName ?? 'Pemohon #$requesterId';
  int get bagsCollected => 0;

  /// Display label for blood type + rhesus (e.g. "O+")
  String get bloodLabel => '$bloodType${rhesus == '+' ? '+' : '-'}';

  /// Check if this request is in a "pending" state
  bool get isPending => status == 'menunggu' || status == 'pending';

  /// Formatted time ago string
  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }
}
