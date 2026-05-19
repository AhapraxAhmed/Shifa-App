import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/date_parser.dart';

class PatientReportModel {
  final String id;
  final String reportName;
  final String reportType;
  final DateTime? generatedAt;
  final String generatedBy;
  final String reportPeriod;
  final String pdfUrl;
  final String patientId;

  const PatientReportModel({
    required this.id,
    required this.reportName,
    required this.reportType,
    required this.generatedAt,
    required this.generatedBy,
    required this.reportPeriod,
    required this.pdfUrl,
    required this.patientId,
  });

  factory PatientReportModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PatientReportModel(
      id: doc.id,
      reportName: d['reportName'] ?? '',
      reportType: d['reportType'] ?? '',
      generatedAt: parseDateTime(d['generatedAt']),
      generatedBy: d['generatedBy'] ?? '',
      reportPeriod: d['reportPeriod'] ?? '',
      pdfUrl: d['pdfUrl'] ?? '',
      patientId: d['patientId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportName': reportName,
      'reportType': reportType,
      'generatedAt': generatedAt != null ? Timestamp.fromDate(generatedAt!) : FieldValue.serverTimestamp(),
      'generatedBy': generatedBy,
      'reportPeriod': reportPeriod,
      'pdfUrl': pdfUrl,
      'patientId': patientId,
    };
  }
}
