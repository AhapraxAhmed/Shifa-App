import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../notes/presentation/providers/notes_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/note_model.dart';

class NotesScreen extends ConsumerStatefulWidget {
  final String patientId;
  final bool showAppBar;
  const NotesScreen({super.key, required this.patientId, this.showAppBar = true});
  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _noteCtrl = TextEditingController();
  final _byCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    _byCtrl.dispose();
    super.dispose();
  }

  void _showAddEditSheet({NoteModel? note}) {
    if (note != null) {
      _noteCtrl.text = note.note;
      _byCtrl.text = note.editedBy ?? note.addedBy;
    } else {
      _noteCtrl.clear();
      _byCtrl.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note != null ? 'Edit Clinical Note' : 'Add Clinical Note',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _byCtrl,
                  decoration: InputDecoration(
                    labelText: note != null ? 'Edited By (Clinician)' : 'Added By (Clinician)',
                    hintText: 'Nurse / Doctor name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Clinical Note',
                    hintText: 'Enter complete medical observation note...',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            if (_noteCtrl.text.trim().isEmpty || _byCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill all fields')),
                              );
                              return;
                            }
                            setModalState(() => _saving = true);
                            try {
                              if (note != null) {
                                await ref.read(notesServiceProvider).updateNote(
                                      patientId: widget.patientId,
                                      noteId: note.id,
                                      note: _noteCtrl.text.trim(),
                                      editedBy: _byCtrl.text.trim(),
                                    );
                              } else {
                                await ref.read(notesServiceProvider).addNote(
                                      patientId: widget.patientId,
                                      note: _noteCtrl.text.trim(),
                                      addedBy: _byCtrl.text.trim(),
                                    );
                              }
                              _noteCtrl.clear();
                              _byCtrl.clear();
                              if (mounted) Navigator.pop(context);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error saving note: $e')),
                                );
                              }
                            } finally {
                              setModalState(() => _saving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E24AA)),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            note != null ? 'Save Changes' : 'Save Note',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(NoteModel note) {
    final deletedByCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Clinical Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to permanently delete this clinical note? This action requires clinician attribution.'),
            const SizedBox(height: 12),
            TextField(
              controller: deletedByCtrl,
              decoration: const InputDecoration(
                labelText: 'Clinician Attributing Delete',
                hintText: 'Enter your name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (deletedByCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delete attribution is required.')),
                );
                return;
              }
              final deletedBy = deletedByCtrl.text.trim();
              Navigator.pop(context);
              try {
                await ref.read(notesServiceProvider).deleteNote(
                      patientId: widget.patientId,
                      noteId: note.id,
                      deletedBy: deletedBy,
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note deleted successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting note: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesStreamProvider(widget.patientId));
    return Scaffold(
      backgroundColor: widget.showAppBar ? AppColors.background : Colors.transparent,
      appBar: widget.showAppBar ? AppBar(title: const Text('Notes'), backgroundColor: Colors.white) : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(),
        backgroundColor: const Color(0xFF8E24AA),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No notes added yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: notes.length,
            itemBuilder: (_, i) {
              final n = notes[i];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(color: Color(0x1A8E24AA), shape: BoxShape.circle),
                        child: const Icon(Icons.note_alt_rounded, color: Color(0xFF8E24AA), size: 18),
                      ),
                      if (i < notes.length - 1) Container(width: 2, height: 48, color: const Color(0xFFE8EDF2)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.only(left: 14, top: 12, bottom: 12, right: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8EDF2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(n.addedBy, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF8E24AA))),
                              const Spacer(),
                              if (n.createdAt != null)
                                Text(
                                  DateFormat('dd MMM, hh:mm a').format(n.createdAt!),
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _showAddEditSheet(note: n);
                                  } else if (val == 'delete') {
                                    _confirmDelete(n);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit Note')),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete Note', style: TextStyle(color: AppColors.error),),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(n.note, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
                          if (n.isEdited)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Edited by ${n.editedBy ?? "Clinician"}${n.updatedAt != null ? " on " + DateFormat("dd MMM, hh:mm a").format(n.updatedAt!) : ""}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}