import 'package:flutter/material.dart';

class TaskSummaryCard extends StatelessWidget {
  final int          pendingCount;
  final int          inProgressCount;
  final int          completedCount;
  final VoidCallback onViewTap;

  const TaskSummaryCard({
    super.key,
    required this.pendingCount,
    required this.inProgressCount,
    required this.completedCount,
    required this.onViewTap,
  });

  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);
  static const softGray  = Color(0xFFF2F2F2);

  @override
  Widget build(BuildContext context) {
    final total = pendingCount + inProgressCount + completedCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: softGray, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ───────────────────────────────────────
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: navyBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.task_alt_rounded, color: navyBlue, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Task Summary',
              style: TextStyle(color: navyBlue, fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          Text('$total total', style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onViewTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: navyBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
              child: const Text('View',
                  style: TextStyle(color: navyBlue, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        // ── Pills ────────────────────────────────────────
        Row(children: [
          Expanded(child: _TaskPill(label: 'Pending',     count: pendingCount,    color: orange)),
          const SizedBox(width: 8),
          Expanded(child: _TaskPill(label: 'In Progress', count: inProgressCount, color: steelBlue)),
          const SizedBox(width: 8),
          Expanded(child: _TaskPill(label: 'Completed',   count: completedCount,  color: Colors.green.shade600)),
        ]),
        const SizedBox(height: 12),
        // ── Stacked progress bar ─────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(children: [
            if (pendingCount    > 0) Expanded(flex: pendingCount,    child: Container(height: 6, color: orange)),
            if (inProgressCount > 0) Expanded(flex: inProgressCount, child: Container(height: 6, color: steelBlue)),
            if (completedCount  > 0) Expanded(flex: completedCount,  child: Container(height: 6, color: Colors.green.shade600)),
          ]),
        ),
      ]),
    );
  }
}

class _TaskPill extends StatelessWidget {
  final String label;
  final int    count;
  final Color  color;

  const _TaskPill({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
      ]),
    );
  }
}