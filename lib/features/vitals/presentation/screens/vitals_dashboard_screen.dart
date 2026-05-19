import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/vitals_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/vital_model.dart';

class VitalsScreen extends ConsumerStatefulWidget {
  final String patientId;
  final bool showAppBar;
  const VitalsScreen({super.key, required this.patientId, this.showAppBar = true});

  @override
  ConsumerState<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends ConsumerState<VitalsScreen> {
  final _bpCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _o2Ctrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _sugarCtrl = TextEditingController();
  final _respCtrl = TextEditingController();
  final _addedByCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _bpCtrl.dispose();
    _tempCtrl.dispose();
    _o2Ctrl.dispose();
    _pulseCtrl.dispose();
    _sugarCtrl.dispose();
    _respCtrl.dispose();
    _addedByCtrl.dispose();
    super.dispose();
  }

  void _showAddSheet({VitalModel? vital}) {
    if (vital != null) {
      _bpCtrl.text = vital.bloodPressure;
      _tempCtrl.text = vital.temperature;
      _o2Ctrl.text = vital.oxygenLevel;
      _pulseCtrl.text = vital.pulseRate;
      _sugarCtrl.text = vital.bloodSugar;
      _respCtrl.text = vital.respiratoryRate;
      _addedByCtrl.text = vital.addedBy;
    } else {
      _bpCtrl.clear();
      _tempCtrl.clear();
      _o2Ctrl.clear();
      _pulseCtrl.clear();
      _sugarCtrl.clear();
      _respCtrl.clear();
      _addedByCtrl.clear();
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
                  vital != null ? 'Edit Vitals Reading' : 'Add Vitals',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _field(_bpCtrl, 'Blood Pressure', 'e.g. 120/80')),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_tempCtrl, 'Temperature (°C)', 'e.g. 37.2')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(_o2Ctrl, 'Oxygen Level (%)', 'e.g. 98')),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_pulseCtrl, 'Pulse Rate (bpm)', 'e.g. 72')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(_sugarCtrl, 'Blood Sugar (mg/dL)', 'e.g. 110')),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_respCtrl, 'Respiratory Rate', 'e.g. 18')),
                  ],
                ),
                const SizedBox(height: 12),
                _field(_addedByCtrl, 'Recorded By', 'Nurse / Doctor name'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            if (_bpCtrl.text.isEmpty ||
                                _tempCtrl.text.isEmpty ||
                                _o2Ctrl.text.isEmpty ||
                                _pulseCtrl.text.isEmpty ||
                                _sugarCtrl.text.isEmpty ||
                                _respCtrl.text.isEmpty ||
                                _addedByCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill all fields')),
                              );
                              return;
                            }
                            setModalState(() => _saving = true);
                            try {
                              if (vital != null) {
                                await ref.read(vitalsServiceProvider).updateVital(
                                      patientId: widget.patientId,
                                      vitalId: vital.id,
                                      bloodPressure: _bpCtrl.text.trim(),
                                      temperature: _tempCtrl.text.trim(),
                                      oxygenLevel: _o2Ctrl.text.trim(),
                                      pulseRate: _pulseCtrl.text.trim(),
                                      bloodSugar: _sugarCtrl.text.trim(),
                                      respiratoryRate: _respCtrl.text.trim(),
                                      addedBy: _addedByCtrl.text.trim(),
                                    );
                              } else {
                                await ref.read(vitalsServiceProvider).addVital(
                                      patientId: widget.patientId,
                                      bloodPressure: _bpCtrl.text.trim(),
                                      temperature: _tempCtrl.text.trim(),
                                      oxygenLevel: _o2Ctrl.text.trim(),
                                      pulseRate: _pulseCtrl.text.trim(),
                                      bloodSugar: _sugarCtrl.text.trim(),
                                      respiratoryRate: _respCtrl.text.trim(),
                                      addedBy: _addedByCtrl.text.trim(),
                                    );
                              }
                              _bpCtrl.clear();
                              _tempCtrl.clear();
                              _o2Ctrl.clear();
                              _pulseCtrl.clear();
                              _sugarCtrl.clear();
                              _respCtrl.clear();
                              _addedByCtrl.clear();
                              if (mounted) Navigator.pop(context);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error saving: $e')),
                                );
                              }
                            } finally {
                              setModalState(() => _saving = false);
                            }
                          },
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            vital != null ? 'Save Changes' : 'Save Vitals',
                            style: const TextStyle(fontWeight: FontWeight.w700),
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

  void _confirmDelete(VitalModel vital) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vitals Reading'),
        content: const Text('Are you sure you want to permanently delete this vitals entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(vitalsServiceProvider).deleteVital(
                      patientId: widget.patientId,
                      vitalId: vital.id,
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vitals entry deleted successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting vitals: $e'),
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

  Widget _field(TextEditingController c, String label, String hint) {
    return TextField(controller: c, decoration: InputDecoration(labelText: label, hintText: hint));
  }

  @override
  Widget build(BuildContext context) {
    final vitalsAsync = ref.watch(vitalsStreamProvider(widget.patientId));
    return Scaffold(
      backgroundColor: widget.showAppBar ? AppColors.background : Colors.transparent,
      appBar: widget.showAppBar ? AppBar(title: const Text('Vitals'), backgroundColor: Colors.white) : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Vitals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: vitalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (vitals) {
          if (vitals.isEmpty) return _emptyState();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vitals.length,
            itemBuilder: (_, i) => _vitalCard(vitals[i]),
          );
        },
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monitor_heart_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No vitals recorded yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Tap + Add Vitals to begin', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );

  Widget _vitalCard(VitalModel vital) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Recorded by: ${vital.addedBy}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (vital.createdAt != null)
                Text(
                  DateFormat('dd MMM, hh:mm a').format(vital.createdAt!),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showAddSheet(vital: vital);
                  } else if (val == 'delete') {
                    _confirmDelete(vital);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Reading')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Entry', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _vitalChip('BP', vital.bloodPressure, const Color(0xFF1E88E5)),
              const SizedBox(width: 8),
              _vitalChip('Temp', '${vital.temperature}°C', const Color(0xFFEF6C00)),
              const SizedBox(width: 8),
              _vitalChip('O₂', '${vital.oxygenLevel}%', const Color(0xFF43A047)),
              const SizedBox(width: 8),
              _vitalChip('Pulse', '${vital.pulseRate}bpm', const Color(0xFF8E24AA)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _vitalChip('Sugar', '${vital.bloodSugar}mg/dL', const Color(0xFFD32F2F)),
              const SizedBox(width: 8),
              _vitalChip('Resp', '${vital.respiratoryRate} bpm', const Color(0xFF455A64)),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vitalChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}