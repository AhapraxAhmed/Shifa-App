import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/auth/auth_provider.dart';

final patientControllerProvider =
    StateNotifierProvider<PatientController, AsyncValue<void>>((ref) {
  return PatientController(ref);
});

class PatientController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  PatientController(this.ref) : super(const AsyncValue.data(null));

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> checkMrExists(String mrNumber) async {
    final doc = await _firestore.collection('patients').doc(mrNumber).get();
    return doc.exists;
  }

  /// Saves patient with auto-stamped shiftStartedAt and active status.
  Future<String> savePatient({
    required String mrNumber,
    required String patientName,
    required int age,
    required String gender,
    required String nurseName,
    required String address,
    required String diagnosis,
  }) async {
    state = const AsyncValue.loading();
    try {
      if (mrNumber.isEmpty) {
        throw 'MR Number cannot be empty';
      }
      // Check for duplicate MR before proceeding
      final exists = await checkMrExists(mrNumber);
      if (exists) {
        throw 'MR Number already exists';
      }

      final batch = _firestore.batch();
      
      final currentStaffId = ref.read(currentStaffIdProvider);

      final pRef = _firestore.collection('patients').doc(mrNumber);
      final data = {
        'mrNumber': mrNumber,
        'patientName': patientName,
        'age': age,
        'gender': gender,
        'nurseName': nurseName,
        'address': address,
        'diagnosis': diagnosis,
        'status': 'active',
        'isShiftActive': true,
        'shiftStartedAt': FieldValue.serverTimestamp(),
        'shiftEndedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentStaffId,
      };
      batch.set(pRef, data);

      final hRef = pRef.collection('history').doc();
      batch.set(hRef, {
        'event': 'Patient Registered & Shift Started: $patientName',
        'type': 'registration',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      state = const AsyncValue.data(null);
      return mrNumber;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Updates patient general medical details
  Future<void> updatePatient({
    required String patientId,
    required String patientName,
    required int age,
    required String gender,
    required String nurseName,
    required String address,
    required String diagnosis,
    required String status,
  }) async {
    state = const AsyncValue.loading();
    try {
      final batch = _firestore.batch();
      final pRef = _firestore.collection('patients').doc(patientId);

      batch.update(pRef, {
        'patientName': patientName,
        'age': age,
        'gender': gender,
        'nurseName': nurseName,
        'address': address,
        'diagnosis': diagnosis,
        'status': status,
      });

      final hRef = pRef.collection('history').doc();
      batch.set(hRef, {
        'event': 'Patient Information Updated',
        'type': 'update',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Starts a new shift for the patient
  Future<void> startShift(String patientId) async {
    state = const AsyncValue.loading();
    try {
      final batch = _firestore.batch();
      final pRef = _firestore.collection('patients').doc(patientId);
      
      batch.update(pRef, {
        'status': 'active',
        'isShiftActive': true,
        'shiftStartedAt': FieldValue.serverTimestamp(),
        'shiftEndedAt': null,
      });

      final hRef = pRef.collection('history').doc();
      batch.set(hRef, {
        'event': 'Shift Started',
        'type': 'shift_start',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Ends the current shift for the patient
  Future<void> endShift(String patientId) async {
    state = const AsyncValue.loading();
    try {
      final batch = _firestore.batch();
      final pRef = _firestore.collection('patients').doc(patientId);
      
      batch.update(pRef, {
        'status': 'completed',
        'isShiftActive': false,
        'shiftEndedAt': FieldValue.serverTimestamp(),
      });

      final hRef = pRef.collection('history').doc();
      batch.set(hRef, {
        'event': 'Shift Ended',
        'type': 'shift_end',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      
      // Automatically log out staff member and redirect
      await ref.read(authProvider.notifier).logout();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Deletes a patient from Firestore (and subcollections optionally, though firestore console does it, or direct document delete)
  Future<void> deletePatient(String patientId) async {
    state = const AsyncValue.loading();
    try {
      await _firestore.collection('patients').doc(patientId).delete();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Archives a patient's records
  Future<void> archivePatient({required String patientId, required String nurseName}) async {
    state = const AsyncValue.loading();
    try {
      final batch = _firestore.batch();
      final pRef = _firestore.collection('patients').doc(patientId);

      batch.update(pRef, {
        'status': 'archived',
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'archivedBy': nurseName,
      });

      final hRef = pRef.collection('history').doc();
      batch.set(hRef, {
        'event': 'Patient Archived by $nurseName',
        'type': 'archive',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Restores an archived patient
  Future<void> restorePatient({required String patientId, required String nurseName}) async {
    state = const AsyncValue.loading();
    try {
      final batch = _firestore.batch();
      final pRef = _firestore.collection('patients').doc(patientId);

      batch.update(pRef, {
        'status': 'active',
        'isArchived': false,
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredBy': nurseName,
      });

      final hRef = pRef.collection('history').doc();
      batch.set(hRef, {
        'event': 'Patient Restored by $nurseName',
        'type': 'restore',
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