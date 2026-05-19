import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/history_event_model.dart';

final historyStreamProvider = StreamProvider.family<List<HistoryEventModel>, String>((ref, patientId) {
  return FirebaseFirestore.instance
      .collection('patients')
      .doc(patientId)
      .collection('history')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(HistoryEventModel.fromFirestore).toList());
});
