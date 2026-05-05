import 'package:flutter/material.dart';
import 'package:worktime/app_state.dart';

class LeaveBalance extends StatefulWidget {
  const LeaveBalance({super.key});

  @override
  State<LeaveBalance> createState() => _LeaveBalanceState();
}

class _LeaveBalanceState extends State<LeaveBalance> {
  static const navyBlue  = Color(0xFF2B457B);
  static const steelBlue = Color(0xFF4A698F);

  int _vacationDays  = 0;
  int _sickDays      = 0;
  int _paternalDays  = 0;
  int _maternalDays  = 0;
  int _emergencyDays = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Called by parent via GlobalKey or didUpdateWidget when balance changes
  @override
  void didUpdateWidget(LeaveBalance old) {
    super.didUpdateWidget(old);
    _load();
  }

  Future<void> _load() async {
    await AppState().reloadUser();
    if (!mounted) return;
    setState(() {
      _vacationDays  = AppState().vacationBalance;
      _sickDays      = AppState().sickBalance;
      _paternalDays  = AppState().paternalBalance;
      _maternalDays  = AppState().maternalBalance;
      _emergencyDays = AppState().emergencyBalance;
    });
  }

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
          BoxShadow(
              color: navyBlue.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(children: [
            Icon(Icons.account_balance_wallet_rounded,
                color: Colors.white70, size: 16),
            SizedBox(width: 8),
            Text('Leave Balance',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          // Balance pills — 2 × 2 grid
          Row(children: [
            _BalancePill(
              label:       'Vacation',
              days:        _vacationDays,
              icon:        Icons.beach_access_rounded,
              accentColor: const Color(0xFF4FC3F7), // sky blue
            ),
            const SizedBox(width: 10),
            _BalancePill(
              label:       'Sick',
              days:        _sickDays,
              icon:        Icons.medical_services_rounded,
              accentColor: const Color(0xFFEF9A9A), // soft red
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _BalancePill(
              label:       'Paternity',
              days:        _paternalDays,
              icon:        Icons.man_rounded,
              accentColor: const Color(0xFF80CBC4), // teal
            ),
            const SizedBox(width: 10),
            _BalancePill(
              label:       'Maternity',
              days:        _maternalDays,
              icon:        Icons.pregnant_woman_rounded,
              accentColor: const Color(0xFFCE93D8), // lavender
            ),
          ]),
          const SizedBox(height: 10),
          _BalancePill(
            label:       'Emergency',
            days:        _emergencyDays,
            icon:        Icons.warning_amber_rounded,
            accentColor: const Color(0xFFFFB74D), // amber
            fullWidth:   true,
          ),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  final String   label;
  final int      days;
  final IconData icon;
  final Color    accentColor;
  final bool     fullWidth;

  const _BalancePill({
    required this.label,
    required this.days,
    required this.icon,
    required this.accentColor,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLow = days >= 1 && days <= 2;

    final Color iconColor  = isLow ? Colors.red.shade200 : accentColor;
    final Color daysColor  = isLow ? Colors.red.shade100 : Colors.white;
    final Color labelColor = isLow ? Colors.red.shade200 : accentColor.withOpacity(0.85);

    final pill = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: isLow
            ? Colors.red.withOpacity(0.25)
            : Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: isLow
            ? Border.all(color: Colors.red.shade300, width: 1)
            : Border.all(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$days days',
              style: TextStyle(
                  color: daysColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(color: labelColor, fontSize: 11),
            ),
          ],
        ),
      ]),
    );

    return fullWidth
        ? SizedBox(width: double.infinity, child: pill)
        : Expanded(child: pill);
  }
}