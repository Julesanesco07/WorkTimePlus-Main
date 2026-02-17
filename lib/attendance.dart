import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────
class AttendanceRecord {
  final DateTime date;
  final String   timeIn;
  final String   timeOut;
  final String   hours;
  final String   status; // Present | Late | Absent | Rest Day | Holiday | On Leave

  const AttendanceRecord({
    required this.date,
    required this.timeIn,
    required this.timeOut,
    required this.hours,
    required this.status,
  });
}

// ─────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────
class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with SingleTickerProviderStateMixin {

  // ── Colors ────────────────────────────────────────────────
  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);
  static const softGray  = Color(0xFFF2F2F2);
  static const white     = Color(0xFFFFFFFF);

  late TabController _tabController;

  // ── Month/year ────────────────────────────────────────────
  int _month = DateTime.now().month;
  int _year  = DateTime.now().year;

  // ── Selected day on calendar ──────────────────────────────
  DateTime? _selectedDay;

  // ── Month/day labels ─────────────────────────────────────
  static const _months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];
  static const _shortMonths = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];
  static const _weekLabels = ['SUN','MON','TUE','WED','THU','FRI','SAT'];

  // ── Sample attendance data ────────────────────────────────
  late final Map<String, AttendanceRecord> _data = _buildData();

  Map<String, AttendanceRecord> _buildData() {
    final m = <String, AttendanceRecord>{};
    final now = DateTime.now();
    final y = now.year;
    final mo = now.month;

    void add(int yr, int mn, int d, String status,
        {String ti = '—', String to = '—', String h = '—'}) {
      final dt  = DateTime(yr, mn, d);
      m[_fmt(dt)] = AttendanceRecord(date: dt, timeIn: ti, timeOut: to, hours: h, status: status);
    }

    // Current month
    add(y, mo,  1, 'Rest Day');
    add(y, mo,  2, 'Rest Day');
    add(y, mo,  3, 'Present', ti: '08:10 AM', to: '06:30 PM', h: '10h 20m');
    add(y, mo,  4, 'Present', ti: '08:00 AM', to: '05:05 PM', h: '9h 05m');
    add(y, mo,  5, 'Absent');
    add(y, mo,  6, 'Late',    ti: '09:15 AM', to: '05:00 PM', h: '7h 45m');
    add(y, mo,  7, 'Present', ti: '08:30 AM', to: '05:00 PM', h: '8h 30m');
    add(y, mo,  8, 'Rest Day');
    add(y, mo,  9, 'Rest Day');
    add(y, mo, 10, 'Present', ti: '08:02 AM', to: '05:14 PM', h: '9h 12m');
    add(y, mo, 11, 'Present', ti: '07:58 AM', to: '05:00 PM', h: '9h 02m');
    add(y, mo, 12, 'Late',    ti: '09:40 AM', to: '06:00 PM', h: '8h 20m');
    add(y, mo, 13, 'Present', ti: '08:05 AM', to: '05:10 PM', h: '9h 05m');

    // Previous month
    final pm = mo == 1 ? 12 : mo - 1;
    final py = mo == 1 ? y - 1 : y;
    add(py, pm,  1, 'Present', ti: '08:05 AM', to: '05:10 PM', h: '9h 05m');
    add(py, pm,  2, 'Present', ti: '08:00 AM', to: '05:00 PM', h: '9h 00m');
    add(py, pm,  3, 'Rest Day');
    add(py, pm,  4, 'Rest Day');
    add(py, pm,  5, 'Present', ti: '08:15 AM', to: '05:20 PM', h: '9h 05m');
    add(py, pm,  6, 'Late',    ti: '09:05 AM', to: '05:30 PM', h: '8h 25m');
    add(py, pm,  7, 'Present', ti: '07:55 AM', to: '05:00 PM', h: '9h 05m');
    add(py, pm,  8, 'Absent');
    add(py, pm,  9, 'Present', ti: '08:00 AM', to: '05:15 PM', h: '9h 15m');
    add(py, pm, 10, 'Holiday');
    add(py, pm, 11, 'Rest Day');
    add(py, pm, 12, 'Rest Day');
    add(py, pm, 13, 'Present', ti: '08:10 AM', to: '05:00 PM', h: '8h 50m');
    add(py, pm, 14, 'Present', ti: '08:00 AM', to: '05:00 PM', h: '9h 00m');
    add(py, pm, 15, 'Present', ti: '08:20 AM', to: '05:45 PM', h: '9h 25m');
    add(py, pm, 16, 'On Leave');
    add(py, pm, 17, 'On Leave');
    add(py, pm, 18, 'Rest Day');
    add(py, pm, 19, 'Rest Day');
    add(py, pm, 20, 'Present', ti: '08:00 AM', to: '05:00 PM', h: '9h 00m');
    add(py, pm, 21, 'Present', ti: '08:05 AM', to: '06:10 PM', h: '10h 05m');
    add(py, pm, 22, 'Present', ti: '08:00 AM', to: '05:00 PM', h: '9h 00m');
    add(py, pm, 23, 'Absent');
    add(py, pm, 24, 'Present', ti: '08:10 AM', to: '05:05 PM', h: '8h 55m');
    add(py, pm, 25, 'Rest Day');
    add(py, pm, 26, 'Rest Day');
    add(py, pm, 27, 'Present', ti: '08:00 AM', to: '05:00 PM', h: '9h 00m');
    add(py, pm, 28, 'Present', ti: '08:15 AM', to: '05:20 PM', h: '9h 05m');
    add(py, pm, 29, 'Late',    ti: '09:20 AM', to: '06:00 PM', h: '8h 40m');
    add(py, pm, 30, 'Present', ti: '08:00 AM', to: '05:00 PM', h: '9h 00m');
    add(py, pm, 31, 'Present', ti: '08:05 AM', to: '05:15 PM', h: '9h 10m');
    return m;
  }

  // ── Key / lookup helpers ──────────────────────────────────
  static String _fmt(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';

  AttendanceRecord? _recFor(DateTime dt) => _data[_fmt(dt)];
  String _statusFor(DateTime dt)         => _recFor(dt)?.status ?? '';

  // ── Status colour / icon ──────────────────────────────────
  Color _statusColor(String s) {
    switch (s) {
      case 'Present':  return const Color(0xFF388E3C);
      case 'Late':     return orange;
      case 'Absent':   return const Color(0xFFE53935);
      case 'On Leave': return steelBlue;
      case 'Holiday':  return const Color(0xFF8E24AA);
      default:         return const Color(0xFFBDBDBD);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Present':  return Icons.check_circle_rounded;
      case 'Late':     return Icons.watch_later_rounded;
      case 'Absent':   return Icons.cancel_rounded;
      case 'On Leave': return Icons.beach_access_rounded;
      case 'Holiday':  return Icons.celebration_rounded;
      default:         return Icons.remove_circle_outline_rounded;
    }
  }

  // ── Month stats ───────────────────────────────────────────
  Map<String, int> get _stats {
    final days = DateTime(_year, _month + 1, 0).day;
    int p = 0, l = 0, a = 0, lv = 0;
    for (int d = 1; d <= days; d++) {
      final s = _statusFor(DateTime(_year, _month, d));
      if (s == 'Present')  p++;
      if (s == 'Late')     l++;
      if (s == 'Absent')   a++;
      if (s == 'On Leave') lv++;
    }
    return {'p': p, 'l': l, 'a': a, 'lv': lv};
  }

  // ── Records for list view ─────────────────────────────────
  List<AttendanceRecord> get _listRecords {
    final days = DateTime(_year, _month + 1, 0).day;
    final out  = <AttendanceRecord>[];
    for (int d = days; d >= 1; d--) {
      final rec = _recFor(DateTime(_year, _month, d));
      if (rec != null) out.add(rec);
    }
    return out;
  }

  // ── Month navigation ──────────────────────────────────────
  void _prev() => setState(() {
    if (_month == 1) { _month = 12; _year--; } else _month--;
    _selectedDay = null;
  });

  void _next() => setState(() {
    if (_month == 12) { _month = 1; _year++; } else _month++;
    _selectedDay = null;
  });

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        title: const Text('Attendance',
            style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: orange,
          indicatorWeight: 3,
          labelColor: navyBlue,
          unselectedLabelColor: const Color(0xFF9E9E9E),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.list_alt_rounded, size: 18), text: 'List'),
            Tab(icon: Icon(Icons.calendar_month_rounded, size: 18), text: 'Calendar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildListTab(), _buildCalendarTab()],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // LIST TAB
  // ══════════════════════════════════════════════════════════
  Widget _buildListTab() {
    final st  = _stats;
    final rec = _listRecords;
    return Column(children: [
      _buildBanner(st),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: const [
          Expanded(flex: 2, child: _ColHead('Date')),
          Expanded(flex: 2, child: _ColHead('Time In')),
          Expanded(flex: 2, child: _ColHead('Time Out')),
          Expanded(flex: 2, child: _ColHead('Hours')),
          Expanded(flex: 2, child: _ColHead('Status')),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFF2F2F2)),
      Expanded(
        child: rec.isEmpty
            ? const Center(child: Text('No records', style: TextStyle(color: Color(0xFF9E9E9E))))
            : ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: rec.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (_, i) => _buildListRow(rec[i]),
        ),
      ),
    ]);
  }

  Widget _buildBanner(Map<String, int> st) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [navyBlue, steelBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: navyBlue.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _NavBtn(icon: Icons.chevron_left_rounded,  onTap: _prev),
          Text('${_months[_month - 1]} $_year',
              style: const TextStyle(color: white, fontWeight: FontWeight.bold, fontSize: 16)),
          _NavBtn(icon: Icons.chevron_right_rounded, onTap: _next),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _StatTile(label: 'Present',  value: '${st['p']}',  color: const Color(0xFF69F0AE)),
          _StatTile(label: 'Late',     value: '${st['l']}',  color: Colors.amberAccent),
          _StatTile(label: 'Absent',   value: '${st['a']}',  color: Colors.redAccent.shade100),
          _StatTile(label: 'On Leave', value: '${st['lv']}', color: Colors.lightBlueAccent),
        ]),
      ]),
    );
  }

  Widget _buildListRow(AttendanceRecord rec) {
    final s    = rec.status;
    final rest = s == 'Rest Day';
    final c    = _statusColor(s);
    final day  = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][rec.date.weekday - 1];
    final date = '${_shortMonths[rec.date.month - 1]} ${rec.date.day}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: rest ? softGray.withOpacity(0.5) : white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rest ? Colors.transparent : c.withOpacity(0.15)),
      ),
      child: Row(children: [
        Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: rest ? Colors.grey : navyBlue)),
          Text(day, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
        ])),
        Expanded(flex: 2, child: Text(rec.timeIn,  style: TextStyle(fontSize: 12, color: rest ? Colors.grey : steelBlue))),
        Expanded(flex: 2, child: Text(rec.timeOut, style: TextStyle(fontSize: 12, color: rest ? Colors.grey : steelBlue))),
        Expanded(flex: 2, child: Text(rec.hours,   style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: rest ? Colors.grey : navyBlue))),
        Expanded(flex: 2, child: Row(children: [
          Icon(_statusIcon(s), size: 13, color: c),
          const SizedBox(width: 3),
          Flexible(child: Text(s, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.w600))),
        ])),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════
  // CALENDAR TAB
  // ══════════════════════════════════════════════════════════
  Widget _buildCalendarTab() {
    return Column(children: [
      _buildCalHeader(),
      _buildLegend(),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          child: Column(children: [
            _buildWeekDayRow(),
            const SizedBox(height: 4),
            _buildGrid(),
            if (_selectedDay != null) ...[
              const SizedBox(height: 12),
              _buildDayCard(_selectedDay!),
            ],
          ]),
        ),
      ),
    ]);
  }

  // Calendar top nav bar
  Widget _buildCalHeader() {
    final st = _stats;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [navyBlue, steelBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: navyBlue.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _NavBtn(icon: Icons.chevron_left_rounded,  onTap: _prev),
        Column(children: [
          Text('${_months[_month - 1]} $_year',
              style: const TextStyle(color: white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 3),
          Text('${st['p']} present  ·  ${st['a']} absent  ·  ${st['l']} late',
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ]),
        _NavBtn(icon: Icons.chevron_right_rounded, onTap: _next),
      ]),
    );
  }

  // Legend strip
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _Dot(color: const Color(0xFF388E3C), label: 'Present'),
          _Dot(color: orange,                  label: 'Late'),
          _Dot(color: const Color(0xFFE53935), label: 'Absent'),
          _Dot(color: steelBlue,               label: 'On Leave'),
          _Dot(color: const Color(0xFF8E24AA), label: 'Holiday'),
          _Dot(color: const Color(0xFFBDBDBD), label: 'Rest Day'),
        ].expand((w) => [w, const SizedBox(width: 14)]).toList()..removeLast()),
      ),
    );
  }

  // Sun Mon Tue … header row
  Widget _buildWeekDayRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: _weekLabels.map((d) {
          final isWeekend = d == 'SUN' || d == 'SAT';
          return Expanded(child: Center(child: Text(d,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: isWeekend ? steelBlue.withOpacity(0.45) : steelBlue))));
        }).toList(),
      ),
    );
  }

  // Full calendar grid
  Widget _buildGrid() {
    final firstDay    = DateTime(_year, _month, 1);
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final startOffset = firstDay.weekday % 7; // 0 = Sunday
    final totalCells  = startOffset + daysInMonth;
    final rows        = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            children: List.generate(7, (col) {
              final idx = row * 7 + col;
              final d   = idx - startOffset + 1;

              if (d < 1 || d > daysInMonth) {
                // Empty cell (leading/trailing)
                return Expanded(child: Container(
                  height: 52,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: softGray.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ));
              }

              final dt       = DateTime(_year, _month, d);
              final status   = _statusFor(dt);
              final isToday  = _isToday(dt);
              final isSel    = _selectedDay != null && _isSameDay(_selectedDay!, dt);
              final isRest   = status == 'Rest Day' || status.isEmpty;
              final statCol  = isRest ? const Color(0xFFBDBDBD) : _statusColor(status);

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedDay = isSel ? null : dt;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 52,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSel
                          ? navyBlue
                          : isToday
                          ? orange.withOpacity(0.12)
                          : isRest
                          ? softGray.withOpacity(0.5)
                          : statCol.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel
                            ? navyBlue
                            : isToday
                            ? orange
                            : Colors.transparent,
                        width: 1.8,
                      ),
                      boxShadow: isSel
                          ? [BoxShadow(color: navyBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        isToday && !isSel
                            ? Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(color: orange, shape: BoxShape.circle),
                          child: Center(child: Text('$d',
                              style: const TextStyle(color: white, fontSize: 12, fontWeight: FontWeight.bold))),
                        )
                            : Text('$d', style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSel ? white : navyBlue,
                        )),
                        const SizedBox(height: 3),
                        // Status dot
                        Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSel
                                ? Colors.white54
                                : isRest
                                ? Colors.transparent
                                : statCol,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  // Day detail card shown below grid
  Widget _buildDayCard(DateTime dt) {
    final rec    = _recFor(dt);
    final status = rec?.status ?? 'No Record';
    final color  = status == 'No Record' ? const Color(0xFF9E9E9E) : _statusColor(status);
    const longDays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const longMons = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    final isWork  = rec != null && status != 'Rest Day' && status != 'Holiday' && status != 'On Leave';
    final isEmpty = rec == null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.10), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
            child: Icon(
              isEmpty ? Icons.help_outline_rounded : _statusIcon(status),
              color: color, size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${longDays[dt.weekday - 1]}, ${longMons[dt.month - 1]} ${dt.day}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: navyBlue)),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
              child: Text(
                isEmpty ? 'No Record' : status,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ])),
          GestureDetector(
            onTap: () => setState(() => _selectedDay = null),
            child: const Icon(Icons.close_rounded, color: Color(0xFFBDBDBD), size: 20),
          ),
        ]),
        // Time / hours tiles for working days
        if (isWork) ...[
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF2F2F2)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _InfoTile(label: 'Time In',  value: rec!.timeIn,  icon: Icons.login_rounded,  color: const Color(0xFF388E3C))),
            const SizedBox(width: 10),
            Expanded(child: _InfoTile(label: 'Time Out', value: rec.timeOut, icon: Icons.logout_rounded, color: navyBlue)),
            const SizedBox(width: 10),
            Expanded(child: _InfoTile(label: 'Hours',    value: rec.hours,   icon: Icons.timer_rounded,  color: steelBlue)),
          ]),
        ],
        // Message for non-work days
        if (!isWork && !isEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(
              status == 'Rest Day'  ? '😴  Weekend — no work scheduled'
                  : status == 'Holiday' ? '🎉  Public Holiday'
                  : '🏖️  On Approved Leave',
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600),
            )),
          ),
        ],
      ]),
    );
  }

  // ── Utils ─────────────────────────────────────────────────
  bool _isToday(DateTime dt) {
    final n = DateTime.now();
    return dt.year == n.year && dt.month == n.month && dt.day == n.day;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────
class _ColHead extends StatelessWidget {
  final String text;
  const _ColHead(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600));
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _StatTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
    ]));
  }
}

class _Dot extends StatelessWidget {
  final Color  color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF4A698F), fontWeight: FontWeight.w500)),
    ]);
  }
}

class _InfoTile extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  const _InfoTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
      ]),
    );
  }
}