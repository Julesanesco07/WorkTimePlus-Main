import 'package:flutter/material.dart';

class TrackingCard extends StatelessWidget {
  final String    status;
  final Duration  workedDuration;
  final Duration  totalBreakDuration;
  final bool      isOnBreak;
  final DateTime? breakStart;
  final String Function() breakDurationText;

  const TrackingCard({
    super.key,
    required this.status,
    required this.workedDuration,
    required this.totalBreakDuration,
    required this.isOnBreak,
    required this.breakStart,
    required this.breakDurationText,
  });

  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);

  bool get _isTimedIn  => status == 'working' || status == 'on_break';
  bool get _isTimedOut => status == 'timed_out';

  String get _elapsedText {
    final h = workedDuration.inHours.toString().padLeft(2, '0');
    final m = (workedDuration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (workedDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    String trackStatus;
    Color  trackStatusColor;

    switch (status) {
      case 'on_break':  trackStatus = 'On Break';    trackStatusColor = Colors.amberAccent.shade400; break;
      case 'working':   trackStatus = 'Working';     trackStatusColor = Colors.greenAccent.shade400; break;
      case 'timed_out': trackStatus = 'Shift Ended'; trackStatusColor = Colors.redAccent.shade100;   break;
      default:          trackStatus = 'Not Started'; trackStatusColor = Colors.white38;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navyBlue, steelBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: navyBlue.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        // ── Header ───────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("Today's Work Hours",
              style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.3)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: trackStatusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: trackStatusColor.withOpacity(0.5)),
            ),
            child: Row(children: [
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(color: trackStatusColor, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(trackStatus,
                  style: TextStyle(color: trackStatusColor, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        // ── Elapsed time ─────────────────────────────────
        Text(_elapsedText,
            style: const TextStyle(
                color: Colors.white, fontSize: 46, fontWeight: FontWeight.w300, letterSpacing: 4)),
        const SizedBox(height: 4),
        Text(
          _isTimedIn   ? 'Elapsed work time (breaks excluded)'
              : _isTimedOut ? 'Final hours logged'
              : 'Clock in to start tracking',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 14),
        // ── Progress bar ──────────────────────────────────
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Daily Goal  8h', style: TextStyle(color: Colors.white60, fontSize: 11)),
            Text(
              '${(workedDuration.inSeconds / (8 * 3600) * 100).clamp(0, 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (workedDuration.inSeconds / (8 * 3600)).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.2),
              color: orange,
              minHeight: 6,
            ),
          ),
        ]),
        // ── Break indicator ───────────────────────────────
        if (totalBreakDuration > Duration.zero || isOnBreak) ...[
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.free_breakfast_rounded, color: Colors.amber, size: 14),
            const SizedBox(width: 6),
            Text('Total break: ${breakDurationText()}',
                style: const TextStyle(color: Colors.amber, fontSize: 11)),
          ]),
        ],
      ]),
    );
  }
}