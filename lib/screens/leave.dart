import 'package:flutter/material.dart';
import 'package:worktime/cards/leave/leave_balance.dart';
import 'package:worktime/cards/leave/leave_form.dart';
import 'package:worktime/cards/leave/leave_history.dart';
import 'package:worktime/services/local_db.dart';
import 'package:worktime/app_state.dart';

class LeaveRequestPage extends StatefulWidget {
  const LeaveRequestPage({super.key});

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> {
  static const navyBlue = Color(0xFF2B457B);

  int _refreshTrigger = 0;

  // ── Format helpers ────────────────────────────────────────
  String _fmt(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')}';

  // ── Called by LeaveForm on submit ─────────────────────────
  Future<void> _onSubmit(
      String type, DateTime start, DateTime end, String reason) async {
    final userId   = AppState().userId;
    final now      = DateTime.now();
    final id       = now.millisecondsSinceEpoch.toString();
    final days     = end.difference(start).inDays + 1;
    final datesStr = start == end
        ? _fmt(start)
        : '${_fmt(start)} – ${_fmt(end)}';

    // saveLeaveWithAttendance saves the leave record AND marks
    // each weekday in the range as 'Pending Leave' in attendance
    await LocalDB.saveLeaveWithAttendance(
      userId: userId,
      leave: {
        'id':        id,
        'userId':    userId,
        'type':      type,
        'startDate': _dateKey(start),
        'endDate':   _dateKey(end),
        'days':      days,
        'dates':     datesStr,
        'appliedOn': _fmt(now),
        'reason':    reason,
        'status':    'Pending',
        'createdAt': now.toIso8601String(),
      },
    );

    if (mounted) {
      setState(() => _refreshTrigger++);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Leave request submitted successfully!'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            floating: true,
            snap: true,
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: const Text(
              'Leave Request',
              style: TextStyle(
                  color: navyBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const LeaveBalance(),
                const SizedBox(height: 20),
                LeaveForm(onSubmit: _onSubmit),
                const SizedBox(height: 24),
                LeaveHistory(refreshTrigger: _refreshTrigger),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}