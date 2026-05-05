import 'package:flutter/material.dart';

class AttendanceCalendar extends StatefulWidget {
  final Map<String, Map<String, dynamic>> data;
  final void Function(DateTime) onDaySelected;
  final void Function(int month, int year)? onMonthChanged;

  const AttendanceCalendar({
    super.key,
    required this.data,
    required this.onDaySelected,
    this.onMonthChanged,
  });

  @override
  State<AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);

  int _month = DateTime.now().month;
  int _year  = DateTime.now().year;

  static const _months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];
  static const _weekLabels = ['S','M','T','W','T','F','S'];
  static const _shortMonths = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];
  static final _legend = [
    {'label': 'Present',  'color': const Color(0xFF388E3C)},
    {'label': 'Late',     'color': const Color(0xFFE97638)},
    {'label': 'Absent',   'color': const Color(0xFFE53935)},
    {'label': 'On Leave', 'color': const Color(0xFF4A698F)},
    {'label': 'Pending',  'color': const Color(0xFFF9A825)},
    {'label': 'Rest',     'color': const Color(0xFFBDBDBD)},
  ];

  // ── Helpers ─────────────────────────────────────────────────
  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';

  Map<String, dynamic>? _recFor(DateTime dt) => widget.data[_dateKey(dt)];
  String _statusFor(DateTime dt) => _recFor(dt)?['status'] as String? ?? '';

  Color _statusColor(String s) {
    switch (s) {
      case 'Present':       return const Color(0xFF388E3C);
      case 'Late':          return orange;
      case 'Absent':        return const Color(0xFFE53935);
      case 'On Leave':      return steelBlue;
      case 'Pending Leave': return const Color(0xFFF9A825);
      default:              return const Color(0xFFBDBDBD);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Present':       return Icons.check_circle_rounded;
      case 'Late':          return Icons.watch_later_rounded;
      case 'Absent':        return Icons.cancel_rounded;
      case 'On Leave':      return Icons.beach_access_rounded;
      case 'Pending Leave': return Icons.access_time_rounded;
      default:              return Icons.brightness_3_rounded;
    }
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  void _prev() => setState(() {
    if (_month == 1) { _month = 12; _year--; } else { _month--; }
    widget.onMonthChanged?.call(_month, _year);
  });

  void _next() => setState(() {
    if (_month == 12) { _month = 1; _year++; } else { _month++; }
    widget.onMonthChanged?.call(_month, _year);
  });

  // ── Day detail bottom sheet ──────────────────────────────────
  void _showDayDetail(DateTime dt) {
    final rec       = _recFor(dt);
    final isWeekend = dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday;
    final dbStatus  = rec?['status'] as String? ?? '';
    final status    = dbStatus.isNotEmpty ? dbStatus : isWeekend ? 'Rest Day' : '';
    final timeIn    = rec?['timeIn']  as String? ?? '';
    final timeOut   = rec?['timeOut'] as String? ?? '';
    final hours     = rec?['hours']   as String? ?? '';
    final color     = status.isNotEmpty
        ? _statusColor(status)
        : const Color(0xFFBDBDBD);
    final label = '${_shortMonths[dt.month - 1]} ${dt.day}, ${dt.year}';

    widget.onDaySelected(dt);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: MediaQuery.of(ctx).viewInsets,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Date + badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        status.isNotEmpty
                            ? _statusIcon(status)
                            : Icons.calendar_today_rounded,
                        color: color, size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: navyBlue)),
                    ),
                  ]),
                ),
                if (status.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(status,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 16),

            if (status.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(children: [
                  Icon(Icons.event_busy_rounded,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text('No attendance record for this day.',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF9E9E9E))),
                ]),
              )
            else if (status == 'Rest Day')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(children: [
                  Icon(Icons.weekend_rounded,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text('Weekend — rest day, no work required.',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF9E9E9E))),
                ]),
              )
            else ...[
                if (timeIn.isNotEmpty) ...[
                  _SheetTimeRow(
                    icon: Icons.login_rounded,
                    label: 'Time In',
                    value: timeIn,
                    color: const Color(0xFF388E3C),
                  ),
                  const SizedBox(height: 10),
                ],
                if (timeOut.isNotEmpty) ...[
                  _SheetTimeRow(
                    icon: Icons.logout_rounded,
                    label: 'Time Out',
                    value: timeOut,
                    color: const Color(0xFFE53935),
                  ),
                  const SizedBox(height: 10),
                ],
                if (hours.isNotEmpty)
                  _SheetTimeRow(
                    icon: Icons.schedule_rounded,
                    label: 'Hours Worked',
                    value: hours,
                    color: navyBlue,
                  ),
                if (timeIn.isEmpty && timeOut.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      status == 'Absent'
                          ? 'No time records — marked as Absent.'
                          : 'Leave day — no clock in required.',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF9E9E9E)),
                    ),
                  ),
              ],
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Compute month grid parameters once
    final first       = DateTime(_year, _month, 1);
    final days        = DateTime(_year, _month + 1, 0).day;
    final startOffset = first.weekday % 7; // 0=Sun
    final rows        = ((startOffset + days) / 7).ceil();

    return LayoutBuilder(builder: (context, constraints) {
      // Raise threshold to account for the ~44px gradient header added above the grid
      final isConstrained = constraints.maxHeight < 420;
      final headerFontSize = isConstrained ? 13.0 : 15.0;
      final dayFontSize    = isConstrained ? 10.0 : 12.0;
      final legendFontSize = isConstrained ? 9.0  : 10.0;
      final hPad           = isConstrained ? 6.0  : 12.0;
      final vPad           = isConstrained ? 2.0  : 4.0;
      // Hide dot indicator whenever space is tight — it adds 6px per row × up to 6 rows
      final showDot        = constraints.maxHeight >= 480;

      return Padding(
        padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Section header — matches Attendance History ─────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [navyBlue, steelBlue],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_month_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                const Text(
                  'Attendance Calendar',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_months[_month - 1]} $_year',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ]),
            ),

            SizedBox(height: vPad),

            // ── Month nav header ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: _prev,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.chevron_left,
                        color: navyBlue, size: 22),
                  ),
                ),
                Text('${_months[_month - 1]} $_year',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                        color: navyBlue)),
                InkWell(
                  onTap: _next,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.chevron_right,
                        color: navyBlue, size: 22),
                  ),
                ),
              ],
            ),

            SizedBox(height: vPad),

            // ── Legend strip ────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _legend.map((e) {
                  final label = e['label'] as String;
                  final color = e['color'] as Color;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(label,
                          style: TextStyle(
                              fontSize: legendFontSize,
                              color: const Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w500)),
                    ]),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: vPad),

            // ── Weekday row ─────────────────────────────────────
            Row(
              children: List.generate(7, (i) {
                final isWeekendCol = i == 0 || i == 6;
                return Expanded(
                  child: Center(
                    child: Text(_weekLabels[i],
                        style: TextStyle(
                            fontSize: legendFontSize,
                            fontWeight: FontWeight.w700,
                            color: isWeekendCol
                                ? const Color(0xFFBDBDBD)
                                : steelBlue)),
                  ),
                );
              }),
            ),

            SizedBox(height: vPad / 2),

            // ── Grid — fills all remaining space ────────────────
            Expanded(
              child: Column(
                children: List.generate(rows, (r) => Expanded(
                  child: Row(
                    children: List.generate(7, (c) {
                      final idx = r * 7 + c;
                      final d   = idx - startOffset + 1;

                      if (d < 1 || d > days) {
                        return const Expanded(child: SizedBox.shrink());
                      }

                      final dt         = DateTime(_year, _month, d);
                      final dbStatus   = _statusFor(dt);
                      // c==0 → Sun, c==6 → Sat; treat as Rest if no DB record
                      final isWeekend  = c == 0 || c == 6;
                      final status     = dbStatus.isNotEmpty
                          ? dbStatus
                          : isWeekend ? 'Rest Day' : '';
                      final color      = _statusColor(status);
                      final isToday    = _isToday(dt);
                      final hasRecord  = status.isNotEmpty;
                      final isRestDay  = status == 'Rest Day';

                      return Expanded(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showDayDetail(dt),
                              borderRadius: BorderRadius.circular(
                                  isConstrained ? 6 : 8),
                              hoverColor: isToday
                                  ? Colors.white.withOpacity(0.15)
                                  : hasRecord
                                  ? color.withOpacity(0.25)
                                  : navyBlue.withOpacity(0.06),
                              splashColor: isToday
                                  ? Colors.white.withOpacity(0.2)
                                  : color.withOpacity(0.3),
                              highlightColor: Colors.transparent,
                              child: Container(
                                margin: EdgeInsets.all(
                                    isConstrained ? 1.5 : 2.5),
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? navyBlue
                                      : isRestDay
                                      ? const Color(0xFFBDBDBD).withOpacity(0.12)
                                      : hasRecord
                                      ? color.withOpacity(0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                      isConstrained ? 6 : 8),
                                  border: isToday
                                      ? null
                                      : isRestDay
                                      ? Border.all(
                                      color: const Color(0xFFBDBDBD).withOpacity(0.25),
                                      width: 1)
                                      : hasRecord
                                      ? Border.all(
                                      color: color.withOpacity(0.3),
                                      width: 1)
                                      : null,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('$d',
                                          style: TextStyle(
                                              fontSize: dayFontSize,
                                              fontWeight: isToday
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: isToday
                                                  ? Colors.white
                                                  : isRestDay
                                                  ? const Color(0xFFBDBDBD)
                                                  : hasRecord
                                                  ? color
                                                  : navyBlue)),
                                      if (hasRecord && showDot)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Container(
                                            width: 4, height: 4,
                                            decoration: BoxDecoration(
                                              color: isToday
                                                  ? Colors.white.withOpacity(0.7)
                                                  : color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                )),
              ),
            ),

          ],
        ),
      );
    });
  }
}

// ── Bottom sheet time row ─────────────────────────────────────
class _SheetTimeRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;

  static const navyBlue = Color(0xFF2B457B);

  const _SheetTimeRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF9E9E9E))),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: navyBlue)),
      ]),
    );
  }
}