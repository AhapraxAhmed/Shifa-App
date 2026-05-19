import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/io_log_model.dart';
import '../../../../core/auth/auth_provider.dart';

final ioLogsStreamProvider = StreamProvider.family<List<IoLogModel>, String>((ref, patientId) {
  return FirebaseFirestore.instance
      .collection('patients')
      .doc(patientId)
      .collection('io_logs')
      .orderBy('time', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => IoLogModel.fromFirestore(doc)).toList());
});

class IoLogsController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  IoLogsController(this.ref) : super(const AsyncValue.data(null));

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addLog({
    required String patientId,
    required String type,
    required String category,
    required int amount,
    required String routeOrMethod,
    required DateTime time,
    required String notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final staffId = ref.read(currentStaffIdProvider);
      final batch = _db.batch();
      
      final logRef = _db.collection('patients').doc(patientId).collection('io_logs').doc();
      final logData = {
        'type': type,
        'category': category,
        'amount': amount,
        'routeOrMethod': routeOrMethod,
        'time': Timestamp.fromDate(time),
        'notes': notes,
        'recordedBy': staffId,
      };
      batch.set(logRef, logData);

      // Add to patient activity history as well
      final hRef = _db.collection('patients').doc(patientId).collection('history').doc();
      batch.set(hRef, {
        'event': 'Logged ${type.toUpperCase()}: $category (${amount}mL) by $staffId',
        'type': 'io_log',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateLog({
    required String patientId,
    required String logId,
    required String type,
    required String category,
    required int amount,
    required String routeOrMethod,
    required DateTime time,
    required String notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final staffId = ref.read(currentStaffIdProvider);
      final batch = _db.batch();

      final logRef = _db.collection('patients').doc(patientId).collection('io_logs').doc(logId);
      batch.update(logRef, {
        'type': type,
        'category': category,
        'amount': amount,
        'routeOrMethod': routeOrMethod,
        'time': Timestamp.fromDate(time),
        'notes': notes,
        'recordedBy': staffId,
      });

      final hRef = _db.collection('patients').doc(patientId).collection('history').doc();
      batch.set(hRef, {
        'event': 'Updated ${type.toUpperCase()}: $category (${amount}mL) by $staffId',
        'type': 'io_log_update',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteLog({
    required String patientId,
    required String logId,
    required String type,
    required String category,
    required int amount,
  }) async {
    state = const AsyncValue.loading();
    try {
      final staffId = ref.read(currentStaffIdProvider);
      final batch = _db.batch();

      final logRef = _db.collection('patients').doc(patientId).collection('io_logs').doc(logId);
      batch.delete(logRef);

      final hRef = _db.collection('patients').doc(patientId).collection('history').doc();
      batch.set(hRef, {
        'event': 'Deleted ${type.toUpperCase()} Log: $category (${amount}mL) by $staffId',
        'type': 'io_log_delete',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final ioLogsControllerProvider = StateNotifierProvider<IoLogsController, AsyncValue<void>>((ref) {
  return IoLogsController(ref);
});
