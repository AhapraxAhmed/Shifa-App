import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/io_logs_provider.dart';
import '../../data/models/io_log_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/patient_provider.dart';

class IoLogsScreen extends ConsumerStatefulWidget {
  final String patientId;
  final bool showAppBar;
  
  const IoLogsScreen({
    super.key,
    required this.patientId,
    this.showAppBar = true,
  });

  @override
  ConsumerState<IoLogsScreen> createState() => _IoLogsScreenState();
}

class _IoLogsScreenState extends ConsumerState<IoLogsScreen> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  
  String _selectedType = 'intake'; // 'intake' | 'output'
  String _selectedCategory = 'Water';
  String _selectedRouteOrMethod = 'Oral'; // Route for intake, Method for output
  DateTime _selectedTime = DateTime.now();
  bool _saving = false;

  final List<String> _intakeCategories = ['Water', 'Juice', 'IV Fluids', 'Soup', 'Tea/Coffee', 'Milk', 'Other Intake'];
  final List<String> _intakeRoutes = ['Oral', 'IV', 'Nasogastric Tube (NGT)', 'PEG Tube'];

  final List<String> _outputCategories = ['Urine', 'Vomit', 'Drainage', 'Catheter Output', 'Diarrhea', 'Other Output'];
  final List<String> _outputMethods = ['Voided', 'Foley Catheter', 'Drainage Bag', 'Emesis Basin', 'Ostomy'];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _showAddEditSheet({IoLogModel? log}) {
    if (log != null) {
      _selectedType = log.type;
      _selectedCategory = log.category;
      _selectedRouteOrMethod = log.routeOrMethod;
      _amountCtrl.text = log.amount.toString();
      _notesCtrl.text = log.notes;
      _selectedTime = log.time;
    } else {
      _selectedType = 'intake';
      _selectedCategory = 'Water';
      _selectedRouteOrMethod = 'Oral';
      _amountCtrl.clear();
      _notesCtrl.clear();
      _selectedTime = DateTime.now();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          final isIntake = _selectedType == 'intake';
          final categories = isIntake ? _intakeCategories : _outputCategories;
          final routesOrMethods = isIntake ? _intakeRoutes : _outputMethods;

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    log != null ? 'Edit I/O Log Entry' : 'Add New I/O Log Entry',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 20),
                  
                  // Intake / Output Switcher
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              _selectedType = 'intake';
                              _selectedCategory = _intakeCategories.first;
                              _selectedRouteOrMethod = _intakeRoutes.first;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isIntake ? AppColors.success.withOpacity(0.12) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isIntake ? AppColors.success : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_hospital_rounded, color: isIntake ? AppColors.success : Colors.grey[600], size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Intake (In)',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: isIntake ? AppColors.success : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              _selectedType = 'output';
                              _selectedCategory = _outputCategories.first;
                              _selectedRouteOrMethod = _outputMethods.first;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isIntake ? AppColors.error.withOpacity(0.12) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: !isIntake ? AppColors.error : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.opacity_rounded, color: !isIntake ? AppColors.error : Colors.grey[600], size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Output (Out)',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      color: !isIntake ? AppColors.error : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: categories.contains(_selectedCategory) ? _selectedCategory : categories.first,
                    decoration: InputDecoration(
                      labelText: isIntake ? 'Intake Type / Category' : 'Output Type / Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    items: categories
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amount (mL)
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Amount (mL)',
                      hintText: 'e.g. 250',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.water_drop_outlined),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Route or Method Dropdown
                  DropdownButtonFormField<String>(
                    value: routesOrMethods.contains(_selectedRouteOrMethod) ? _selectedRouteOrMethod : routesOrMethods.first,
                    decoration: InputDecoration(
                      labelText: isIntake ? 'Route / Administration' : 'Method / Device',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    items: routesOrMethods
                        .map((rm) => DropdownMenuItem(value: rm, child: Text(rm)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => _selectedRouteOrMethod = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Time Selection Button
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedTime,
                        firstDate: DateTime.now().subtract(const Duration(days: 7)),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (pickedDate != null) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_selectedTime),
                        );
                        if (pickedTime != null) {
                          setModalState(() {
                            _selectedTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF8FAFC),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'Time recorded:',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                          Text(
                            DateFormat('hh:mm a, MMM dd').format(_selectedTime),
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Clinical Notes / Instructions',
                      hintText: 'e.g. Tolerated well, taken after breakfast...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              final amt = int.tryParse(_amountCtrl.text.trim()) ?? 0;
                              if (amt <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a valid amount in mL')),
                                );
                                return;
                              }
                              setModalState(() => _saving = true);

                              try {
                                if (log != null) {
                                  await ref.read(ioLogsControllerProvider.notifier).updateLog(
                                        patientId: widget.patientId,
                                        logId: log.id,
                                        type: _selectedType,
                                        category: _selectedCategory,
                                        amount: amt,
                                        routeOrMethod: _selectedRouteOrMethod,
                                        time: _selectedTime,
                                        notes: _notesCtrl.text.trim(),
                                      );
                                } else {
                                  await ref.read(ioLogsControllerProvider.notifier).addLog(
                                        patientId: widget.patientId,
                                        type: _selectedType,
                                        category: _selectedCategory,
                                        amount: amt,
                                        routeOrMethod: _selectedRouteOrMethod,
                                        time: _selectedTime,
                                        notes: _notesCtrl.text.trim(),
                                      );
                                }
                                if (mounted) Navigator.pop(context);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error saving log: $e')),
                                  );
                                }
                              } finally {
                                setModalState(() => _saving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isIntake ? AppColors.success : AppColors.error,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              log != null ? 'Update Log' : 'Record I/O Log',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
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

  void _confirmDelete(IoLogModel log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete I/O Log', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete this ${log.type} entry of ${log.amount}mL (${log.category})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(ioLogsControllerProvider.notifier).deleteLog(
                      patientId: widget.patientId,
                      logId: log.id,
                      type: log.type,
                      category: log.category,
                      amount: log.amount,
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('I/O Log deleted successfully.'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ioLogsAsync = ref.watch(ioLogsStreamProvider(widget.patientId));
    final patientAsync = ref.watch(patientStreamProvider(widget.patientId));

    return Scaffold(
      backgroundColor: widget.showAppBar ? AppColors.background : Colors.transparent,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text('Intake & Output Monitor', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Log Intake / Output', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ioLogsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          // Calculations
          int totalIntake = 0;
          int totalOutput = 0;
          for (var log in logs) {
            if (log.type == 'intake') {
              totalIntake += log.amount;
            } else {
              totalOutput += log.amount;
            }
          }
          final balance = totalIntake - totalOutput;
          final isStable = balance >= 0;

          return Column(
            children: [
              // Header Summary Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                  border: Border.all(color: const Color(0xFFE8EDF2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCalculationColumn('Total Intake', '$totalIntake mL', AppColors.success, Icons.arrow_downward_rounded),
                        Container(width: 1, height: 40, color: Colors.grey[200]),
                        _buildCalculationColumn('Total Output', '$totalOutput mL', AppColors.error, Icons.arrow_upward_rounded),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fluid Balance:',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (isStable ? AppColors.success : AppColors.error).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${balance >= 0 ? '+' : ''}$balance mL',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: isStable ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Title and Feed
              Expanded(
                child: logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.opacity_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No I/O logs for this shift yet.',
                              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final isIntake = log.type == 'intake';
                          final color = isIntake ? AppColors.success : AppColors.error;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE8EDF2)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: color.withOpacity(0.12),
                                  child: Icon(
                                    isIntake ? Icons.local_hospital_rounded : Icons.opacity_rounded,
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            log.category,
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 15),
                                          ),
                                          Text(
                                            '${isIntake ? '+' : '-'}${log.amount} mL',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w900,
                                              color: color,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${isIntake ? 'Route' : 'Method'}: ${log.routeOrMethod}',
                                            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            DateFormat('hh:mm a').format(log.time),
                                            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      if (log.notes.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            log.notes,
                                            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textPrimary, fontStyle: FontStyle.italic),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      _showAddEditSheet(log: log);
                                    } else if (val == 'delete') {
                                      _confirmDelete(log);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalculationColumn(String title, String value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }
}
