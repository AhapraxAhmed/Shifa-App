import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/date_parser.dart';

class PatientModel {
  final String id;
  final String mrNumber;
  final String patientName;
  final int age;
  final String gender;
  final String nurseName;
  final String address;
  final String diagnosis;
  final String status;
  final bool isShiftActive;
  final DateTime? shiftStartedAt;
  final DateTime? shiftEndedAt;
  final DateTime? createdAt;
  
  // Archive Properties
  final bool isArchived;
  final DateTime? archivedAt;
  final String archivedBy;
  final DateTime? restoredAt;
  final String restoredBy;

  const PatientModel({
    required this.id,
    required this.mrNumber,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.nurseName,
    required this.address,
    required this.diagnosis,
    required this.status,
    this.isShiftActive = false,
    this.shiftStartedAt,
    this.shiftEndedAt,
    this.createdAt,
    this.isArchived = false,
    this.archivedAt,
    this.archivedBy = '',
    this.restoredAt,
    this.restoredBy = '',
  });

  factory PatientModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PatientModel(
      id: doc.id,
      mrNumber: d['mrNumber'] ?? '',
      patientName: d['patientName'] ?? '',
      age: (d['age'] as num?)?.toInt() ?? 0,
      gender: d['gender'] ?? '',
      nurseName: d['nurseName'] ?? '',
      address: d['address'] ?? '',
      diagnosis: d['diagnosis'] ?? '',
      status: d['status'] ?? 'unknown',
      isShiftActive: d['isShiftActive'] ?? false,
      shiftStartedAt: parseDateTime(d['shiftStartedAt']),
      shiftEndedAt: parseDateTime(d['shiftEndedAt']),
      createdAt: parseDateTime(d['createdAt']),
      isArchived: d['isArchived'] ?? false,
      archivedAt: parseDateTime(d['archivedAt']),
      archivedBy: d['archivedBy'] ?? '',
      restoredAt: parseDateTime(d['restoredAt']),
      restoredBy: d['restoredBy'] ?? '',
    );
  }

  factory PatientModel.fromMap(Map<String, dynamic> map, String id) {
    return PatientModel(
      id: id,
      mrNumber: map['mrNumber'] ?? '',
      patientName: map['patientName'] ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      gender: map['gender'] ?? '',
      nurseName: map['nurseName'] ?? '',
      address: map['address'] ?? '',
      diagnosis: map['diagnosis'] ?? '',
      status: map['status'] ?? 'unknown',
      isShiftActive: map['isShiftActive'] ?? false,
      shiftStartedAt: parseDateTime(map['shiftStartedAt']),
      shiftEndedAt: parseDateTime(map['shiftEndedAt']),
      createdAt: parseDateTime(map['createdAt']),
      isArchived: map['isArchived'] ?? false,
      archivedAt: parseDateTime(map['archivedAt']),
      archivedBy: map['archivedBy'] ?? '',
      restoredAt: parseDateTime(map['restoredAt']),
      restoredBy: map['restoredBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mrNumber': mrNumber,
      'patientName': patientName,
      'age': age,
      'gender': gender,
      'nurseName': nurseName,
      'address': address,
      'diagnosis': diagnosis,
      'status': status,
      'isShiftActive': isShiftActive,
      'shiftStartedAt': shiftStartedAt,
      'shiftEndedAt': shiftEndedAt,
      'createdAt': createdAt,
      'isArchived': isArchived,
      'archivedAt': archivedAt,
      'archivedBy': archivedBy,
      'restoredAt': restoredAt,
      'restoredBy': restoredBy,
    };
  }
}
