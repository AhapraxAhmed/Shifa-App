import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/note_model.dart';

final notesStreamProvider = StreamProvider.family<List<NoteModel>, String>((ref, patientId) {
  return FirebaseFirestore.instance
      .collection('patients')
      .doc(patientId)
      .collection('notes')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(NoteModel.fromFirestore).toList());
});

class NotesService {
  final _db = FirebaseFirestore.instance;

  Future<void> addNote({
    required String patientId,
    required String note,
    required String addedBy,
  }) async {
    final batch = _db.batch();
    final nRef = _db.collection('patients').doc(patientId).collection('notes').doc();
    batch.set(nRef, {
      'note': note,
      'addedBy': addedBy,
      'isEdited': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    final hRef = _db.collection('patients').doc(patientId).collection('history').doc();
    batch.set(hRef, {
      'event': 'Note added by $addedBy',
      'type': 'note',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> updateNote({
    required String patientId,
    required String noteId,
    required String note,
    required String editedBy,
  }) async {
    final batch = _db.batch();
    final nRef = _db.collection('patients').doc(patientId).collection('notes').doc(noteId);
    batch.update(nRef, {
      'note': note,
      'editedBy': editedBy,
      'isEdited': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    final hRef = _db.collection('patients').doc(patientId).collection('history').doc();
    batch.set(hRef, {
      'event': 'Note edited by $editedBy',
      'type': 'note',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> deleteNote({
    required String patientId,
    required String noteId,
    required String deletedBy,
  }) async {
    final batch = _db.batch();
    final nRef = _db.collection('patients').doc(patientId).collection('notes').doc(noteId);
    batch.delete(nRef);

    final hRef = _db.collection('patients').doc(patientId).collection('history').doc();
    batch.set(hRef, {
      'event': 'Note deleted by $deletedBy',
      'type': 'note',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}

final notesServiceProvider = Provider<NotesService>((ref) => NotesService());
