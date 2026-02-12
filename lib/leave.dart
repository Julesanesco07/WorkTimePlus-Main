import 'package:flutter/material.dart';

class LeaveRequestPage extends StatefulWidget {
  const LeaveRequestPage({super.key});

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> with SingleTickerProviderStateMixin {
  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);
  static const softGray  = Color(0xFFF2F2F2);

  late TabController _tabController;
  String? _selectedLeaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();

  final List<Map<String, dynamic>> _history = [
    {'type': 'Sick Leave', 'dates': 'Jan 10 – Jan 11, 2025', 'status': 'Approved', 'days': 2},
    {'type': 'Vacation Leave', 'dates': 'Dec 20 – Dec 22, 2024', 'status': 'Approved', 'days': 3},
    {'type': 'Vacation Leave', 'dates': 'Oct 14 – Oct 16, 2024', 'status': 'Pending', 'days': 3},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: navyBlue, secondary: orange),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Select date';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  void _submitRequest() {
    if (_selectedLeaveType == null || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all required fields'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Leave request submitted successfully!'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    setState(() {
      _selectedLeaveType = null;
      _startDate = null;
      _endDate = null;
      _reasonController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Leave Request', style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: orange,
          indicatorWeight: 3,
          labelColor: navyBlue,
          unselectedLabelColor: const Color(0xFF9E9E9E),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'New Request'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewRequestTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ── Leave Balance Summary ─────────────────────────────────
  Widget _buildBalanceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navyBlue, steelBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: navyBlue.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Leave Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              _BalancePill(label: 'Vacation', days: 12),
              const SizedBox(width: 10),
              _BalancePill(label: 'Sick', days: 7),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
    );
  }

  // ── New Request Tab ───────────────────────────────────────
  Widget _buildNewRequestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceSummary(),
          const SizedBox(height: 24),
          _SectionLabel(label: 'Leave Type'),
          const SizedBox(height: 8),
          _buildLeaveTypeSelector(),
          const SizedBox(height: 20),
          _SectionLabel(label: 'Duration'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _DatePickerCard(label: 'From', date: _formatDate(_startDate), onTap: () => _pickDate(true))),
              const SizedBox(width: 12),
              Expanded(child: _DatePickerCard(label: 'To', date: _formatDate(_endDate), onTap: () => _pickDate(false))),
            ],
          ),
          if (_startDate != null && _endDate != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_endDate!.difference(_startDate!).inDays + 1} day(s) requested',
                style: const TextStyle(color: orange, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _SectionLabel(label: 'Reason (optional)'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: softGray,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _reasonController,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, color: navyBlue),
              decoration: const InputDecoration(
                hintText: 'Describe the reason for your leave...',
                hintStyle: TextStyle(color: Color(0xFFBDBDBD)),
                contentPadding: EdgeInsets.all(14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _submitRequest,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: orange,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: orange.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Center(
                child: Text('Submit Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTypeSelector() {
    final types = ['Vacation Leave', 'Sick Leave'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final selected = _selectedLeaveType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedLeaveType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? navyBlue : softGray,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? navyBlue : Colors.transparent),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: selected ? Colors.white : steelBlue,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── History Tab ───────────────────────────────────────────
  Widget _buildHistoryTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final item = _history[i];
        final status = item['status'] as String;
        final statusColor = status == 'Approved'
            ? Colors.green.shade600
            : status == 'Rejected'
            ? Colors.red.shade400
            : orange;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: softGray, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: navyBlue.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Icon(Icons.beach_access_rounded, color: navyBlue, size: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['type'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: navyBlue)),
                    const SizedBox(height: 3),
                    Text(item['dates'], style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                    const SizedBox(height: 3),
                    Text('${item['days']} day(s)', style: const TextStyle(fontSize: 12, color: steelBlue)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BalancePill extends StatelessWidget {
  final String label;
  final int days;
  const _BalancePill({required this.label, required this.days});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text('$days', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  final String label;
  final String date;
  final VoidCallback onTap;

  const _DatePickerCard({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF4A698F)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
                Text(date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2B457B))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4A698F), letterSpacing: 0.3),
    );
  }
}