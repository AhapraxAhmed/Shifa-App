import 'package:cloud_firestore/cloud_firestore.dart';

class IoLogModel {
  final String id;
  final String type; // 'intake' | 'output'
  final String category; // 'Water', 'Juice', 'IV Fluids', 'Urine', etc.
  final int amount; // mL
  final String routeOrMethod; // Intake Route (e.g. Oral, IV) or Output Method (e.g. Voided, Catheter)
  final DateTime time;
  final String notes;
  final String recordedBy;

  const IoLogModel({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.routeOrMethod,
    required this.time,
    required this.notes,
    required this.recordedBy,
  });

  factory IoLogModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return IoLogModel(
      id: doc.id,
      type: d['type'] ?? 'intake',
      category: d['category'] ?? '',
      amount: (d['amount'] as num?)?.toInt() ?? 0,
      routeOrMethod: d['routeOrMethod'] ?? d['route'] ?? d['method'] ?? '',
      time: (d['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: d['notes'] ?? '',
      recordedBy: d['recordedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'category': category,
      'amount': amount,
      'routeOrMethod': routeOrMethod,
      'time': Timestamp.fromDate(time),
      'notes': notes,
      'recordedBy': recordedBy,
    };
  }
}
