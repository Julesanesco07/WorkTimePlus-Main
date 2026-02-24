import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:worktime/cards/attendance/attendance_calendar.dart';
import 'package:worktime/cards/attendance/attendance_history.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  static const navyBlue = Color(0xFF2B457B);
  static const white    = Color(0xFFFFFFFF);

  final Map<String, AttendanceRecord> _data = AttendanceRecord.buildSampleData();

  int _month = DateTime.now().month;
  int _year  = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        title: const Text(
          'Attendance',
          style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: isLandscape
            ? _buildLandscape()
            : _buildPortrait(),
      ),
    );
  }

  // ── Portrait: stacked ─────────────────────────────────────
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

  // ── Landscape: side by side ───────────────────────────────
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