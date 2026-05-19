import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/history_event_model.dart';

class ActivityTimeline extends StatelessWidget {
  final List<HistoryEventModel> events;

  const ActivityTimeline({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: const Center(
          child: Text(
            'No recent activities',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      children: events.take(5).map((e) => _TimelineItem(event: e)).toList(),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final HistoryEventModel event;

  const _TimelineItem({required this.event});

  @override
  Widget build(BuildContext context) {
    final iconMap = {
      'vitals': Icons.monitor_heart_rounded,
      'medication': Icons.medical_services_rounded,
      'note': Icons.note_alt_rounded,
      'registration': Icons.person_add_rounded,
      'shift': Icons.assignment_ind_rounded,
    };

    final colorMap = {
      'vitals': const Color(0xFF1E88E5),
      'medication': const Color(0xFF43A047),
      'note': const Color(0xFF8E24AA),
      'registration': AppColors.primary,
      'shift': const Color(0xFFEF6C00),
    };

    final icon = iconMap[event.type] ?? Icons.history_rounded;
    final color = colorMap[event.type] ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              Container(
                width: 2,
                height: 30,
                color: color.withValues(alpha: 0.05),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
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
                      Text(
                        _getTypeLabel(event.type),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      if (event.createdAt != null)
                        Text(
                          DateFormat('hh:mm A').format(event.createdAt!),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.event,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(event.createdAt!),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'vitals': return 'VITALS ADDED';
      case 'medication': return 'MEDICATION ADDED';
      case 'note': return 'NURSE NOTE';
      case 'registration': return 'PATIENT REGISTERED';
      case 'shift': return 'SHIFT STARTED';
      default: return 'ACTIVITY';
    }
  }
}
