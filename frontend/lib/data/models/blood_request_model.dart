class BloodRequestModel {
  final int id;
  final int requesterId;
  final String patientName;
  final String hospitalName;
  final String bloodType;
  final String rhesus;
  final int bagsNeeded;
  final int bagsCollected;
  final String urgencyLevel; // 'normal', 'urgent', 'critical'
  final String status; // 'pending', 'in_progress', 'completed', 'cancelled'
  final String? notes;
  final DateTime? createdAt;

  BloodRequestModel({
    required this.id,
    required this.requesterId,
    required this.patientName,
    required this.hospitalName,
    required this.bloodType,
    required this.rhesus,
    required this.bagsNeeded,
    required this.bagsCollected,
    required this.urgencyLevel,
    required this.status,
    this.notes,
    this.createdAt,
  });

  factory BloodRequestModel.fromJson(Map<String, dynamic> json) {
    return BloodRequestModel(
      id: json['id'] as int,
      requesterId: json['requester_id'] as int,
      patientName: json['patient_name'] as String? ?? '',
      hospitalName: json['hospital_name'] as String? ?? '',
      bloodType: json['blood_type'] as String? ?? '',
      rhesus: json['rhesus'] as String? ?? '+',
      bagsNeeded: json['bags_needed'] as int? ?? 1,
      bagsCollected: json['bags_collected'] as int? ?? 0,
      urgencyLevel: json['urgency_level'] as String? ?? 'normal',
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'patient_name': patientName,
      'hospital_name': hospitalName,
      'blood_type': bloodType,
      'rhesus': rhesus,
      'bags_needed': bagsNeeded,
      'bags_collected': bagsCollected,
      'urgency_level': urgencyLevel,
      'status': status,
      'notes': notes,
    };
  }
}
