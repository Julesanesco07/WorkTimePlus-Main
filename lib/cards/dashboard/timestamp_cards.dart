import 'package:flutter/material.dart';

class TimestampCards extends StatelessWidget {
  final DateTime? timeIn;
  final DateTime? timeOut;
  final DateTime? lastBreakStart;
  final DateTime? breakEnd;

  const TimestampCards({
    super.key,
    required this.timeIn,
    required this.timeOut,
    required this.lastBreakStart,
    required this.breakEnd,
  });

  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);

  String _fmt(DateTime dt) {
    final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m  = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Time In / Time Out ──────────────────────────────
      Row(children: [
        Expanded(child: _TimeStampCard(
          label: 'Time In',  icon: Icons.login_rounded,
          color: Colors.green.shade600,
          time:  timeIn != null ? _fmt(timeIn!) : '--:-- --',
          isSet: timeIn != null,
        )),
        const SizedBox(width: 12),
        Expanded(child: _TimeStampCard(
          label: 'Time Out', icon: Icons.logout_rounded,
          color: navyBlue,
          time:  timeOut != null ? _fmt(timeOut!) : '--:-- --',
          isSet: timeOut != null,
        )),
      ]),
      const SizedBox(height: 12),
      // ── Break Start / Break End ─────────────────────────
      Row(children: [
        Expanded(child: _TimeStampCard(
          label: 'Break Start', icon: Icons.free_breakfast_rounded,
          color: steelBlue,
          time:  lastBreakStart != null ? _fmt(lastBreakStart!) : '--:-- --',
          isSet: lastBreakStart != null,
        )),
        const SizedBox(width: 12),
        Expanded(child: _TimeStampCard(
          label: 'Break End', icon: Icons.play_arrow_rounded,
          color: orange,
          time:  breakEnd != null ? _fmt(breakEnd!) : '--:-- --',
          isSet: breakEnd != null,
        )),
      ]),
    ]);
  }
}

class _TimeStampCard extends StatelessWidget {
  final String   label;
  final String   time;
  final IconData icon;
  final Color    color;
  final bool     isSet;

  const _TimeStampCard({
    required this.label, required this.time, required this.icon,
    required this.color, required this.isSet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSet ? color.withOpacity(0.06) : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isSet ? color.withOpacity(0.2) : Colors.transparent),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSet ? color.withOpacity(0.12) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: isSet ? color : Colors.grey, size: 18),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(time,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold,
                  color: isSet ? color : const Color(0xFFBDBDBD))),
        ]),
      ]),
    );
  }
}