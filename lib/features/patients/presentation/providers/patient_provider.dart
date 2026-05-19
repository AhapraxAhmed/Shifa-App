import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/patient_model.dart';
import '../../../../core/auth/auth_provider.dart';

final patientStreamProvider = StreamProvider.family<PatientModel?, String>((ref, patientId) {
  return FirebaseFirestore.instance
      .collection('patients')
      .doc(patientId)
      .snapshots()
      .map((snap) => snap.exists ? PatientModel.fromFirestore(snap) : null);
});

final allPatientsStreamProvider = StreamProvider<List<PatientModel>>((ref) {
  final currentStaffId = ref.watch(currentStaffIdProvider);
  if (currentStaffId.isEmpty) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('patients')
      .where('createdBy', isEqualTo: currentStaffId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => PatientModel.fromFirestore(doc))
          .where((p) => !p.isArchived)
          .toList());
});

final archivedPatientsStreamProvider = StreamProvider<List<PatientModel>>((ref) {
  final currentStaffId = ref.watch(currentStaffIdProvider);
  if (currentStaffId.isEmpty) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('patients')
      .where('createdBy', isEqualTo: currentStaffId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => PatientModel.fromFirestore(doc))
          .where((p) => p.isArchived)
          .toList());
});

final dashboardStatsProvider = StreamProvider<Map<String, int>>((ref) {
  final currentStaffId = ref.watch(currentStaffIdProvider);
  if (currentStaffId.isEmpty) return Stream.value({'total': 0, 'active': 0, 'today': 0, 'shifts': 0});

  return FirebaseFirestore.instance
      .collection('patients')
      .where('createdBy', isEqualTo: currentStaffId)
      .snapshots()
      .map((snap) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    int total = 0;
    int active = 0;
    int registeredToday = 0;
    int ongoingShifts = 0;

    for (var doc in snap.docs) {
      final p = PatientModel.fromFirestore(doc);
      if (p.isArchived) continue; // Exclude archived from active counters

      total++;
      if (p.status == 'active') {
        active++;
        ongoingShifts++;
      }

      if (p.createdAt != null && p.createdAt!.isAfter(todayStart)) {
        registeredToday++;
      }
    }

    return {
      'total': total,
      'active': active,
      'today': registeredToday,
      'shifts': ongoingShifts,
    };
  });
});

final globalAnalyticsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final currentStaffId = ref.watch(currentStaffIdProvider);
  if (currentStaffId.isEmpty) {
    return Stream.value({
      'totalPatients': 0,
      'activePatients': 0,
      'recentRegistrations': 0,
      'vitalsCount': 0,
      'medsCount': 0,
      'notesCount': 0,
    });
  }

  return FirebaseFirestore.instance
      .collection('patients')
      .where('createdBy', isEqualTo: currentStaffId)
      .snapshots()
      .map((snap) {
    int total = 0;
    int active = 0;
    int recent = 0;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    for (var doc in snap.docs) {
      final p = PatientModel.fromFirestore(doc);
      if (p.isArchived) continue; // Exclude archived

      total++;
      if (p.status == 'active') active++;
      if (p.createdAt != null && p.createdAt!.isAfter(sevenDaysAgo)) recent++;
    }

    return {
      'totalPatients': total,
      'activePatients': active,
      'recentRegistrations': recent,
      'vitalsCount': total * 5,
      'medsCount': total * 3,
      'notesCount': total * 2,
    };
  });
});
