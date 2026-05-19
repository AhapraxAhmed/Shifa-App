import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/medications_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/medication_model.dart';
import '../../../patients/presentation/providers/patient_provider.dart';

class MedicationDashboard extends ConsumerStatefulWidget {
  final String patientId;
  final bool showAppBar;
  const MedicationDashboard({super.key, required this.patientId, this.showAppBar = true});

  @override
  ConsumerState<MedicationDashboard> createState() => _MedicationDashboardState();
}

class _MedicationDashboardState extends ConsumerState<MedicationDashboard> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _scheduleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _nurseCtrl = TextEditingController();
  final _timesCtrl = TextEditingController();
  
  String _selectedRoute = 'Oral';
  String _selectedStatus = 'Active';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _scheduleCtrl.dispose();
    _notesCtrl.dispose();
    _nurseCtrl.dispose();
    _timesCtrl.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  TimeOfDay _parseTimeOfDay(String string) {
    try {
      final format = DateFormat("hh:mm a");
      final dateTime = format.parse(string);
      return TimeOfDay.fromDateTime(dateTime);
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  void _showAddEditSheet({MedicationModel? med, String? defaultNurse}) {
    final presets = [
      'Once Daily (QD)',
      'Twice Daily (BID)',
      'Three Times Daily (TID)',
      'Four Times Daily (QID)',
      'Every 4 Hours',
      'Every 6 Hours',
      'Every 8 Hours',
      'Every 12 Hours',
      'PRN (As Needed)'
    ];

    List<String> selectedTimes = [];
    String selectedPreset = 'Three Times Daily (TID)';

    if (med != null) {
      _nameCtrl.text = med.medicineName;
      _dosageCtrl.text = med.dosage;
      _selectedRoute = med.route;
      _selectedStatus = med.status;
      _nurseCtrl.text = med.prescribedBy;
      _notesCtrl.text = med.notes;
      selectedTimes = List.from(med.administrationTimes);
      if (presets.contains(med.schedule)) {
        selectedPreset = med.schedule;
        _scheduleCtrl.clear();
      } else {
        selectedPreset = 'Custom';
        _scheduleCtrl.text = med.schedule;
      }
    } else {
      _nameCtrl.clear();
      _dosageCtrl.clear();
      _selectedRoute = 'Oral';
      _selectedStatus = 'Active';
      _nurseCtrl.text = defaultNurse ?? 'Nurse Ahmed';
      _notesCtrl.clear();
      selectedPreset = 'Three Times Daily (TID)';
      selectedTimes = ['09:00 AM', '02:00 PM', '09:00 PM'];
      _scheduleCtrl.clear();
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med != null ? 'Edit Medication Order' : 'Add Medication Order',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Medicine Name',
                      hintText: 'e.g. Paracetamol',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dosageCtrl,
                          decoration: InputDecoration(
                            labelText: 'Dosage',
                            hintText: 'e.g. 500mg',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedRoute,
                          decoration: InputDecoration(
                            labelText: 'Route',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Oral', child: Text('Oral')),
                            DropdownMenuItem(value: 'IV', child: Text('IV')),
                            DropdownMenuItem(value: 'IM', child: Text('IM')),
                            DropdownMenuItem(value: 'SC', child: Text('SC')),
                            DropdownMenuItem(value: 'Topical', child: Text('Topical')),
                            DropdownMenuItem(value: 'Inhalation', child: Text('Inhalation')),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => _selectedRoute = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPreset,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Frequency / Schedule Preset',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Once Daily (QD)', child: Text('Once Daily (QD)')),
                      DropdownMenuItem(value: 'Twice Daily (BID)', child: Text('Twice Daily (BID)')),
                      DropdownMenuItem(value: 'Three Times Daily (TID)', child: Text('Three Times Daily (TID)')),
                      DropdownMenuItem(value: 'Four Times Daily (QID)', child: Text('Four Times Daily (QID)')),
                      DropdownMenuItem(value: 'Every 4 Hours', child: Text('Every 4 Hours')),
                      DropdownMenuItem(value: 'Every 6 Hours', child: Text('Every 6 Hours')),
                      DropdownMenuItem(value: 'Every 8 Hours', child: Text('Every 8 Hours')),
                      DropdownMenuItem(value: 'Every 12 Hours', child: Text('Every 12 Hours')),
                      DropdownMenuItem(value: 'PRN (As Needed)', child: Text('PRN (As Needed)')),
                      DropdownMenuItem(value: 'Custom', child: Text('Custom Preset...')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedPreset = val;
                          if (val == 'Once Daily (QD)') {
                            selectedTimes = ['09:00 AM'];
                          } else if (val == 'Twice Daily (BID)') {
                            selectedTimes = ['09:00 AM', '09:00 PM'];
                          } else if (val == 'Three Times Daily (TID)') {
                            selectedTimes = ['09:00 AM', '02:00 PM', '09:00 PM'];
                          } else if (val == 'Four Times Daily (QID)') {
                            selectedTimes = ['09:00 AM', '01:00 PM', '05:00 PM', '09:00 PM'];
                          } else if (val == 'Every 4 Hours') {
                            selectedTimes = ['08:00 AM', '12:00 PM', '04:00 PM', '08:00 PM', '12:00 AM', '04:00 AM'];
                          } else if (val == 'Every 6 Hours') {
                            selectedTimes = ['06:00 AM', '12:00 PM', '06:00 PM', '12:00 AM'];
                          } else if (val == 'Every 8 Hours') {
                            selectedTimes = ['08:00 AM', '04:00 PM', '12:00 AM'];
                          } else if (val == 'Every 12 Hours') {
                            selectedTimes = ['08:00 AM', '08:00 PM'];
                          } else if (val == 'PRN (As Needed)') {
                            selectedTimes = [];
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Order Status',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(value: 'Suspended', child: Text('Suspended')),
                      DropdownMenuItem(value: 'Discontinued', child: Text('Discontinued')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => _selectedStatus = val);
                    },
                  ),
                  if (selectedPreset == 'Custom') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _scheduleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Custom Frequency Description',
                        hintText: 'e.g. Every alternate day, Mondays only...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Administration Time Slots',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        if (selectedPreset == 'PRN (As Needed)' && selectedTimes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'PRN / As Needed orders do not require fixed schedule times.',
                              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                            ),
                          )
                        else if (selectedTimes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'No scheduled slots. Click "+ Add Slot" below to schedule deliveries.',
                              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                            ),
                          ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...selectedTimes.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final timeStr = entry.value;
                              return InputChip(
                                label: Text(
                                  timeStr,
                                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                backgroundColor: AppColors.primary.withOpacity(0.06),
                                deleteIcon: const Icon(Icons.cancel_rounded, size: 14, color: AppColors.primary),
                                onDeleted: () {
                                  setModalState(() {
                                    selectedTimes.removeAt(idx);
                                  });
                                },
                                onPressed: () async {
                                  final initialTime = _parseTimeOfDay(timeStr);
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: initialTime,
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      selectedTimes[idx] = _formatTimeOfDay(picked);
                                    });
                                  }
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: AppColors.primary.withOpacity(0.15)),
                                ),
                              );
                            }),
                            ActionChip(
                              avatar: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                              label: Text(
                                'Add Slot',
                                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              backgroundColor: AppColors.primary,
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(hour: 9, minute: 0),
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    selectedTimes.add(_formatTimeOfDay(picked));
                                    selectedTimes.sort((a, b) {
                                      final ta = _parseTimeOfDay(a);
                                      final tb = _parseTimeOfDay(b);
                                      return (ta.hour * 60 + ta.minute).compareTo(tb.hour * 60 + tb.minute);
                                    });
                                  });
                                }
                              },
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide.none),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nurseCtrl,
                    decoration: InputDecoration(
                      labelText: 'Attributed Nurse / Clinician',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Special Instructions / Notes',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
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
                              final scheduleVal = selectedPreset == 'Custom' ? _scheduleCtrl.text.trim() : selectedPreset;
                              
                              if (_nameCtrl.text.trim().isEmpty ||
                                  _dosageCtrl.text.trim().isEmpty ||
                                  scheduleVal.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill in medicine name, dosage, and frequency')),
                                );
                                return;
                              }
                              setModalState(() => _saving = true);

                              try {
                                if (med != null) {
                                  await ref.read(medicationsServiceProvider).updateMedication(
                                        patientId: widget.patientId,
                                        medicationId: med.id,
                                        medicineName: _nameCtrl.text.trim(),
                                        dosage: _dosageCtrl.text.trim(),
                                        route: _selectedRoute,
                                        schedule: scheduleVal,
                                        status: _selectedStatus,
                                        prescribedBy: _nurseCtrl.text.trim(),
                                        administrationTimes: selectedTimes,
                                        notes: _notesCtrl.text.trim(),
                                      );
                                } else {
                                  await ref.read(medicationsServiceProvider).addMedication(
                                        patientId: widget.patientId,
                                        medicineName: _nameCtrl.text.trim(),
                                        dosage: _dosageCtrl.text.trim(),
                                        route: _selectedRoute,
                                        schedule: scheduleVal,
                                        status: _selectedStatus,
                                        prescribedBy: _nurseCtrl.text.trim(),
                                        administrationTimes: selectedTimes,
                                        notes: _notesCtrl.text.trim(),
                                      );
                                }
                                if (mounted) Navigator.pop(context);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error saving medication: $e')),
                                  );
                                }
                              } finally {
                                setModalState(() => _saving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              med != null ? 'Update Order' : 'Save Medication Order',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(MedicationModel med) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Discontinue Medication', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently discontinue and remove ${med.medicineName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(medicationsServiceProvider).deleteMedication(
                      patientId: widget.patientId,
                      medicationId: med.id,
                      medicineName: med.medicineName,
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${med.medicineName} has been discontinued.'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error removing medication: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Discontinue', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medsAsync = ref.watch(medicationsStreamProvider(widget.patientId));
    final patientAsync = ref.watch(patientStreamProvider(widget.patientId));

    return Scaffold(
      backgroundColor: widget.showAppBar ? AppColors.background : Colors.transparent,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text('Medications Board', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              backgroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final p = patientAsync.value;
          _showAddEditSheet(defaultNurse: p?.nurseName);
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Prescribe Med', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: medsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (meds) {
          if (meds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No medications recorded for this shift.',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 15),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: meds.length,
            itemBuilder: (_, index) {
              final med = meds[index];
              return _MedicationCard(
                med: med,
                patientId: widget.patientId,
                onEdit: () => _showAddEditSheet(med: med),
                onDelete: () => _confirmDelete(med),
              );
            },
          );
        },
      ),
    );
  }
}

class _MedicationCard extends ConsumerStatefulWidget {
  final MedicationModel med;
  final String patientId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicationCard({
    required this.med,
    required this.patientId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  ConsumerState<_MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends ConsumerState<_MedicationCard> {
  bool _isExpanded = false;

  IconData _getRouteIcon(String route) {
    switch (route.toLowerCase()) {
      case 'iv':
      case 'im':
      case 'sc':
        return Icons.vaccines_rounded;
      case 'topical':
        return Icons.clean_hands_rounded;
      case 'inhalation':
        return Icons.air_rounded;
      default:
        return Icons.medical_services_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'suspended':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showLogAdminDialog(BuildContext context, MedicationModel med) {
    final nurseCtrl = TextEditingController(text: 'Nurse Ahmed');
    String selectedTime = med.administrationTimes.isNotEmpty ? med.administrationTimes[0] : '08:00 AM';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log Med Delivery',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acknowledge delivery of ${med.medicineName} (${med.dosage}) to patient.',
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nurseCtrl,
              decoration: InputDecoration(
                labelText: 'Administered By',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedTime,
              decoration: InputDecoration(
                labelText: 'Scheduled Slot',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: med.administrationTimes
                  .map((time) => DropdownMenuItem(value: time, child: Text(time)))
                  .toList(),
              onChanged: (val) {
                if (val != null) selectedTime = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final nurse = nurseCtrl.text.trim();
              if (nurse.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter nurse name')),
                );
                return;
              }
              Navigator.pop(context);
              try {
                await ref.read(medicationsServiceProvider).administerMedication(
                      patientId: widget.patientId,
                      medicationId: med.id,
                      medicineName: med.medicineName,
                      nurseName: nurse,
                      timeString: selectedTime,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${med.medicineName} administered successfully!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging administration: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Confirm Delivery', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.med.status);
    final arg = (patientId: widget.patientId, medicationId: widget.med.id);
    final administrationsAsync = ref.watch(medicationAdministrationsStreamProvider(arg));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getRouteIcon(widget.med.route), color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.med.medicineName,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.med.status.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.med.dosage}  •  ${widget.med.route}  •  ${widget.med.schedule}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: widget.med.administrationTimes.map((time) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
         
                              ),
                              child: Text(
                                time,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                        onSelected: (val) {
                          if (val == 'edit') {
                            widget.onEdit();
                          } else if (val == 'delete') {
                            widget.onDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit Order')),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Discontinue Order', style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE8EDF2)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Detail Log',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  _detailRow('Prescribed By:', widget.med.prescribedBy),
                  _detailRow('Clinical Notes:', widget.med.notes.isEmpty ? 'No special instructions recorded.' : widget.med.notes),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delivery History Logs',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      TextButton.icon(
                        onPressed: () => _showLogAdminDialog(context, widget.med),
                        icon: const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                        label: Text(
                          'Log Delivery',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.success.withOpacity(0.08),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  administrationsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (e, _) => Text('Error loading history: $e', style: const TextStyle(fontSize: 12, color: AppColors.error)),
                    data: (admins) {
                      if (admins.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'No administrations logged yet for this shift.',
                            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: admins.length,
                        itemBuilder: (context, i) {
                          final ad = admins[i];
                          final formattedTime = ad['administeredAt'] != null
                              ? DateFormat('dd MMM, hh:mm a').format(ad['administeredAt']!)
                              : 'Just Now';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.done_all_rounded, size: 14, color: AppColors.success),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Slot ${ad['scheduledTime']} delivered by ${ad['administeredBy']}',
                                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Text(
                                  formattedTime,
                                  style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}