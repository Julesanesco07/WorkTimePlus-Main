import 'package:flutter/material.dart';
import '../../app_state.dart';

class GreetingCard extends StatelessWidget {
  final DateTime now;
  final String   status;
  final String   availability;
  final void Function(String) onAvailabilityChanged;

  const GreetingCard({
    super.key,
    required this.now,
    required this.status,
    required this.availability,
    required this.onAvailabilityChanged,
  });

  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);
  static const softGray  = Color(0xFFF2F2F2);

  String _formatClockTime(DateTime dt) {
    final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m  = dt.minute.toString().padLeft(2, '0');
    final s  = dt.second.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m:$s $ap';
  }

  String _formatFullDate(DateTime dt) {
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hour      = now.hour;
    final greeting  = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';

    // First name from the DB-backed AppState
    final fullName  = AppState().userName;
    final firstName = fullName.split(' ').first;

    Color  statusColor;
    Color  statusBg;
    String statusLabel;

    switch (status) {
      case 'on_break':
        statusLabel = 'On Break';
        statusColor = steelBlue;
        statusBg    = steelBlue.withOpacity(0.1);
        break;
      case 'working':
        statusLabel = 'Clocked In';
        statusColor = Colors.green.shade600;
        statusBg    = const Color(0xFFE8F5E9);
        break;
      case 'timed_out':
        statusLabel = 'Clocked Out';
        statusColor = Colors.red.shade400;
        statusBg    = Colors.red.shade50;
        break;
      default:
        statusLabel = 'Not Clocked In';
        statusColor = const Color(0xFF9E9E9E);
        statusBg    = softGray;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: greeting + badges ──────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting, $firstName 👋',
                  style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: navyBlue)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                            color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(statusLabel,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor)),
                  ]),
                ),
                // Availability dropdown
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: availability == 'Available'
                        ? const Color(0xFFFFF3E0)
                        : softGray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: availability,
                      isDense: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          size: 16, color: orange),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: availability == 'Available'
                            ? orange
                            : const Color(0xFF9E9E9E),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Available',
                            child: Text('Available')),
                        DropdownMenuItem(
                            value: 'Not Available',
                            child: Text('Not Available')),
                      ],
                      onChanged: (val) =>
                          onAvailabilityChanged(val!),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
        // ── Right: live clock ─────────────────────────────────
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_formatClockTime(now),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: navyBlue,
                  letterSpacing: 0.8)),
          const SizedBox(height: 2),
          Text(_formatFullDate(now),
              style: const TextStyle(fontSize: 10, color: steelBlue)),
        ]),
      ],
    );
  }
}