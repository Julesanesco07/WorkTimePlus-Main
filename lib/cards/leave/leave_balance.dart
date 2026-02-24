import 'package:flutter/material.dart';
import 'package:worktime/app_state.dart';

class LeaveBalance extends StatelessWidget {
  const LeaveBalance({super.key});

  static const navyBlue  = Color(0xFF2B457B);
  static const steelBlue = Color(0xFF4A698F);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          // ── Header ─────────────────────────────────────────
          const Row(children: [
            Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 16),
            SizedBox(width: 8),
            Text(
              'Leave Balance',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ]),
          const SizedBox(height: 12),
          // ── Balance pills ───────────────────────────────────
          Row(children: [
            _BalancePill(
              label: 'Vacation',
              days: AppState().vacationBalance,
              icon: Icons.beach_access_rounded,
            ),
            const SizedBox(width: 10),
            _BalancePill(
              label: 'Sick',
              days: AppState().sickBalance,
              icon: Icons.medical_services_rounded,
            ),
          ]),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  final String  label;
  final int     days;
  final IconData icon;

  const _BalancePill({required this.label, required this.days, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '$days days',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}