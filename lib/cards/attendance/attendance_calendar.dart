import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class AttendanceCalendar extends StatefulWidget {
  final Map<String, AttendanceRecord> data;
  final void Function(DateTime) onDaySelected;

  const AttendanceCalendar({
    super.key,
    required this.data,
    required this.onDaySelected,
  });

  @override
  State<AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  // ── Colors ────────────────────────────────────────────────
  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);

  int _month = DateTime.now().month;
  int _year  = DateTime.now().year;
  DateTime? _selectedDay;

  static const _months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];

  static const _weekLabels = ['SUN','MON','TUE','WED','THU','FRI','SAT'];

  // ── Helpers ───────────────────────────────────────────────
  AttendanceRecord? _recFor(DateTime dt) => widget.data[AttendanceRecord.fmt(dt)];
  String _statusFor(DateTime dt) => _recFor(dt)?.status ?? '';

  Color _statusColor(String s) {
    switch (s) {
      case 'Present':  return const Color(0xFF388E3C);
      case 'Late':     return orange;
      case 'Absent':   return const Color(0xFFE53935);
      case 'On Leave': return steelBlue;
      default:         return const Color(0xFFBDBDBD);
    }
  }

  void _prev() {
    setState(() {
      if (_month == 1) { _month = 12; _year--; }
      else _month--;
      _selectedDay = null;
    });
  }

  void _next() {
    setState(() {
      if (_month == 12) { _month = 1; _year++; }
      else _month++;
      _selectedDay = null;
    });
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [navyBlue, steelBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              const Text(
                'Attendance Calendar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          _buildHeader(),
          const SizedBox(height: 8),
          _buildWeekDayRow(),
          const SizedBox(height: 4),
          _buildGrid(),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: _prev, icon: const Icon(Icons.chevron_left, color: navyBlue)),
        Text(
          '${_months[_month - 1]} $_year',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: navyBlue),
        ),
        IconButton(onPressed: _next, icon: const Icon(Icons.chevron_right, color: navyBlue)),
      ],
    );
  }

  Widget _buildWeekDayRow() {
    return Row(
      children: _weekLabels.map((d) => Expanded(
        child: Center(
          child: Text(
            d,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: steelBlue),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildGrid() {
    final first       = DateTime(_year, _month, 1);
    final days        = DateTime(_year, _month + 1, 0).day;
    final startOffset = first.weekday % 7;
    final rows        = ((startOffset + days) / 7).ceil();

    return Column(
      children: List.generate(rows, (r) {
        return Row(
          children: List.generate(7, (c) {
            final idx = r * 7 + c;
            final d   = idx - startOffset + 1;
            if (d < 1 || d > days) {
              return const Expanded(child: SizedBox(height: 40));
            }
            final dt       = DateTime(_year, _month, d);
            final status   = _statusFor(dt);
            final color    = _statusColor(status);
            final isToday  = dt.year == DateTime.now().year &&
                dt.month == DateTime.now().month &&
                dt.day == DateTime.now().day;
            final isSelected = _selectedDay != null &&
                _selectedDay!.year == dt.year &&
                _selectedDay!.month == dt.month &&
                _selectedDay!.day == dt.day;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedDay = dt);
                  widget.onDaySelected(dt);
                },
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.5)
                        : color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: navyBlue, width: 1.5)
                        : isSelected
                        ? Border.all(color: color, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$d',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isToday || isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? color : navyBlue,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildLegend() {
    final items = [
      ('Present',  const Color(0xFF388E3C)),
      ('Late',     orange),
      ('Absent',   const Color(0xFFE53935)),
      ('On Leave', steelBlue),
      ('Rest Day', const Color(0xFFBDBDBD)),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: items.map((e) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: e.$2, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 4),
          Text(e.$1, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
        ],
      )).toList(),
    );
  }
}