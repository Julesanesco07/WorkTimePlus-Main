import 'package:flutter/material.dart';

class AttendanceHistory extends StatefulWidget {
  final Map<String, Map<String, dynamic>> data;
  final int month;
  final int year;

  const AttendanceHistory({
    super.key,
    required this.data,
    required this.month,
    required this.year,
  });

  @override
  State<AttendanceHistory> createState() => _AttendanceHistoryState();
}

class _AttendanceHistoryState extends State<AttendanceHistory> {
  // ── Colors ────────────────────────────────────────────────
  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);
  static const softGray  = Color(0xFFF2F2F2);

  static const _pageSize = 5;
  int _currentPage = 1;

  static const _shortMonths = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  // ── Reset page when month/year changes ───────────────────
  @override
  void didUpdateWidget(AttendanceHistory old) {
    super.didUpdateWidget(old);
    if (old.month != widget.month || old.year != widget.year) {
      setState(() => _currentPage = 1);
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  Color _statusColor(String s) {
    switch (s) {
      case 'Present':  return const Color(0xFF388E3C);
      case 'Late':     return orange;
      case 'Absent':   return const Color(0xFFE53935);
      case 'On Leave': return steelBlue;
      default:         return const Color(0xFFBDBDBD);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'Present':  return Icons.check_circle_rounded;
      case 'Late':     return Icons.watch_later_rounded;
      case 'Absent':   return Icons.cancel_rounded;
      case 'On Leave': return Icons.beach_access_rounded;
      default:         return Icons.brightness_3_rounded;
    }
  }

  // ── Date key helper (matches LocalDB format) ─────────────
  String _dateKey(int year, int month, int day) {
    final mm = month.toString().padLeft(2, '0');
    final dd = day.toString().padLeft(2, '0');
    return '$year-$mm-$dd';
  }

  Map<String, int> get _stats {
    final days = DateTime(widget.year, widget.month + 1, 0).day;
    int p = 0, l = 0, a = 0, lv = 0;
    for (int d = 1; d <= days; d++) {
      final key = _dateKey(widget.year, widget.month, d);
      final s   = widget.data[key]?['status'] as String? ?? '';
      if (s == 'Present')  p++;
      if (s == 'Late')     l++;
      if (s == 'Absent')   a++;
      if (s == 'On Leave') lv++;
    }
    return {'p': p, 'l': l, 'a': a, 'lv': lv};
  }

  List<Map<String, dynamic>> get _allRecords {
    final days = DateTime(widget.year, widget.month + 1, 0).day;
    final out  = <Map<String, dynamic>>[];
    for (int d = days; d >= 1; d--) {
      final key = _dateKey(widget.year, widget.month, d);
      final rec = widget.data[key];
      if (rec != null) out.add(rec);
    }
    return out;
  }

  // ── Pagination ────────────────────────────────────────────
  int _totalPages(int count) => (count / _pageSize).ceil().clamp(1, 9999);

  List<Map<String, dynamic>> _pageOf(
      List<Map<String, dynamic>> list, int page) {
    final start = (page - 1) * _pageSize;
    final end   = (start + _pageSize).clamp(0, list.length);
    if (start >= list.length) return [];
    return list.sublist(start, end);
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final st         = _stats;
    final allRec     = _allRecords;
    final totalPages = _totalPages(allRec.length);
    final page       = _currentPage.clamp(1, totalPages);
    final pageItems  = _pageOf(allRec, page);

    return CustomScrollView(
      slivers: [

        // ── Section header ────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Container(
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
                const Icon(Icons.history_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                const Text(
                  'Attendance History',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${allRec.length} record${allRec.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ]),
            ),
          ),
        ),

        // ── Stats summary bar ─────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: softGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(label: 'Present',  value: st['p']!,
                    color: const Color(0xFF388E3C)),
                _StatChip(label: 'Late',     value: st['l']!,  color: orange),
                _StatChip(label: 'Absent',   value: st['a']!,
                    color: const Color(0xFFE53935)),
                _StatChip(label: 'On Leave', value: st['lv']!, color: steelBlue),
              ],
            ),
          ),
        ),

        // ── Divider ───────────────────────────────────────
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 10),
            child: Divider(height: 1),
          ),
        ),

        // ── Empty state ───────────────────────────────────
        if (allRec.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text(
                'No records this month',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
              ),
            ),
          )

        // ── Paginated records list ────────────────────────
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (_, i) {
                  final r      = pageItems[i];
                  final status = r['status'] as String? ?? '';
                  final date   = DateTime.tryParse(r['date'] as String? ?? '')
                      ?? DateTime(widget.year, widget.month, 1);
                  final timeIn  = r['timeIn']  as String? ?? '';
                  final timeOut = r['timeOut'] as String? ?? '';
                  final hours   = r['hours']   as String? ?? '';
                  final color   = _statusColor(status);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border:
                        Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        // Status icon
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_statusIcon(status),
                              color: color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        // Date + clock times
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_shortMonths[date.month - 1]}'
                                    ' ${date.day}, ${date.year}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: navyBlue,
                                ),
                              ),
                              if (timeIn.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  '$timeIn  →  $timeOut  ·  $hours',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF9E9E9E)),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  );
                },
                childCount: pageItems.length,
              ),
            ),
          ),

          // ── Pagination bar ────────────────────────────
          SliverToBoxAdapter(
            child: _PaginationBar(
              current:   page,
              total:     totalPages,
              itemCount: allRec.length,
              onPrev: page > 1
                  ? () => setState(() => _currentPage = page - 1)
                  : () {},
              onNext: page < totalPages
                  ? () => setState(() => _currentPage = page + 1)
                  : () {},
              onPage: (p) => setState(() => _currentPage = p),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SUPPORTING WIDGETS
// ─────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int    value;
  final Color  color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(
        '$value',
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: color),
      ),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
    ]);
  }
}

class _PaginationBar extends StatelessWidget {
  final int  current;
  final int  total;
  final int  itemCount;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(int) onPage;

  static const navyBlue  = Color(0xFF2B457B);
  static const steelBlue = Color(0xFF4A698F);

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
                            fontSize: 12, color: Color(0xFF9E9E9E))),
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
            color: enabled ? Colors.white
                : const Color(0xFFBDBDBD)),
      ),
    );
  }
}