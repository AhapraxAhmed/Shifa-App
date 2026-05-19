import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/date_parser.dart';

class MedicationModel {
  final String id;
  final String medicineName;
  final String dosage;
  final String route;
  final String schedule;
  final String notes;
  final String status;
  final String prescribedBy;
  final List<String> administrationTimes;
  final bool isDeleted;
  final DateTime? createdAt;

  const MedicationModel({
    required this.id,
    required this.medicineName,
    required this.dosage,
    this.route = 'Oral',
    required this.schedule,
    required this.notes,
    this.status = 'Active',
    this.prescribedBy = '',
    this.administrationTimes = const [],
    this.isDeleted = false,
    this.createdAt,
  });

  factory MedicationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    
    // Support safe parsing of administration times array
    final timesRaw = d['administrationTimes'];
    List<String> times = [];
    if (timesRaw is List) {
      times = timesRaw.map((e) => e.toString()).toList();
    }

    return MedicationModel(
      id: doc.id,
      medicineName: d['medicineName'] ?? '',
      dosage: d['dosage'] ?? '',
      route: d['route'] ?? 'Oral',
      schedule: d['schedule'] ?? '',
      notes: d['notes'] ?? '',
      status: d['status'] ?? 'Active',
      prescribedBy: d['prescribedBy'] ?? '',
      administrationTimes: times,
      isDeleted: d['isDeleted'] ?? false,
      createdAt: parseDateTime(d['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineName': medicineName,
      'dosage': dosage,
      'route': route,
      'schedule': schedule,
      'notes': notes,
      'status': status,
      'prescribedBy': prescribedBy,
      'administrationTimes': administrationTimes,
      'isDeleted': isDeleted,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
