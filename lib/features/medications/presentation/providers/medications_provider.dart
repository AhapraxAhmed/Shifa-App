import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/medication_model.dart';

final medicationsStreamProvider = StreamProvider.family<List<MedicationModel>, String>((ref, patientId) {
  return FirebaseFirestore.instance
      .collection('patients')
      .doc(patientId)
      .collection('medications')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map(MedicationModel.fromFirestore)
          .where((m) => !m.isDeleted)
          .toList());
});

typedef MedicationAdminArg = ({String patientId, String medicationId});

final medicationAdministrationsStreamProvider = StreamProvider.family<List<Map<String, dynamic>>, MedicationAdminArg>((ref, arg) {
  return FirebaseFirestore.instance
      .collection('patients')
      .doc(arg.patientId)
      .collection('medications')
      .doc(arg.medicationId)
      .collection('administrations')
      .orderBy('administeredAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final data = doc.data();
            final timestamp = data['administeredAt'] as Timestamp?;
            return {
              'id': doc.id,
              'administeredBy': data['administeredBy'] ?? 'Unknown Nurse',
              'scheduledTime': data['scheduledTime'] ?? 'N/A',
              'administeredAt': timestamp?.toDate(),
            };
          }).toList());
});

class MedicationsService {
  final _db = FirebaseFirestore.instance;

  Future<void> addMedication({
    required String patientId,
    required String medicineName,
    required String dosage,
    required String route,
    required String schedule,
    required String status,
    required String prescribedBy,
    required List<String> administrationTimes,
    required String notes,
  }) async {
    final batch = _db.batch();
    final mRef = _db.collection('patients').doc(patientId).collection('medications').doc();
    
    batch.set(mRef, {
      'medicineName': medicineName,
      'dosage': dosage,
      'route': route,
      'schedule': schedule,
      'notes': notes,
      'status': status,
      'prescribedBy': prescribedBy,
      'administrationTimes': administrationTimes,
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final hRef = _db.collection('patients').doc(patientId).collection('history').doc();
    batch.set(hRef, {
      'event': 'Medication Added: $medicineName $dosage via $route ($schedule) by $prescribedBy',
      'type': 'medication_added',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> updateMedication({
    required String patientId,
    required String medicationId,
    required String medicineName,
    required String dosage,
    required String route,
    required String schedule,
    required String status,
    required String prescribedBy,
    required List<String> administrationTimes,
    required String notes,
  }) async {
    final batch = _db.batch();
    final mRef = _db.collection('patients').doc(patientId).collection('medications').doc(medicationId);
    
    batch.update(mRef, {
      'medicineName': medicineName,
      'dosage': dosage,
      'route': route,
      'schedule': schedule,
      'notes': notes,
      'status': status,
      'prescribedBy': prescribedBy,
      'administrationTimes': administrationTimes,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final hRef = _db.collection('patients').doc(patientId).collection('history').doc();
    batch.set(hRef, {
      'event': 'Medication Edited: $medicineName $dosage ($schedule, $status) by $prescribedBy',
      'type': 'medication_edited',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> deleteMedication({
    required String patientId,
    required String medicationId,
    required String medicineName,
  }) async {
    final batch = _db.batch();
    final mRef = _db.collection('patients').doc(patientId).collection('medications').doc(medicationId);
    
    batch.update(mRef, {
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });

    final hRef = _db.collection('patients').doc(patientId).collection('history').doc();
    batch.set(hRef, {
      'event': 'Medication Deleted: $medicineName was discontinued',
      'type': 'medication_deleted',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> administerMedication({
    required String patientId,
    required String medicationId,
    required String medicineName,
    required String nurseName,
    required String timeString,
  }) async {
    final batch = _db.batch();
    final aRef = _db
        .collection('patients')
        .doc(patientId)
        .collection('medications')
        .doc(medicationId)
        .collection('administrations')
        .doc();

    batch.set(aRef, {
      'administeredAt': FieldValue.serverTimestamp(),
      'administeredBy': nurseName,
      'scheduledTime': timeString,
    });

    final hRef = _db.collection('patients').doc(patientId).collection('history').doc();
    batch.set(hRef, {
      'event': 'Medication Administered: $medicineName at $timeString by $nurseName',
      'type': 'medication_administered',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}

final medicationsServiceProvider = Provider<MedicationsService>((ref) => MedicationsService());
