import 'package:flutter/material.dart';

class PendingLeaveCard extends StatelessWidget {
  final int          pendingCount;
  final VoidCallback onViewTap;

  const PendingLeaveCard({
    super.key,
    required this.pendingCount,
    required this.onViewTap,
  });

  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);
  static const softGray  = Color(0xFFF2F2F2);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: softGray, width: 1.5),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.pending_actions_rounded, color: orange, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text('Pending Leave Requests',
              style: TextStyle(color: steelBlue, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(20)),
          child: Text('$pendingCount Pending',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onViewTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: navyBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('View',
                style: TextStyle(color: navyBlue, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}