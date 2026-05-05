import 'package:flutter/material.dart';
import 'package:worktime/services/local_db.dart';
import 'package:worktime/app_state.dart';

class LeaveHistory extends StatefulWidget {
  final List<Map<String, dynamic>> pending;
  final List<Map<String, dynamic>> history;
  final int refreshTrigger;

  const LeaveHistory({
    super.key,
    this.pending  = const [],
    this.history  = const [],
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

  static const yellowBg     = Color(0xFFFFFBEB);
  static const yellowBorder = Color(0xFFFFE082);
  static const yellowDeep   = Color(0xFFF9A825);

  static const _pageSize = 5;

  // ── Data ──────────────────────────────────────────────────
  late List<Map<String, dynamic>> _pending;
  late List<Map<String, dynamic>> _history;

  // ── Pagination state ──────────────────────────────────────
  int _pendingPage = 1;
  int _historyPage = 1;

  // ── History filter ────────────────────────────────────────
  String _filter = 'All';
  static const _filters = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _pending = List.from(widget.pending);
    _history = List.from(widget.history);
    _loadFromDb();
  }

  @override
  void didUpdateWidget(LeaveHistory old) {
    super.didUpdateWidget(old);
    if (old.refreshTrigger != widget.refreshTrigger) _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    final userId = AppState().userId;
    final mine   = await LocalDB.getLeavesByUser(userId);
    if (!mounted) return;
    setState(() {
      // Pending section = quick-view cards for awaiting requests
      _pending = mine.where((l) => l['status'] == 'Pending').toList();
      // History table = ALL records (Pending + Approved + Rejected)
      // sorted newest first so users can see everything they've submitted
      _history = List.from(mine)
        ..sort((a, b) =>
            (b['createdAt'] as String).compareTo(a['createdAt'] as String));
      _pendingPage = 1;
      _historyPage = 1;
    });
  }

  // ── Cancel a leave request ────────────────────────────────
  Future<void> _cancelLeave(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cancel_outlined,
                color: Colors.red.shade400, size: 20),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text('Cancel Leave?',
                style: TextStyle(
                    color: navyBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cancel your ${item['type']} request for ${item['dates']}?',
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF4A698F)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: Colors.red.shade400),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'This will also remove the leave days from your attendance calendar.',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ),
              ]),
            ),
          ],
        ),
        actionsPadding:
        const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(
                      color: Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep It',
                    style: TextStyle(
                        color: Color(0xFF4A698F),
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  padding:
                  const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Cancel Leave',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ],
      ),
    );

    if (confirmed != true) return;

    final userId = AppState().userId;
    // Remove attendance records for the leave days
    await LocalDB.deleteAttendanceRange(
        userId,
        item['startDate'] as String? ?? '',
        item['endDate']   as String? ?? '');
    // Delete the leave record itself
    await LocalDB.deleteLeave(item['id'] as String);
    // Reload
    await _loadFromDb();
  }

  // ── Filtered history ──────────────────────────────────────
  List<Map<String, dynamic>> get _filteredHistory {
    if (_filter == 'All') return _history;
    return _history.where((h) => h['status'] == _filter).toList();
  }

  // ── Page slices ───────────────────────────────────────────
  List<Map<String, dynamic>> _pageOf(
      List<Map<String, dynamic>> list, int page) {
    final start = (page - 1) * _pageSize;
    final end   = (start + _pageSize).clamp(0, list.length);
    if (start >= list.length) return [];
    return list.sublist(start, end);
  }

  int _totalPages(List<Map<String, dynamic>> list) =>
      (list.length / _pageSize).ceil().clamp(1, 9999);

  // ── Color helpers ─────────────────────────────────────────
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
    final totalPages  = _totalPages(_pending);
    final currentPage = _pendingPage.clamp(1, totalPages);
    final pageItems   = _pageOf(_pending, currentPage);

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
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                  bottom:
                  BorderSide(color: yellowBorder.withOpacity(0.5))),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: navyBlue.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.access_time_rounded,
                    color: navyBlue, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pending Requests',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: navyBlue)),
                      const SizedBox(height: 1),
                      Text('Awaiting approval',
                          style: TextStyle(
                              fontSize: 11,
                              color: navyBlue.withOpacity(0.5))),
                    ]),
              ),
              // Total count badge
              Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(
                    color: navyBlue, shape: BoxShape.circle),
                child: Center(
                  child: Text('${_pending.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ),
            ]),
          ),

          // ── Pending cards ─────────────────────────────────
          if (_pending.isEmpty)
            _emptyState('No pending leave requests')
          else ...[
            ...pageItems.map((item) => _buildPendingCard(item)),

            // ── Pagination bar ─────────────────────────────
            if (totalPages > 1)
              _PaginationBar(
                current:    currentPage,
                total:      totalPages,
                itemCount:  _pending.length,
                onPrev: () => setState(() => _pendingPage = currentPage - 1),
                onNext: () => setState(() => _pendingPage = currentPage + 1),
                onPage: (p) => setState(() => _pendingPage = p),
              ),
            if (totalPages <= 1)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border:
          Border(bottom: BorderSide(color: Color(0xFFF2F2F2), width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: type + dates — takes all remaining space
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(item['type'],
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: navyBlue),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: yellowDeep.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${item['days']}d',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: yellowDeep)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(item['dates'],
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9E9E9E)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if ((item['reason'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(item['reason'],
                          style: TextStyle(
                              fontSize: 11,
                              color: steelBlue.withOpacity(0.7)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ]),
            ),
            const SizedBox(width: 12),
            // Right: fixed-width badge so it never shifts left content
            SizedBox(
              width: 106,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: yellowBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: yellowBorder, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: yellowDeep),
                    const SizedBox(width: 5),
                    const Flexible(
                      child: Text('Awaiting',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: yellowDeep),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Detail bottom sheet ───────────────────────────────────
  void _showDetail(Map<String, dynamic> item) {
    final status      = item['status'] as String? ?? '';
    final statusColor = _statusColor(status);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Header row — type + status badge
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text(item['type'] as String? ?? '',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: navyBlue)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: statusColor.withOpacity(0.3), width: 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  status == 'Approved'
                      ? Icons.check_circle_rounded
                      : status == 'Rejected'
                      ? Icons.cancel_rounded
                      : Icons.access_time_rounded,
                  size: 13,
                  color: statusColor,
                ),
                const SizedBox(width: 5),
                Text(status,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ]),
            ),
          ]),
          const SizedBox(height: 20),

          // Info rows
          _DetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Duration',
            value: item['dates'] as String? ?? '—',
          ),
          _DetailRow(
            icon: Icons.hourglass_bottom_rounded,
            label: 'Days',
            value: '${item['days']} day${(item['days'] as int? ?? 1) == 1 ? '' : 's'}',
            valueColor: orange,
          ),
          _DetailRow(
            icon: Icons.edit_calendar_rounded,
            label: 'Applied On',
            value: item['appliedOn'] as String? ?? '—',
          ),
          if ((item['reason'] as String? ?? '').isNotEmpty)
            _DetailRow(
              icon: Icons.notes_rounded,
              label: 'Reason',
              value: item['reason'] as String,
            ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF2F2F2)),
          const SizedBox(height: 16),

          // Cancel button — only for Pending
          if (status == 'Pending')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.cancel_outlined,
                    color: Colors.white, size: 18),
                label: const Text('Cancel Leave Request',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                onPressed: () {
                  Navigator.pop(context);
                  _cancelLeave(item);
                },
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Close',
                    style: TextStyle(
                        color: steelBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
            ),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // HISTORY SECTION
  // ─────────────────────────────────────────────────────────
  Widget _buildHistorySection() {
    final filtered    = _filteredHistory;
    final totalPages  = _totalPages(filtered);
    final currentPage = _historyPage.clamp(1, totalPages);
    final pageItems   = _pageOf(filtered, currentPage);

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
                child: const Icon(Icons.history_rounded,
                    color: steelBlue, size: 18),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Leave History',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: navyBlue)),
                const SizedBox(height: 1),
                Text('Tap a record to view details',
                    style: TextStyle(
                        fontSize: 11,
                        color: steelBlue.withOpacity(0.6))),
              ]),
            ]),
          ),

          // ── Filter chips ──────────────────────────────────
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
                      onTap: () => setState(() {
                        _filter      = f;
                        _historyPage = 1;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? chipColor : softGray,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(f,
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : steelBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF2F2F2)),

          // ── Cards / Empty ─────────────────────────────────
          if (filtered.isEmpty)
            _emptyState(
                'No ${_filter == 'All' ? '' : '$_filter '}records found')
          else ...[
            ...pageItems.map((item) => _buildHistoryCard(item)),

            // ── Pagination bar ─────────────────────────────
            if (totalPages > 1)
              _PaginationBar(
                current:   currentPage,
                total:     totalPages,
                itemCount: filtered.length,
                onPrev: () =>
                    setState(() => _historyPage = currentPage - 1),
                onNext: () =>
                    setState(() => _historyPage = currentPage + 1),
                onPage: (p) => setState(() => _historyPage = p),
              ),
            if (totalPages <= 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final status      = item['status'] as String? ?? '';
    final statusColor = _statusColor(status);

    final IconData statusIcon;
    switch (status) {
      case 'Approved': statusIcon = Icons.check_circle_rounded; break;
      case 'Rejected': statusIcon = Icons.cancel_rounded;       break;
      default:         statusIcon = Icons.access_time_rounded;
    }

    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Color(0xFFF2F2F2), width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // Accent bar — fixed, never shifts
            Container(
              width: 3, height: 44,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),

            // Middle: type + date — takes all remaining space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['type'] as String? ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: navyBlue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['dates'] as String? ?? '',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9E9E)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Days badge — fixed width, always same position
            SizedBox(
              width: 36,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: orange.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '${item['days']}d',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: orange),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Status badge — fixed width, always same position
            SizedBox(
              width: 84,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(statusIcon, size: 11, color: statusColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        status,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Chevron
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: Color(0xFFBDBDBD)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(message,
            style: TextStyle(
                color: steelBlue.withOpacity(0.5), fontSize: 13)),
      ),
    );
  }
}

// ── Detail row widget ─────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;

  static const navyBlue  = Color(0xFF2B457B);
  static const steelBlue = Color(0xFF4A698F);

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: steelBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? navyBlue)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Reusable pagination bar ───────────────────────────────────
class _PaginationBar extends StatelessWidget {
  final int  current;
  final int  total;
  final int  itemCount;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(int) onPage;

  static const navyBlue  = Color(0xFF2B457B);
  static const steelBlue = Color(0xFF4A698F);
  static const softGray  = Color(0xFFF2F2F2);

  const _PaginationBar({
    required this.current,
    required this.total,
    required this.itemCount,
    required this.onPrev,
    required this.onNext,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context) {
    // Visible page numbers: first, last, current ±1
    final Set<int> pageSet = {1, total, current};
    if (current > 1)     pageSet.add(current - 1);
    if (current < total) pageSet.add(current + 1);
    final pages = pageSet.toList()..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: result count
          Text(
            '$itemCount record${itemCount == 1 ? '' : 's'}  •  Page $current of $total',
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9E9E9E),
                fontWeight: FontWeight.w500),
          ),

          // Right: prev + page numbers + next
          Row(mainAxisSize: MainAxisSize.min, children: [
            _Btn(
              icon: Icons.chevron_left,
              enabled: current > 1,
              onTap: onPrev,
            ),
            const SizedBox(width: 4),

            ...() {
              final List<Widget> widgets = [];
              int? prev;
              for (final p in pages) {
                if (prev != null && p - prev > 1) {
                  widgets.add(const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Text('…',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9E9E9E))),
                  ));
                }
                widgets.add(_NumBtn(
                  page: p,
                  isSelected: p == current,
                  onTap: () => onPage(p),
                ));
                widgets.add(const SizedBox(width: 4));
                prev = p;
              }
              return widgets;
            }(),

            _Btn(
              icon: Icons.chevron_right,
              enabled: current < total,
              onTap: onNext,
            ),
          ]),
        ],
      ),
    );
  }
}

class _NumBtn extends StatelessWidget {
  final int  page;
  final bool isSelected;
  final VoidCallback onTap;

  static const navyBlue  = Color(0xFF2B457B);
  static const steelBlue = Color(0xFF4A698F);

  const _NumBtn({
    required this.page,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: isSelected ? navyBlue : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Center(
          child: Text('$page',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : steelBlue)),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final bool     enabled;
  final VoidCallback onTap;

  static const navyBlue = Color(0xFF2B457B);

  const _Btn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: enabled ? navyBlue : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? Colors.white : const Color(0xFFBDBDBD)),
      ),
    );
  }
}