import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String patientName;
  final String mrn;
  final String reportType;
  final String generatingStaff;
  final DateTime generatedAt;
  final Map<String, dynamic> data;

  ReportModel({
    required this.id,
    required this.patientName,
    required this.mrn,
    required this.reportType,
    required this.generatingStaff,
    required this.generatedAt,
    required this.data,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      patientName: d['patientName'] ?? '',
      mrn: d['mrn'] ?? '',
      reportType: d['reportType'] ?? 'General',
      generatingStaff: d['generatingStaff'] ?? '',
      generatedAt: (d['generatedAt'] as Timestamp).toDate(),
      data: d['data'] ?? {},
    );
  }
}
