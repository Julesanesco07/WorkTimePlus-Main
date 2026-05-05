import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/local_db.dart';
import '../cards/attendance/attendance_calendar.dart';
import '../cards/attendance/attendance_history.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => AttendancePageState();
}

class AttendancePageState extends State<AttendancePage>
    with WidgetsBindingObserver {
  static const navyBlue = Color(0xFF2B457B);
  static const white    = Color(0xFFFFFFFF);

  // All attendance records for the current user as plain DB maps
  // Key = "yyyy-MM-dd", Value = the full map from LocalDB
  Map<String, Map<String, dynamic>> _data = {};

  int  _month   = DateTime.now().month;
  int  _year    = DateTime.now().year;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRecords();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Reload whenever the app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadRecords();
  }

  // ── Load all attendance records for this user from LocalDB ───
  /// Called by navigation when switching to Attendance tab
  void refresh() => _loadRecords();

  Future<void> _loadRecords() async {
    final userId  = AppState().userId;
    final records = await LocalDB.getAttendanceByUser(userId);

    final map = <String, Map<String, dynamic>>{};
    for (final r in records) {
      final date = r['date'] as String? ?? '';
      if (date.isNotEmpty) map[date] = r;
    }

    if (mounted) {
      setState(() {
        _data    = map;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: white,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: navyBlue))
          : CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: white,
            elevation: 0,
            floating: true,
            snap: true,
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: const Text(
              'Attendance',
              style: TextStyle(
                  color: navyBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: navyBlue),
                  onPressed: () {
                    setState(() => _loading = true);
                    _loadRecords();
                  },
                ),
              ),
            ],
          ),
          SliverFillRemaining(
            child: SafeArea(
              top: false,
              child: isLandscape ? _buildLandscape() : _buildPortrait(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Portrait: stacked ──────────────────────────────────────
  Widget _buildPortrait() {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: AttendanceCalendar(
            data: _data,
            onDaySelected: (dt) => setState(() {
              _month = dt.month;
              _year  = dt.year;
            }),
            onMonthChanged: (m, y) => setState(() {
              _month = m;
              _year  = y;
            }),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 5,
          child: AttendanceHistory(
            data:  _data,
            month: _month,
            year:  _year,
          ),
        ),
      ],
    );
  }

  // ── Landscape: side by side ────────────────────────────────
  Widget _buildLandscape() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: AttendanceCalendar(
            data: _data,
            onDaySelected: (dt) => setState(() {
              _month = dt.month;
              _year  = dt.year;
            }),
            onMonthChanged: (m, y) => setState(() {
              _month = m;
              _year  = y;
            }),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 5,
          child: AttendanceHistory(
            data:  _data,
            month: _month,
            year:  _year,
          ),
        ),
      ],
    );
  }
}