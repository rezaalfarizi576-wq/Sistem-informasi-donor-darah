class DispatchTicketModel {
  final String ticketCode;
  final String dispatchId;
  final int requestId;
  final int donorId;
  final String patientName;
  final String hospitalName;
  final String bloodType;
  final String rhesus;
  final int bagsNeeded;
  final String urgencyLevel;
  final String notes;
  final double hospitalLat;
  final double hospitalLng;
  final String status;
  final DateTime? waktuRespon;

  DispatchTicketModel({
    required this.ticketCode,
    required this.dispatchId,
    required this.requestId,
    required this.donorId,
    required this.patientName,
    required this.hospitalName,
    required this.bloodType,
    required this.rhesus,
    required this.bagsNeeded,
    required this.urgencyLevel,
    required this.notes,
    required this.hospitalLat,
    required this.hospitalLng,
    this.status = 'diterima',
    this.waktuRespon,
  });

  factory DispatchTicketModel.fromJson(Map<String, dynamic> json) {
    return DispatchTicketModel(
      ticketCode: json['ticket_code'] ?? 'TGP-2026-0001',
      dispatchId: json['dispatch_id'] ?? '#DSP-2026-0001',
      requestId: json['request_id'] is int
          ? json['request_id']
          : int.tryParse(json['request_id']?.toString() ?? '1') ?? 1,
      donorId: json['donor_id'] is int
          ? json['donor_id']
          : int.tryParse(json['donor_id']?.toString() ?? '1') ?? 1,
      patientName: json['patient_name'] ?? 'Pasien IGD Darurat',
      hospitalName: json['hospital_name'] ?? 'RSUD Dr. Soegiri Lamongan',
      bloodType: json['blood_type'] ?? 'O',
      rhesus: json['rhesus'] ?? '+',
      bagsNeeded: json['bags_needed'] ?? 1,
      urgencyLevel: json['urgency_level'] ?? 'kritis',
      notes: json['notes'] ?? 'Donor Darurat Fast-Track',
      hospitalLat: (json['hospital_lat'] as num?)?.toDouble() ?? -7.119812,
      hospitalLng: (json['hospital_lng'] as num?)?.toDouble() ?? 112.415155,
      status: json['status'] ?? 'diterima',
      waktuRespon: json['waktu_respon'] != null
          ? DateTime.tryParse(json['waktu_respon'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'ticket_code': ticketCode,
        'dispatch_id': dispatchId,
        'request_id': requestId,
        'donor_id': donorId,
        'patient_name': patientName,
        'hospital_name': hospitalName,
        'blood_type': bloodType,
        'rhesus': rhesus,
        'bags_needed': bagsNeeded,
        'urgency_level': urgencyLevel,
        'notes': notes,
        'hospital_lat': hospitalLat,
        'hospital_lng': hospitalLng,
        'status': status,
        'waktu_respon': waktuRespon?.toIso8601String(),
      };

  /// Data teks yang dikodekan ke dalam QR Code untuk dipindai scanner RSUD / IGD
  String get qrData =>
      'DONOR_FASTTRACK|TICKET:$ticketCode|REQ:$requestId|DONOR:$donorId|BLOOD:$bloodType$rhesus|HOSPITAL:$hospitalName';
}
