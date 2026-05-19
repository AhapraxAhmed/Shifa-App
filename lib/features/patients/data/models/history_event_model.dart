import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/date_parser.dart';

class HistoryEventModel {
  final String id;
  final String event;
  final String type;
  final DateTime? createdAt;

  const HistoryEventModel({
    required this.id,
    required this.event,
    required this.type,
    this.createdAt,
  });

  factory HistoryEventModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return HistoryEventModel(
      id: doc.id,
      event: d['event'] ?? '',
      type: d['type'] ?? 'general',
      createdAt: parseDateTime(d['createdAt']),
    );
  }
}
