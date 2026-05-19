import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../patients/presentation/providers/patient_provider.dart';
import '../../../patients/presentation/providers/history_provider.dart';
import '../../../vitals/presentation/providers/vitals_provider.dart';
import '../../../medications/presentation/providers/medications_provider.dart';
import '../../../notes/presentation/providers/notes_provider.dart';
import '../../domain/report_exporter.dart';
import '../../../../core/constants/app_colors.dart';

class ReportPreviewScreen extends ConsumerWidget {
  final String patientId;
  const ReportPreviewScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientStreamProvider(patientId));
    final vitalsAsync = ref.watch(vitalsStreamProvider(patientId));
    final medsAsync = ref.watch(medicationsStreamProvider(patientId));
    final notesAsync = ref.watch(notesStreamProvider(patientId));
    final historyAsync = ref.watch(historyStreamProvider(patientId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Clinical Report Preview',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[100]),
        ),
      ),
      body: patientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading patient: $err')),
        data: (patient) {
          if (patient == null) {
            return const Center(child: Text('Patient not found'));
          }

          final vitals = vitalsAsync.value ?? [];
          final meds = medsAsync.value ?? [];
          final notes = notesAsync.value ?? [];
          final history = historyAsync.value ?? [];

          return PdfPreview(
            build: (format) => ReportExporter.generatePatientReportPdf(
              patient: patient,
              vitals: vitals,
              meds: meds,
              notes: notes,
              history: history,
            ),
            canChangeOrientation: false,
            canChangePageFormat: false,
            pdfFileName: 'Clinical_Report_${patient.mrNumber}.pdf',
            onPrinted: (ctx) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report printed successfully!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            onShared: (ctx) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report shared successfully!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
