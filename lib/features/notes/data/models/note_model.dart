import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/date_parser.dart';

class NoteModel {
  final String id;
  final String note;
  final String addedBy;
  final DateTime? createdAt;
  final String? editedBy;
  final bool isEdited;
  final DateTime? updatedAt;

  const NoteModel({
    required this.id,
    required this.note,
    required this.addedBy,
    this.createdAt,
    this.editedBy,
    this.isEdited = false,
    this.updatedAt,
  });

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NoteModel(
      id: doc.id,
      note: d['note'] ?? '',
      addedBy: d['addedBy'] ?? '',
      createdAt: parseDateTime(d['createdAt']),
      editedBy: d['editedBy'],
      isEdited: d['isEdited'] ?? false,
      updatedAt: parseDateTime(d['updatedAt']),
    );
  }
}
