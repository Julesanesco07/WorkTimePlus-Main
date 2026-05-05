import 'package:flutter/material.dart';

class TrackingCard extends StatelessWidget {
  final String    status;
  final Duration  workedDuration;
  final Duration  totalBreakDuration;
  final bool      isOnBreak;
  final DateTime? breakStart;
  final String Function() breakDurationText;
  final bool      isOvertime;
  final Duration  shiftDuration;

  const TrackingCard({
    super.key,
    required this.status,
    required this.workedDuration,
    required this.totalBreakDuration,
    required this.isOnBreak,
    required this.breakStart,
    required this.breakDurationText,
    required this.isOvertime,
    required this.shiftDuration,
  });

  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);

  bool get _isTimedIn  => status == 'working' || status == 'on_break';
  bool get _isTimedOut => status == 'timed_out';

  // ── Remaining shift time — based on actual worked time ───
  Duration get _remaining {
    final rem = shiftDuration - workedDuration;
    return rem.isNegative ? Duration.zero : rem;
  }

  // ── Overtime beyond 8h of work ────────────────────────────
  Duration get _overtimeAmount {
    if (!isOvertime) return Duration.zero;
    final ot = workedDuration - shiftDuration;
    return ot.isNegative ? Duration.zero : ot;
  }

  // ── Format Duration as HH:MM:SS ──────────────────────────
  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ── Worked time display (excludes breaks) ────────────────
  String get _workedText => _fmt(workedDuration);

  @override
  Widget build(BuildContext context) {
    // ── Status badge ─────────────────────────────────────────
    String trackStatus;
    Color  trackStatusColor;
    if (isOvertime && _isTimedIn) {
      trackStatus      = 'Overtime';
      trackStatusColor = orange;
    } else {
      switch (status) {
        case 'on_break':  trackStatus = 'On Break';    trackStatusColor = Colors.amberAccent.shade400; break;
        case 'working':   trackStatus = 'Working';     trackStatusColor = Colors.greenAccent.shade400; break;
        case 'timed_out': trackStatus = 'Shift Ended'; trackStatusColor = Colors.redAccent.shade100;   break;
        default:          trackStatus = 'Not Started'; trackStatusColor = Colors.white38;
      }
    }

    // Card gradient changes to orange tones when in overtime
    final List<Color> gradientColors = isOvertime && _isTimedIn
        ? [const Color(0xFF8B3A1A), const Color(0xFFB5541E)]
        : [navyBlue, steelBlue];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isOvertime && _isTimedIn ? orange : navyBlue)
                .withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: [

        // ── Header row ──────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            isOvertime && _isTimedIn
                ? 'Overtime Running'
                : "Today's Shift",
            style: const TextStyle(
                color: Colors.white70, fontSize: 13, letterSpacing: 0.3),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: trackStatusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: trackStatusColor.withOpacity(0.5)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                      color: trackStatusColor, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(trackStatus,
                  style: TextStyle(
                      color: trackStatusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),

        const SizedBox(height: 10),

        // ── Main timer display ───────────────────────────────
        if (!_isTimedIn && !_isTimedOut)
        // Idle — show shift target
          Column(children: [
            const Text('08:00:00',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 46,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4)),
            const SizedBox(height: 4),
            const Text('Clock in to start your shift',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ])
        else if (_isTimedOut)
        // Shift ended — show worked time
          Column(children: [
            Text(_workedText,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 46,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4)),
            const SizedBox(height: 4),
            const Text('Final hours logged (breaks excluded)',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ])
        else if (isOvertime)
          // OVERTIME — show how much over they are
            Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Icon(Icons.add, color: orange, size: 28),
                  Text(_fmt(_overtimeAmount),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 46,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 4)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Overtime — 8h work shift complete',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ])
          else
          // COUNTDOWN — time remaining in shift
            Column(children: [
              Text(_fmt(_remaining),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 46,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 4)),
              const SizedBox(height: 4),
              const Text('Remaining work time:',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ]),

        const SizedBox(height: 14),

        // ── Progress bar ─────────────────────────────────────
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              isOvertime && _isTimedIn
                  ? 'Shift complete  8h 0m'
                  : 'Work goal',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
            Text(
              isOvertime && _isTimedIn
                  ? '100%'
                  : '${(workedDuration.inSeconds / shiftDuration.inSeconds * 100).clamp(0, 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isOvertime
                  ? 1.0
                  : (workedDuration.inSeconds / shiftDuration.inSeconds)
                  .clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.2),
              color: isOvertime ? orange : Colors.greenAccent.shade400,
              minHeight: 6,
            ),
          ),
        ]),

        // ── Work vs break breakdown ───────────────────────────
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _MiniStat(
            icon: Icons.work_outline_rounded,
            label: 'Worked',
            value: _workedText,
            color: Colors.greenAccent.shade400,
          ),
          _MiniStat(
            icon: Icons.free_breakfast_rounded,
            label: 'Break',
            value: breakDurationText(),
            color: Colors.amberAccent.shade400,
          ),
          if (_isTimedIn && !isOvertime)
            _MiniStat(
              icon: Icons.hourglass_bottom_rounded,
              label: 'Remaining',
              value: _fmt(_remaining),
              color: Colors.white70,
            )
          else if (isOvertime && _isTimedIn)
            _MiniStat(
              icon: Icons.trending_up_rounded,
              label: 'Overtime',
              value: _fmt(_overtimeAmount),
              color: orange,
            ),
        ]),

      ]),
    );
  }
}

// ── Mini stat below progress bar ─────────────────────────────
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 13),
      const SizedBox(width: 5),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 9, letterSpacing: 0.3)),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ]),
    ]);
  }
}