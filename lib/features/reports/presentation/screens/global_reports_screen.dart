import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';
import '../../../patients/presentation/providers/patient_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/report_model.dart';
import '../../domain/report_exporter.dart';
import '../../../../core/widgets/shifa_shimmer.dart';

final globalReportsStreamProvider = StreamProvider<List<ReportModel>>((ref) {
  return Stream.value([
    ReportModel(
      id: 'REP-001',
      patientName: 'Ahmed Ali',
      mrn: 'MR-9821',
      reportType: 'Vitals Summary',
      generatingStaff: 'Nurse Sarah',
      generatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      data: {'bp': '120/80', 'pulse': '72', 'spo2': '98%'},
    ),
    ReportModel(
      id: 'REP-002',
      patientName: 'John Doe',
      mrn: 'MR-1022',
      reportType: 'Lab Results',
      generatingStaff: 'Dr. Mike',
      generatedAt: DateTime.now().subtract(const Duration(days: 1)),
      data: {'glucose': '110 mg/dL', 'cholesterol': '180 mg/dL'},
    ),
  ]); // Simulated real-time stream
});

class GlobalReportsScreen extends ConsumerStatefulWidget {
  const GlobalReportsScreen({super.key});

  @override
  ConsumerState<GlobalReportsScreen> createState() => _GlobalReportsScreenState();
}

class _GlobalReportsScreenState extends ConsumerState<GlobalReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Reports Hub',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Analytics'),
            Tab(text: 'Directory'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalyticsTab(),
          _buildDirectoryTab(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final analyticsAsync = ref.watch(globalAnalyticsProvider);
    return analyticsAsync.when(
      loading: () => _buildAnalyticsShimmer(),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('System Overview', Icons.analytics_outlined),
            const SizedBox(height: 24),
            _buildSummaryGrid(data),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildDirectoryTab() {
    final reportsAsync = ref.watch(globalReportsStreamProvider);
    return reportsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ShifaShimmer.listItem(),
        ),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (reports) => ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildReportItem(reports[index]),
      ),
    );
  }

  Widget _buildReportItem(ReportModel report) {
    return InkWell(
      onTap: () => _showReportPreview(report),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.description_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.reportType,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${report.patientName} • ${report.mrn}',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${report.generatedAt.hour}:${report.generatedAt.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                Text(
                  report.generatingStaff,
                  style: GoogleFonts.outfit(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReportPreview(ReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            _buildPreviewHeader(report),
            Expanded(
              child: Screenshot(
                controller: _screenshotController,
                child: _buildReportDocument(report),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewHeader(ReportModel report) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE8EDF2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Document Preview', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                Text(report.id, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
          _buildExportMenu(report),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildExportMenu(ReportModel report) {
    return PopupMenuButton<String>(
      onSelected: (val) async {
        if (val == 'pdf') await ReportExporter.exportToPdf(report);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.download_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Export', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'pdf', child: Text('Download PDF')),
        const PopupMenuItem(value: 'jpeg', child: Text('Save as JPEG')),
        const PopupMenuItem(value: 'png', child: Text('Save as PNG')),
      ],
    );
  }

  Widget _buildReportDocument(ReportModel report) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SHIFA', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)),
              Text('OFFICIAL REPORT', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 40),
          _reportField('Patient', report.patientName),
          _reportField('MR Number', report.mrn),
          _reportField('Report Type', report.reportType),
          _reportField('Date Generated', report.generatedAt.toString()),
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 20),
          ...report.data.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key.toUpperCase(), style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                Text(e.value.toString(), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _reportField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary))),
          Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        ShifaShimmer.listItem(height: 40, width: 200),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: List.generate(4, (_) => ShifaShimmer.card()),
        ),
      ]),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
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

  Widget _buildSummaryGrid(Map<String, dynamic> data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _AnalyticsCard(label: 'Total Patients', value: '${data['totalPatients']}', icon: Icons.people_rounded, color: AppColors.primary),
        _AnalyticsCard(label: 'Active Patients', value: '${data['activePatients']}', icon: Icons.person_pin_rounded, color: AppColors.success),
        _AnalyticsCard(label: 'Total Vitals', value: '${data['vitalsCount']}', icon: Icons.monitor_heart_rounded, color: Colors.orange),
        _AnalyticsCard(label: 'Meds Given', value: '${data['medsCount']}', icon: Icons.medical_services_rounded, color: Colors.purple),
      ],
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 2),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(label, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

