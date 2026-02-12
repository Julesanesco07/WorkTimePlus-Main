import 'package:flutter/material.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);
  static const softGray  = Color(0xFFF2F2F2);

  int _selectedMonth = DateTime.now().month;
  int _selectedYear  = DateTime.now().year;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  // Sample attendance data
  final List<Map<String, dynamic>> _records = [
    {'date': 'Feb 10', 'day': 'Mon', 'timeIn': '08:02 AM', 'timeOut': '05:14 PM', 'hours': '9h 12m', 'status': 'Present'},
    {'date': 'Feb 09', 'day': 'Sun', 'timeIn': '—',        'timeOut': '—',        'hours': '—',      'status': 'Rest Day'},
    {'date': 'Feb 08', 'day': 'Sat', 'timeIn': '—',        'timeOut': '—',        'hours': '—',      'status': 'Rest Day'},
    {'date': 'Feb 07', 'day': 'Fri', 'timeIn': '08:30 AM', 'timeOut': '05:00 PM', 'hours': '8h 30m', 'status': 'Present'},
    {'date': 'Feb 06', 'day': 'Thu', 'timeIn': '09:15 AM', 'timeOut': '05:00 PM', 'hours': '7h 45m', 'status': 'Late'},
    {'date': 'Feb 05', 'day': 'Wed', 'timeIn': '—',        'timeOut': '—',        'hours': '—',      'status': 'Absent'},
    {'date': 'Feb 04', 'day': 'Tue', 'timeIn': '08:00 AM', 'timeOut': '05:05 PM', 'hours': '9h 05m', 'status': 'Present'},
    {'date': 'Feb 03', 'day': 'Mon', 'timeIn': '08:10 AM', 'timeOut': '06:30 PM', 'hours': '10h 20m','status': 'Present'},
    {'date': 'Feb 02', 'day': 'Sun', 'timeIn': '—',        'timeOut': '—',        'hours': '—',      'status': 'Rest Day'},
    {'date': 'Feb 01', 'day': 'Sat', 'timeIn': '—',        'timeOut': '—',        'hours': '—',      'status': 'Rest Day'},
  ];

  Color _statusColor(String status) {
    switch (status) {
      case 'Present':  return Colors.green.shade600;
      case 'Late':     return orange;
      case 'Absent':   return Colors.red.shade400;
      default:         return const Color(0xFFBDBDBD);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Present':  return Icons.check_circle_rounded;
      case 'Late':     return Icons.watch_later_rounded;
      case 'Absent':   return Icons.cancel_rounded;
      default:         return Icons.remove_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Attendance', style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedMonth,
                style: const TextStyle(color: navyBlue, fontWeight: FontWeight.w600, fontSize: 14),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: navyBlue),
                items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(_months[i]))),
                onChanged: (val) => setState(() => _selectedMonth = val!),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummarySection(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Date', style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Time In', style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Time Out', style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Hours', style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF2F2F2)),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) => _buildRecord(_records[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navyBlue, steelBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: navyBlue.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_months[_selectedMonth - 1]} $_selectedYear',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _SummaryTile(label: 'Present', value: '18', color: Colors.greenAccent.shade400),
              _SummaryTile(label: 'Late', value: '2', color: Colors.amberAccent),
              _SummaryTile(label: 'Absent', value: '1', color: Colors.redAccent.shade100),
              _SummaryTile(label: 'Total Hrs', value: '154h', color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecord(Map<String, dynamic> record) {
    final status = record['status'] as String;
    final isRestDay = status == 'Rest Day';
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isRestDay ? softGray.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRestDay ? Colors.transparent : color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record['date'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isRestDay ? Colors.grey : navyBlue)),
                Text(record['day'],  style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(record['timeIn'],  style: TextStyle(fontSize: 12, color: isRestDay ? Colors.grey : steelBlue))),
          Expanded(flex: 2, child: Text(record['timeOut'], style: TextStyle(fontSize: 12, color: isRestDay ? Colors.grey : steelBlue))),
          Expanded(flex: 2, child: Text(record['hours'],   style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isRestDay ? Colors.grey : navyBlue))),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(_statusIcon(status), size: 14, color: color),
                const SizedBox(width: 4),
                Flexible(child: Text(status, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }
}