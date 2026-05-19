import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../vitals/data/models/vital_model.dart';

class VitalsGrid extends StatelessWidget {
  final VitalModel? latestVital;

  const VitalsGrid({super.key, this.latestVital});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        _VitalCard(
          label: 'BP',
          value: latestVital?.bloodPressure ?? '--',
          unit: 'mmHg',
          icon: Icons.speed_rounded,
          color: _getBPColor(latestVital?.bloodPressure),
        ),
        _VitalCard(
          label: 'Pulse',
          value: latestVital?.pulseRate ?? '--',
          unit: 'bpm',
          icon: Icons.favorite_rounded,
          color: _getPulseColor(latestVital?.pulseRate),
        ),
        _VitalCard(
          label: 'SPO2',
          value: latestVital?.oxygenLevel ?? '--',
          unit: '%',
          icon: Icons.air_rounded,
          color: _getSPO2Color(latestVital?.oxygenLevel),
        ),
        _VitalCard(
          label: 'Temp',
          value: latestVital?.temperature ?? '--',
          unit: '°C',
          icon: Icons.thermostat_rounded,
          color: _getTempColor(latestVital?.temperature),
        ),
        _VitalCard(
          label: 'Sugar',
          value: latestVital?.bloodSugar ?? '--',
          unit: 'mg/dL',
          icon: Icons.water_drop_rounded,
          color: _getSugarColor(latestVital?.bloodSugar),
        ),
        _VitalCard(
          label: 'Resp',
          value: latestVital?.respiratoryRate ?? '--',
          unit: 'bpm',
          icon: Icons.timer_rounded,
          color: _getRespColor(latestVital?.respiratoryRate),
        ),
      ],
    );
  }

  Color _getBPColor(String? bp) {
    if (bp == null || bp.isEmpty || bp == '--') return AppColors.primary;
    try {
      final parts = bp.split('/');
      if (parts.length != 2) return AppColors.primary;
      final sys = int.parse(parts[0]);
      final dia = int.parse(parts[1]);
      if (sys > 160 || dia > 100 || sys < 90 || dia < 60) return AppColors.error;
      if (sys > 140 || dia > 90) return Colors.orange;
      return AppColors.success;
    } catch (_) {
      return AppColors.primary;
    }
  }

  Color _getPulseColor(String? pulse) {
    if (pulse == null || pulse.isEmpty || pulse == '--') return Colors.purple;
    try {
      final p = int.parse(pulse);
      if (p > 120 || p < 50) return AppColors.error;
      if (p > 100 || p < 60) return Colors.orange;
      return AppColors.success;
    } catch (_) {
      return Colors.purple;
    }
  }

  Color _getSPO2Color(String? spo2) {
    if (spo2 == null || spo2.isEmpty || spo2 == '--') return Colors.teal;
    try {
      final s = int.parse(spo2);
      if (s < 90) return AppColors.error;
      if (s < 95) return Colors.orange;
      return AppColors.success;
    } catch (_) {
      return Colors.teal;
    }
  }

  Color _getTempColor(String? temp) {
    if (temp == null || temp.isEmpty || temp == '--') return Colors.orange;
    try {
      final t = double.parse(temp);
      if (t > 38.5 || t < 35.0) return AppColors.error;
      if (t > 37.5 || t < 36.0) return Colors.orange;
      return AppColors.success;
    } catch (_) {
      return Colors.orange;
    }
  }

  Color _getSugarColor(String? sugar) {
    if (sugar == null || sugar.isEmpty || sugar == '--') return Colors.redAccent;
    try {
      final s = int.parse(sugar);
      if (s > 200 || s < 70) return AppColors.error;
      if (s > 140) return Colors.orange;
      return AppColors.success;
    } catch (_) {
      return Colors.redAccent;
    }
  }

  Color _getRespColor(String? resp) {
    if (resp == null || resp.isEmpty || resp == '--') return Colors.blueGrey;
    try {
      final r = int.parse(resp);
      if (r > 25 || r < 10) return AppColors.error;
      if (r > 20) return Colors.orange;
      return AppColors.success;
    } catch (_) {
      return Colors.blueGrey;
    }
  }
}

class _VitalCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _VitalCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
