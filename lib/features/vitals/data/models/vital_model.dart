import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/date_parser.dart';

class VitalModel {
  final String id;
  final String bloodPressure;
  final String temperature;
  final String oxygenLevel;
  final String pulseRate;
  final String bloodSugar;
  final String respiratoryRate;
  final String addedBy;
  final DateTime? createdAt;

  const VitalModel({
    required this.id,
    required this.bloodPressure,
    required this.temperature,
    required this.oxygenLevel,
    required this.pulseRate,
    required this.bloodSugar,
    required this.respiratoryRate,
    required this.addedBy,
    this.createdAt,
  });

  factory VitalModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VitalModel(
      id: doc.id,
      bloodPressure: d['bloodPressure'] ?? '',
      temperature: d['temperature'] ?? '',
      oxygenLevel: d['oxygenLevel'] ?? '',
      pulseRate: d['pulseRate'] ?? '',
      bloodSugar: d['bloodSugar'] ?? '',
      respiratoryRate: d['respiratoryRate'] ?? '',
      addedBy: d['addedBy'] ?? '',
      createdAt: parseDateTime(d['createdAt']),
    );
  }
}
