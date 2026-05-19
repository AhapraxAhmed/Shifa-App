import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../patients/presentation/providers/history_provider.dart';
import '../../../../core/constants/app_colors.dart';

class HistoryScreen extends ConsumerWidget {
  final String patientId;
  final bool showAppBar;
  const HistoryScreen({super.key, required this.patientId, this.showAppBar = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final histAsync = ref.watch(historyStreamProvider(patientId));
    return Scaffold(
      backgroundColor: showAppBar ? AppColors.background : Colors.transparent,
      appBar: showAppBar ? AppBar(title: const Text('Patient History'), backgroundColor: Colors.white) : null,
      body: histAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (events) {
          if (events.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No history yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ]));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (_, i) {
              final e = events[i];
              final iconMap = {'vitals': Icons.monitor_heart_rounded, 'medication': Icons.medical_services_rounded, 'note': Icons.note_alt_rounded, 'registration': Icons.person_add_rounded};
              final colorMap = {'vitals': const Color(0xFF1E88E5), 'medication': const Color(0xFF43A047), 'note': const Color(0xFF8E24AA), 'registration': AppColors.primary};
              final color = colorMap[e.type] ?? AppColors.primary;
              final icon = iconMap[e.type] ?? Icons.history_rounded;
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 18)),
                  if (i < events.length - 1) Container(width: 2, height: 40, color: const Color(0xFFE8EDF2)),
                ]),
                const SizedBox(width: 12),
                Expanded(child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EDF2))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.event, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
                    if (e.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(DateFormat('dd MMM yyyy, hh:mm a').format(e.createdAt!), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ]),
                )),
              ]);
            },
          );
        },
      ),
    );
  }
}
