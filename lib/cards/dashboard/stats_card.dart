import 'package:flutter/material.dart';
import '../../app_state.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({super.key});

  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);

  @override
  Widget build(BuildContext context) {
    final leaveLeft = AppState().vacationBalance;
    return Row(children: [
      Expanded(child: _StatTile(label: 'This Week',  value: '34h 20m',         icon: Icons.bar_chart_rounded,       color: steelBlue)),
      const SizedBox(width: 10),
      Expanded(child: _StatTile(label: 'Overtime',   value: '2h 10m',          icon: Icons.more_time_rounded,       color: orange)),
      const SizedBox(width: 10),
      Expanded(child: _StatTile(label: 'Leave Left', value: '$leaveLeft days', icon: Icons.event_available_rounded, color: navyBlue)),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
      ]),
    );
  }
}