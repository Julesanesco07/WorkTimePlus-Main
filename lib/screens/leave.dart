import 'package:flutter/material.dart';
import 'package:worktime/cards/leave/leave_balance.dart';
import 'package:worktime/cards/leave/leave_form.dart';
import 'package:worktime/cards/leave/leave_history.dart';

class LeaveRequestPage extends StatefulWidget {
  const LeaveRequestPage({super.key});

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> {
  static const navyBlue  = Color(0xFF2B457B);
  static const steelBlue = Color(0xFF4A698F);

  // ── Data ──────────────────────────────────────────────────
  final List<Map<String, dynamic>> _pending = [
    {'type': 'Vacation Leave', 'dates': 'Oct 14 – Oct 16, 2025', 'days': 3},
    {'type': 'Sick Leave',     'dates': 'Nov 5 – Nov 6, 2025',   'days': 2},
  ];

  final List<Map<String, dynamic>> _history = [
    {'type': 'Sick Leave',     'dates': 'Jan 10 – Jan 11, 2025', 'status': 'Approved', 'days': 2},
    {'type': 'Vacation Leave', 'dates': 'Dec 20 – Dec 22, 2024', 'status': 'Approved', 'days': 3},
    {'type': 'Vacation Leave', 'dates': 'Sep 1 – Sep 3, 2024',   'status': 'Rejected', 'days': 3},
  ];

  // ── On form submit ────────────────────────────────────────
  void _onSubmit(String type, DateTime start, DateTime end, String reason) {
    setState(() {
      _pending.insert(0, {
        'type':  type,
        'dates': '${start.month}/${start.day}/${start.year} – ${end.month}/${end.day}/${end.year}',
        'days':  end.difference(start).inDays + 1,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Leave request submitted successfully!'),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [

          // ── Scrollable App Bar ───────────────────────────
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            floating: true,
            snap: true,
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: const Text(
              'Leave Request',
              style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold),
            ),
          ),

          // ── Page content ─────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                const LeaveBalance(),
                const SizedBox(height: 20),

                LeaveForm(onSubmit: _onSubmit),
                const SizedBox(height: 24),

                LeaveHistory(pending: _pending, history: _history),
                const SizedBox(height: 24),

              ]),
            ),
          ),

        ],
      ),
    );
  }
}