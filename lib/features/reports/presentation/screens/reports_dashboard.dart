import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../patients/presentation/providers/patient_provider.dart';
import '../../../vitals/presentation/providers/vitals_provider.dart';
import '../../../medications/presentation/providers/medications_provider.dart';
import '../../../notes/presentation/providers/notes_provider.dart';
import '../../../patients/presentation/providers/history_provider.dart';
import '../../domain/report_exporter.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/reports_provider.dart';

class ReportsDashboard extends ConsumerWidget {
  final String patientId;
  final bool showAppBar;
  const ReportsDashboard({super.key, required this.patientId, this.showAppBar = true});

  Future<void> _quickPrint(BuildContext context, WidgetRef ref) async {
    try {
      final patient = ref.read(patientStreamProvider(patientId)).value;
      if (patient == null) throw 'Patient data not loaded yet';
      
      final vitals = ref.read(vitalsStreamProvider(patientId)).value ?? [];
      final meds = ref.read(medicationsStreamProvider(patientId)).value ?? [];
      final notes = ref.read(notesStreamProvider(patientId)).value ?? [];
      final history = ref.read(historyStreamProvider(patientId)).value ?? [];

      final pdfData = await ReportExporter.generatePatientReportPdf(
        patient: patient,
        vitals: vitals,
        meds: meds,
        notes: notes,
        history: history,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'Clinical_Report_${patient.mrNumber}',
      );
      
      await ref.read(patientReportControllerProvider.notifier).logReportPrinted(
        patientId: patientId,
        reportName: 'Quick Shift Report',
        nurseName: patient.nurseName.isEmpty ? 'Nurse' : patient.nurseName,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing report: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleHistoricalAction({
    required BuildContext context,
    required WidgetRef ref,
    required String action,
    required String reportName,
    required String generatedBy,
  }) async {
    try {
      final patient = ref.read(patientStreamProvider(patientId)).value;
      if (patient == null) throw 'Patient data not loaded yet';
      
      final vitals = ref.read(vitalsStreamProvider(patientId)).value ?? [];
      final meds = ref.read(medicationsStreamProvider(patientId)).value ?? [];
      final notes = ref.read(notesStreamProvider(patientId)).value ?? [];
      final history = ref.read(historyStreamProvider(patientId)).value ?? [];

      final pdfData = await ReportExporter.generatePatientReportPdf(
        patient: patient,
        vitals: vitals,
        meds: meds,
        notes: notes,
        history: history,
      );

      if (action == 'preview') {
        showDialog(
          context: context,
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(reportName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: PdfPreview(
              build: (format) => pdfData,
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
            ),
          ),
        );
      } else if (action == 'print') {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfData,
          name: 'Clinical_Report_${patient.mrNumber}',
        );
        await ref.read(patientReportControllerProvider.notifier).logReportPrinted(
          patientId: patientId,
          reportName: reportName,
          nurseName: generatedBy,
        );
      } else if (action == 'share') {
        await Printing.sharePdf(bytes: pdfData, filename: '${reportName.replaceAll(" ", "_")}.pdf');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showGenerateReportDialog(BuildContext context, WidgetRef ref, dynamic patient) {
    final now = DateTime.now();
    final df = DateFormat('dd MMM yyyy');
    
    final nameController = TextEditingController(text: 'Shift Summary Report - ${df.format(now)}');
    final periodController = TextEditingController(text: df.format(now));
    final nurseController = TextEditingController(text: patient.nurseName.isEmpty ? 'Nurse Ahmed' : patient.nurseName);
    String selectedType = 'Shift Summary';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Generate EMR Report',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This compiles current vitals, medications, and clinical progress logs into a permanent historical EMR PDF.',
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Report Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: 'Report Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: const [
                  DropdownMenuItem(value: 'Shift Summary', child: Text('Shift Summary')),
                  DropdownMenuItem(value: 'Weekly Assessment', child: Text('Weekly Assessment')),
                  DropdownMenuItem(value: 'Discharge Summary', child: Text('Discharge Summary')),
                  DropdownMenuItem(value: 'Incident Report', child: Text('Incident Report')),
                ],
                onChanged: (val) {
                  if (val != null) selectedType = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: periodController,
                decoration: InputDecoration(
                  labelText: 'Report Period / Date',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nurseController,
                decoration: InputDecoration(
                  labelText: 'Generating Clinician / Nurse',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final period = periodController.text.trim();
              final nurse = nurseController.text.trim();

              if (name.isEmpty || nurse.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter Report Name and clinician signature')),
                );
                return;
              }

              Navigator.pop(context);
              try {
                await ref.read(patientReportControllerProvider.notifier).saveReport(
                      patientId: patientId,
                      reportName: name,
                      reportType: selectedType,
                      generatedBy: nurse,
                      reportPeriod: period,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Report "$name" generated and archived permanently.'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving report: $e'),
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
            child: Text('Generate & Save', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientStreamProvider(patientId));
    final vitalsAsync = ref.watch(vitalsStreamProvider(patientId));
    final medsAsync = ref.watch(medicationsStreamProvider(patientId));
    final notesAsync = ref.watch(notesStreamProvider(patientId));
    final reportsAsync = ref.watch(patientReportsStreamProvider(patientId));

    return Scaffold(
      backgroundColor: showAppBar ? AppColors.background : Colors.transparent,
      appBar: showAppBar
          ? AppBar(
              title: Text(
                'Clinical Reports Dashboard',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Core Action Card
            patientAsync.maybeWhen(
              data: (patient) {
                if (patient == null) return const SizedBox.shrink();
                return _buildGenerateActionsCard(context, ref, patient);
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            
            // Statistics Metrics Row
            _sectionTitle('Shift Record Metrics'),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard(
                  'Vitals Recorded',
                  vitalsAsync.maybeWhen(data: (v) => '${v.length}', orElse: () => '0'),
                  Icons.monitor_heart_rounded,
                  const Color(0xFF1E88E5),
                ),
                const SizedBox(width: 12),
                _statCard(
                  'Medications',
                  medsAsync.maybeWhen(data: (m) => '${m.length}', orElse: () => '0'),
                  Icons.medical_services_rounded,
                  const Color(0xFF43A047),
                ),
                const SizedBox(width: 12),
                _statCard(
                  'Nurse Notes',
                  notesAsync.maybeWhen(data: (n) => '${n.length}', orElse: () => '0'),
                  Icons.note_alt_rounded,
                  const Color(0xFF8E24AA),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Report History System List
            _sectionTitle('EMR Historical Reports Log'),
            const SizedBox(height: 12),
            reportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading historical reports: $e')),
              data: (reports) {
                if (reports.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8EDF2)),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history_edu_rounded, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            'No generated reports saved. Click "Generate EMR Report" above to compile a permanent record.',
                            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final df = DateFormat('dd MMM yyyy, hh:mm a');
                    final dateStr = report.generatedAt != null
                        ? df.format(report.generatedAt!)
                        : 'Just Now';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8EDF2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        report.reportName,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Type: ${report.reportType}  •  Period: ${report.reportPeriod}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Generated on: $dateStr  •  By: ${report.generatedBy}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFE8EDF2)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _historyActionButton(
                                  context: context,
                                  ref: ref,
                                  icon: Icons.visibility_rounded,
                                  label: 'Preview',
                                  action: 'preview',
                                  report: report,
                                ),
                                const SizedBox(width: 8),
                                _historyActionButton(
                                  context: context,
                                  ref: ref,
                                  icon: Icons.print_rounded,
                                  label: 'Print',
                                  action: 'print',
                                  report: report,
                                ),
                                const SizedBox(width: 8),
                                _historyActionButton(
                                  context: context,
                                  ref: ref,
                                  icon: Icons.share_rounded,
                                  label: 'Share',
                                  action: 'share',
                                  report: report,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _historyActionButton({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required String action,
    required dynamic report,
  }) {
    return TextButton.icon(
      onPressed: () => _handleHistoricalAction(
        context: context,
        ref: ref,
        action: action,
        reportName: report.reportName,
        generatedBy: report.generatedBy,
      ),
      icon: Icon(icon, size: 14, color: AppColors.primary),
      label: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: AppColors.primary.withOpacity(0.06),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildGenerateActionsCard(BuildContext context, WidgetRef ref, dynamic patient) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0x10004D40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: Color(0xFF004D40),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EMR Report Engine',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Compile and archive permanent clinical charts.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showGenerateReportDialog(context, ref, patient),
                  icon: const Icon(Icons.add_chart_rounded, size: 18, color: Colors.white),
                  label: Text(
                    'Generate EMR Report',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _quickPrint(context, ref),
                  icon: const Icon(Icons.print_rounded, size: 18, color: Color(0xFF004D40)),
                  label: Text(
                    'Quick Print',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF004D40)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF004D40)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}