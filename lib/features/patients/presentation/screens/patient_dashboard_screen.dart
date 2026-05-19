import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/patient_provider.dart';
import '../providers/patient_controller.dart';
import '../providers/history_provider.dart';
import '../../../vitals/presentation/providers/vitals_provider.dart';
import '../../../vitals/presentation/screens/vitals_dashboard_screen.dart';
import '../../../medications/presentation/providers/medications_provider.dart';
import '../../../medications/presentation/screens/medication_dashboard.dart';
import '../../../notes/presentation/providers/notes_provider.dart';
import '../../../notes/presentation/screens/notes_screen.dart';
import '../../../reports/presentation/screens/reports_dashboard.dart';
import '../screens/history_screen.dart';
import '../screens/io_logs_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/vitals_grid.dart';
import '../widgets/activity_timeline.dart';
import '../../data/models/patient_model.dart';

class PatientDashboardScreen extends ConsumerStatefulWidget {
  final String patientId;
  const PatientDashboardScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends ConsumerState<PatientDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _bottomNavIndex = _mapTabToBottomNav(_tabController.index);
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _mapTabToBottomNav(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 0; // STATUS
      case 1:
        return 1; // VITALS
      case 2:
        return 2; // MEDS
      case 4:
        return 3; // NOTES
      case 6:
        return 4; // ARCHIVES
      default:
        return _bottomNavIndex ?? 0;
    }
  }

  int _mapBottomNavToTab(int navIndex) {
    switch (navIndex) {
      case 0:
        return 0; // STATUS
      case 1:
        return 1; // VITALS
      case 2:
        return 2; // MEDS
      case 3:
        return 4; // NOTES
      case 4:
        return 6; // ARCHIVES
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientAsync = ref.watch(patientStreamProvider(widget.patientId));

    return patientAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (patient) {
        if (patient == null) return const Scaffold(body: Center(child: Text('Patient not found')));

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _buildPremiumHeader(context, patient),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                width: double.infinity,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                  unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Vitals'),
                    Tab(text: 'Medications'),
                    Tab(text: 'I/O Logs'),
                    Tab(text: 'Notes'),
                    Tab(text: 'Reports'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(patientId: widget.patientId),
                    VitalsScreen(patientId: widget.patientId, showAppBar: false),
                    MedicationDashboard(patientId: widget.patientId, showAppBar: false),
                    IoLogsScreen(patientId: widget.patientId, showAppBar: false),
                    NotesScreen(patientId: widget.patientId, showAppBar: false),
                    ReportsDashboard(patientId: widget.patientId, showAppBar: false),
                    HistoryScreen(patientId: widget.patientId, showAppBar: false),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _DashboardBottomNavBar(
            selectedIndex: _bottomNavIndex ?? 0,
            onTap: (index) {
              setState(() {
                _bottomNavIndex = index;
                _tabController.animateTo(_mapBottomNavToTab(index));
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildPremiumHeader(BuildContext context, PatientModel patient) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1565C0),
            Color(0xFF1E88E5),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Action Row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => context.go('/home'),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      patient.patientName,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _AppBarAction(
                    icon: Icons.edit_note_rounded,
                    onTap: () => context.push('/edit_patient/${patient.id}'),
                  ),
                  _AppBarAction(
                    icon: Icons.notifications_active_rounded,
                    onTap: () => _showClinicalAlertsBottomSheet(context, patient),
                  ),
                  _buildMoreMenu(context, patient),
                ],
              ),
              const SizedBox(height: 12),
              // Patient Details Container Card
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/shifa_logo.jpeg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                patient.patientName,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _MiniStatusBadge(status: patient.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'MRN: ${patient.mrNumber}  •  ${patient.age}Y  •  ${patient.gender}',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.medical_services_rounded,
                              color: Colors.white,
                              size: 11,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Primary Dx: ${patient.diagnosis.isNotEmpty ? patient.diagnosis : 'None'}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildMoreMenu(BuildContext context, PatientModel patient) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
      onSelected: (val) {
        if (val == 'end_shift') {
          _confirmEndShift(context, patient);
        } else if (val == 'start_shift') {
          _confirmStartShift(context, patient);
        } else if (val == 'archive') {
          _archiveRecords(context, patient);
        } else if (val == 'export') {
          context.push('/report_preview/${patient.id}');
        } else if (val == 'delete') {
          _confirmDeletePatient(context, patient);
        }
      },
      itemBuilder: (context) => [
        if (patient.isShiftActive)
          const PopupMenuItem(value: 'end_shift', child: Text('End Active Shift'))
        else
          const PopupMenuItem(value: 'start_shift', child: Text('Start New Shift')),
        const PopupMenuItem(value: 'archive', child: Text('Archive Records')),
        const PopupMenuItem(value: 'export', child: Text('Export PDF Report')),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete Patient Profile', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }

  void _showClinicalAlertsBottomSheet(BuildContext context, PatientModel patient) {
    final vitals = ref.read(vitalsStreamProvider(patient.id)).value ?? [];
    final history = ref.read(historyStreamProvider(patient.id)).value ?? [];

    final alerts = <String>[];
    if (vitals.isNotEmpty) {
      final latest = vitals.first;
      
      // Parse BP
      final bpParts = latest.bloodPressure.split('/');
      if (bpParts.length == 2) {
        final sys = int.tryParse(bpParts[0].trim());
        final dia = int.tryParse(bpParts[1].trim());
        if (sys != null && (sys > 140 || sys < 90)) {
          alerts.add('Abnormal Blood Pressure (Systolic: $sys mmHg)');
        }
        if (dia != null && (dia > 90 || dia < 60)) {
          alerts.add('Abnormal Blood Pressure (Diastolic: $dia mmHg)');
        }
      }

      // Parse Temp
      final temp = double.tryParse(latest.temperature.trim());
      if (temp != null) {
        if (temp > 38.0) {
          alerts.add('High Body Temperature / Fever: ${temp}°C');
        } else if (temp < 35.5) {
          alerts.add('Low Body Temperature / Hypothermia: ${temp}°C');
        }
      }

      // Parse SPO2
      final o2 = int.tryParse(latest.oxygenLevel.trim());
      if (o2 != null && o2 < 95) {
        alerts.add('Low Oxygen Saturation (SPO₂): $o2% (Hypoxia Risk)');
      }

      // Parse Pulse
      final pulse = int.tryParse(latest.pulseRate.trim());
      if (pulse != null) {
        if (pulse > 100) {
          alerts.add('Elevated Pulse / Tachycardia: $pulse bpm');
        } else if (pulse < 60) {
          alerts.add('Low Pulse / Bradycardia: $pulse bpm');
        }
      }

      // Parse Sugar
      final sugar = int.tryParse(latest.bloodSugar.trim());
      if (sugar != null) {
        if (sugar > 180) {
          alerts.add('Elevated Blood Sugar / Hyperglycemia: $sugar mg/dL');
        } else if (sugar < 70) {
          alerts.add('Low Blood Sugar / Hypoglycemia: $sugar mg/dL');
        }
      }

      // Parse Resp
      final resp = int.tryParse(latest.respiratoryRate.trim());
      if (resp != null) {
        if (resp > 20) {
          alerts.add('Elevated Respiratory Rate / Tachypnea: $resp bpm');
        } else if (resp < 12) {
          alerts.add('Low Respiratory Rate / Bradypnea: $resp bpm');
        }
      }
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Clinical Alerts & Logs',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Real-Time Clinical Vitals Watchdog',
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (alerts.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All vitals are within normal biological baseline. Patient is clinically stable.',
                        style: GoogleFonts.outfit(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...alerts.map(
                (alert) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          alert,
                          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Recent Activity Logs',
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('No recent activities logged.', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.length > 3 ? 3 : history.length,
                  itemBuilder: (_, idx) {
                    final h = history[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.history_toggle_off_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              h.event,
                              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmEndShift(BuildContext context, PatientModel patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Shift'),
        content: Text('Are you sure you want to end the shift for ${patient.patientName}? This will mark their status as Completed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(patientControllerProvider.notifier).endShift(patient.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shift ended successfully.'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error ending shift: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('End Shift', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmStartShift(BuildContext context, PatientModel patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Shift'),
        content: Text('Are you sure you want to start a new shift for ${patient.patientName}? This will activate their status.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(patientControllerProvider.notifier).startShift(patient.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shift started successfully.'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error starting shift: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Start Shift', style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
  }

  void _archiveRecords(BuildContext context, PatientModel patient) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Archive Patient Record',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to archive ${patient.patientName}? They will disappear from active dashboards, shifts, search, and counters, but all historical vitals, medications, and notes remain safely preserved.',
              style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Clinician / Nurse Name',
                labelStyle: GoogleFonts.outfit(),
                hintText: 'Enter your name for EMR attribution...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final nurse = nameController.text.trim();
              if (nurse.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your name to authenticate archive.')),
                );
                return;
              }
              Navigator.pop(context);
              try {
                await ref.read(patientControllerProvider.notifier).archivePatient(
                      patientId: patient.id,
                      nurseName: nurse,
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Records for ${patient.patientName} have been archived successfully!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  context.go('/home');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error archiving patient: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Archive Record', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePatient(BuildContext context, PatientModel patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient Profile'),
        content: Text('Are you sure you want to permanently delete ${patient.patientName}? This action is irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(patientControllerProvider.notifier).deletePatient(patient.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Patient profile permanently deleted.'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  context.go('/home');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting patient: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }


}

class _AppBarPatientContext extends StatelessWidget {
  final PatientModel patient;
  const _AppBarPatientContext({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            image: const DecorationImage(
              image: AssetImage('assets/images/shifa_logo.jpeg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.patientName,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'MRN: ${patient.mrNumber} • ${patient.age}Y • ${patient.gender} • Dx: ${patient.diagnosis.isNotEmpty ? patient.diagnosis : 'None'}',
                      style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.9), fontSize: 10.5, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _MiniStatusBadge(status: patient.status),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStatusBadge extends StatelessWidget {
  final String status;
  const _MiniStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.toLowerCase() == 'critical' ? AppColors.error : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }
}

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 22),
      onPressed: onTap,
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final String patientId;
  const _OverviewTab({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitalsAsync = ref.watch(vitalsStreamProvider(patientId));
    final patientAsync = ref.watch(patientStreamProvider(patientId));

    return patientAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (patient) {
        if (patient == null) return const Center(child: Text('Patient not found'));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickActions(context),
              const SizedBox(height: 28),
              _sectionHeader('Real-Time Vitals', Icons.sensors_rounded),
              const SizedBox(height: 16),
              vitalsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (vitals) => VitalsGrid(latestVital: vitals.isNotEmpty ? vitals.first : null),
              ),
              const SizedBox(height: 28),
              _sectionHeader('Clinical Condition', Icons.monitor_heart_outlined),
              const SizedBox(height: 16),
              _ConditionCard(patient: patient),
              const SizedBox(height: 28),
              _sectionHeader('Patient Information', Icons.info_outline_rounded),
              const SizedBox(height: 16),
              _InfoCard(patient: patient),
              const SizedBox(height: 28),
              _SupportCard(),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ActionChip(label: 'Add Vitals', icon: Icons.add_chart_rounded, color: AppColors.primary, onTap: () => context.push('/vitals/$patientId'))),
        const SizedBox(width: 12),
        Expanded(child: _ActionChip(label: 'Add Note', icon: Icons.edit_note_rounded, color: const Color(0xFF2E7D32), onTap: () => context.push('/notes/$patientId'))),
        const SizedBox(width: 12),
        Expanded(child: _ActionChip(label: 'Medication', icon: Icons.medication_rounded, color: const Color(0xFFC62828), onTap: () => context.push('/medications/$patientId'))),
      ],
    );
  }
}

class _ConditionCard extends StatelessWidget {
  final PatientModel patient;
  const _ConditionCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE8EDF2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Primary Diagnosis', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(patient.diagnosis, style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.bold, height: 1.4)),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE8EDF2)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(patient.address, style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final PatientModel patient;
  const _InfoCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE8EDF2))),
      child: Column(
        children: [
          _infoRow('MR Number', patient.mrNumber),
          _infoRow('Age / Gender', '${patient.age} Yrs • ${patient.gender}'),
          _infoRow('Assigned Nurse', patient.nurseName.isEmpty ? 'Not assigned' : patient.nurseName),
          _infoRow('Shift Started', _formatDateTime(patient.shiftStartedAt)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '--';
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FF), // Very soft elegant blue background like in the image
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD0E3FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'SUPPORT & ASSISTANCE',
            style: GoogleFonts.outfit(
              color: const Color(0xFF2563EB), // Sleek blue
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'For any technical help or shift support, please contact us:',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1E3A8A), // Dark Navy
              fontWeight: FontWeight.w600,
              fontSize: 15,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SupportButton(
                  label: 'CALL NOW',
                  icon: Icons.phone_in_talk_rounded,
                  color: const Color(0xFF2563EB), // Blue button
                  onTap: () async {
                    final Uri launchUri = Uri(
                      scheme: 'tel',
                      path: '03009262562',
                    );
                    if (await canLaunchUrl(launchUri)) {
                      await launchUrl(launchUri);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SupportButton(
                  label: 'WHATSAPP',
                  icon: Icons.chat_bubble_outline_rounded,
                  color: const Color(0xFF10B981), // Green button
                  onTap: () async {
                    final Uri whatsappUri = Uri.parse('https://wa.me/923009262562');
                    if (await canLaunchUrl(whatsappUri)) {
                      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '0300-9262562',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1E3A8A), // Bold dark blue number
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SupportButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _DashboardBottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
        color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.insights_rounded, // Pulse icon
                  label: 'STATUS',
                  isSelected: selectedIndex == 0,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.favorite_border_rounded, // Heart icon
                  label: 'VITALS',
                  isSelected: selectedIndex == 1,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.medication_outlined, // Pill icon
                  label: 'MEDS',
                  isSelected: selectedIndex == 2,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.description_outlined, // File icon
                  label: 'NOTES',
                  isSelected: selectedIndex == 3,
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.calendar_month_outlined, // Calendar icon
                  label: 'ARCHIVES',
                  isSelected: selectedIndex == 4,
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isSelected
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB), // Active blue background
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x3D2563EB),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Icon(icon, color: const Color(0xFF94A3B8), size: 22),
                  ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 9.5,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}