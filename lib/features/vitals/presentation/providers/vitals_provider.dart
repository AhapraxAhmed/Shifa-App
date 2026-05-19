import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/vital_model.dart';

final vitalsStreamProvider = StreamProvider.family<List<VitalModel>, String>((ref, patientId) {
  return FirebaseFirestore.instance
      .collection('patients')
      .doc(patientId)
      .collection('vitals')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(VitalModel.fromFirestore).toList());
});

class VitalsService {
  final _db = FirebaseFirestore.instance;

  Future<void> addVital({
    required String patientId,
    required String bloodPressure,
    required String temperature,
    required String oxygenLevel,
    required String pulseRate,
    required String bloodSugar,
    required String respiratoryRate,
    required String addedBy,
  }) async {
    final batch = _db.batch();
    final vRef = _db.collection('patients').doc(patientId).collection('vitals').doc();
    batch.set(vRef, {
      'bloodPressure': bloodPressure,
      'temperature': temperature,
      'oxygenLevel': oxygenLevel,
      'pulseRate': pulseRate,
      'bloodSugar': bloodSugar,
      'respiratoryRate': respiratoryRate,
      'addedBy': addedBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final hRef = _db.collection('patients').doc(patientId).collection('history').doc();
    batch.set(hRef, {
      'event': 'Vitals recorded — BP: $bloodPressure, Temp: ${temperature}°C, O₂: $oxygenLevel%, Pulse: $pulseRate bpm, Sugar: $bloodSugar mg/dL, Resp: $respiratoryRate bpm',
      'type': 'vitals',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> updateVital({
    required String patientId,
    required String vitalId,
    required String bloodPressure,
    required String temperature,
    required String oxygenLevel,
    required String pulseRate,
    required String bloodSugar,
    required String respiratoryRate,
    required String addedBy,
  }) async {
    final batch = _db.batch();
    final vRef = _db.collection('patients').doc(patientId).collection('vitals').doc(vitalId);
    batch.update(vRef, {
      'bloodPressure': bloodPressure,
      'temperature': temperature,
      'oxygenLevel': oxygenLevel,
      'pulseRate': pulseRate,
      'bloodSugar': bloodSugar,
      'respiratoryRate': respiratoryRate,
      'addedBy': addedBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final hRef = _db.collection('patients').doc(patientId).collection('history').doc();
    batch.set(hRef, {
      'event': 'Vitals updated — BP: $bloodPressure, Temp: ${temperature}°C, O₂: $oxygenLevel%, Pulse: $pulseRate bpm, Sugar: $bloodSugar mg/dL, Resp: $respiratoryRate bpm',
      'type': 'vitals',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> deleteVital({
    required String patientId,
    required String vitalId,
  }) async {
    final batch = _db.batch();
    final vRef = _db.collection('patients').doc(patientId).collection('vitals').doc(vitalId);
    batch.delete(vRef);

    final hRef = _db.collection('patients').doc(patientId).collection('history').doc();
    batch.set(hRef, {
      'event': 'Vitals entry removed',
      'type': 'vitals',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}

final vitalsServiceProvider = Provider<VitalsService>((ref) => VitalsService());
