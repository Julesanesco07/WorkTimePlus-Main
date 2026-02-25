import 'package:flutter/material.dart';
import 'package:worktime/services/local_db.dart';

class LeaveHistory extends StatefulWidget {
  final List<Map<String, dynamic>> pending;
  final List<Map<String, dynamic>> history;
  final int refreshTrigger;

  const LeaveHistory({
    super.key,
    required this.pending,
    required this.history,
    this.refreshTrigger = 0,
  });

  @override
  State<LeaveHistory> createState() => _LeaveHistoryState();
}

class _LeaveHistoryState extends State<LeaveHistory> {
  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);
  static const softGray  = Color(0xFFF2F2F2);

  // ── Yellow palette for pending ────────────────────────────
  static const yellowBg     = Color(0xFFFFFBEB);
  static const yellowBorder = Color(0xFFFFE082);
  static const yellowDeep   = Color(0xFFF9A825);

  // ── LocalDB-backed lists ──────────────────────────────────
  late List<Map<String, dynamic>> _pending;
  late List<Map<String, dynamic>> _history;

  // ── History filter ────────────────────────────────────────
  String _filter = 'All';
  static const _filters = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    // Start with whatever the parent passed in
    _pending = List.from(widget.pending);
    _history = List.from(widget.history);
    _loadFromDb();
  }

  @override
  void didUpdateWidget(LeaveHistory old) {
    super.didUpdateWidget(old);
    // Reload when parent signals a new submission
    if (old.refreshTrigger != widget.refreshTrigger) _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final all = await LocalDB.getLeaves();
    if (!mounted) return;
    setState(() {
      _pending = all.where((l) => l['status'] == 'Pending').toList();
      _history = all.where((l) => l['status'] != 'Pending').toList()
        ..sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    });
  }

  List<Map<String, dynamic>> get _filteredHistory {
    if (_filter == 'All') return _history;
    return _history.where((h) => h['status'] == _filter).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved': return Colors.green.shade600;
      case 'Rejected': return Colors.red.shade400;
      default:         return yellowDeep;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPendingSection(),
        const SizedBox(height: 20),
        _buildHistorySection(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // PENDING SECTION
  // ─────────────────────────────────────────────────────────
  Widget _buildPendingSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: softGray, width: 1.5),
      ),
      child: Column(
        children: [
          // ── Yellow header ─────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: yellowBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: yellowBorder.withOpacity(0.5))),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: navyBlue.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.access_time_rounded, color: navyBlue, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text(
                    'Pending Requests',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: navyBlue,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Awaiting approval',
                    style: TextStyle(fontSize: 11, color: navyBlue.withOpacity(0.5)),
                  ),
                ]),
              ),
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: navyBlue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${_pending.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ]),
          ),

          // ── Pending cards ─────────────────────────────────
          if (_pending.isEmpty)
            _emptyState('No pending leave requests')
          else
            ..._pending.map((item) => _buildPendingCard(item)),
        ],
      ),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: softGray, width: 1)),
      ),
      child: Row(children: [
        // Left: type + dates + reason
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(
                item['type'],
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: navyBlue),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: yellowDeep.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${item['days']}d',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: yellowDeep),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Text(item['dates'], style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
            if ((item['reason'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                item['reason'],
                style: TextStyle(fontSize: 11, color: steelBlue.withOpacity(0.7)),
              ),
            ],
          ]),
        ),
        // Right: awaiting approval badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: yellowBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: yellowBorder, width: 1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.access_time_rounded, size: 12, color: yellowDeep),
            const SizedBox(width: 5),
            Text(
              'Awaiting Approval',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: yellowDeep),
            ),
          ]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // HISTORY SECTION
  // ─────────────────────────────────────────────────────────
  Widget _buildHistorySection() {
    final filtered = _filteredHistory;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: softGray, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: steelBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_rounded, color: steelBlue, size: 18),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  'Leave History',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: navyBlue),
                ),
                const SizedBox(height: 1),
                Text(
                  'All your leave requests',
                  style: TextStyle(fontSize: 11, color: steelBlue.withOpacity(0.6)),
                ),
              ]),
            ]),
          ),

          // ── Filter chips row ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final isSelected = _filter == f;
                  Color chipColor;
                  switch (f) {
                    case 'Pending':  chipColor = yellowDeep; break;
                    case 'Approved': chipColor = Colors.green.shade600; break;
                    case 'Rejected': chipColor = Colors.red.shade400; break;
                    default:         chipColor = orange;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? chipColor : softGray,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: isSelected ? Colors.white : steelBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF2F2F2)),

          // ── Table ─────────────────────────────────────────
          if (filtered.isEmpty)
            _emptyState('No ${_filter == 'All' ? '' : '$_filter '}records found')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 72,
                columnSpacing: 20,
                headingTextStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9E9E9E),
                  letterSpacing: 0.5,
                ),
                columns: const [
                  DataColumn(label: Text('TYPE')),
                  DataColumn(label: Text('DURATION')),
                  DataColumn(label: Text('DAYS')),
                  DataColumn(label: Text('REASON')),
                  DataColumn(label: Text('APPLIED ON')),
                  DataColumn(label: Text('STATUS')),
                ],
                rows: filtered.map((item) {
                  final status      = item['status'] as String;
                  final statusColor = _statusColor(status);
                  return DataRow(cells: [
                    // TYPE
                    DataCell(SizedBox(
                      width: 90,
                      child: Text(
                        item['type'],
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: navyBlue),
                      ),
                    )),
                    // DURATION
                    DataCell(SizedBox(
                      width: 110,
                      child: Text(
                        item['dates'],
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    )),
                    // DAYS
                    DataCell(Text(
                      '${item['days']}d',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: orange),
                    )),
                    // REASON
                    DataCell(SizedBox(
                      width: 80,
                      child: Text(
                        (item['reason'] ?? '—').toString(),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    // APPLIED ON
                    DataCell(SizedBox(
                      width: 90,
                      child: Text(
                        item['appliedOn'] ?? '—',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    )),
                    // STATUS
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          status == 'Approved'
                              ? Icons.check_circle_rounded
                              : status == 'Rejected'
                              ? Icons.cancel_rounded
                              : Icons.access_time_rounded,
                          size: 12,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                        ),
                      ]),
                    )),
                  ]);
                }).toList(),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: steelBlue.withOpacity(0.5), fontSize: 13),
        ),
      ),
    );
  }
}