import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class AttendanceHistory extends StatelessWidget {
  final Map<String, AttendanceRecord> data;
  final int month;
  final int year;

  const AttendanceHistory({
    super.key,
    required this.data,
    required this.month,
    required this.year,
  });

  // ── Colors ────────────────────────────────────────────────
  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);
  static const softGray  = Color(0xFFF2F2F2);

  static const _shortMonths = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

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

  Map<String, int> get _stats {
    final days = DateTime(year, month + 1, 0).day;
    int p = 0, l = 0, a = 0, lv = 0;
    for (int d = 1; d <= days; d++) {
      final key = AttendanceRecord.fmt(DateTime(year, month, d));
      final s   = data[key]?.status ?? '';
      if (s == 'Present')  p++;
      if (s == 'Late')     l++;
      if (s == 'Absent')   a++;
      if (s == 'On Leave') lv++;
    }
    return {'p': p, 'l': l, 'a': a, 'lv': lv};
  }

  List<AttendanceRecord> get _records {
    final days = DateTime(year, month + 1, 0).day;
    final out  = <AttendanceRecord>[];
    for (int d = days; d >= 1; d--) {
      final rec = data[AttendanceRecord.fmt(DateTime(year, month, d))];
      if (rec != null) out.add(rec);
    }
    return out;
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final st  = _stats;
    final rec = _records;

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
                      fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
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
                _StatChip(label: 'Present',  value: st['p']!,  color: const Color(0xFF388E3C)),
                _StatChip(label: 'Late',     value: st['l']!,  color: orange),
                _StatChip(label: 'Absent',   value: st['a']!,  color: const Color(0xFFE53935)),
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
        if (rec.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text(
                'No records this month',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
              ),
            ),
          )

        // ── Records list ──────────────────────────────────
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (_, i) {
                  final r     = rec[i];
                  final color = _statusColor(r.status);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_statusIcon(r.status),
                              color: color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        // Date + times
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_shortMonths[r.date.month - 1]} ${r.date.day}, ${r.date.year}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: navyBlue,
                                ),
                              ),
                              if (r.timeIn != '—') ...[
                                const SizedBox(height: 3),
                                Text(
                                  '${r.timeIn}  →  ${r.timeOut}  ·  ${r.hours}',
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
                            r.status,
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
                childCount: rec.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Small stat chip ───────────────────────────────────────────
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