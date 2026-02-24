import 'package:flutter/material.dart';

class ActionButtonsCard extends StatelessWidget {
  final String       status;
  final VoidCallback onTimeIn;
  final VoidCallback onTimeOut;
  final VoidCallback onBreakStart;
  final VoidCallback onBreakEnd;

  const ActionButtonsCard({
    super.key,
    required this.status,
    required this.onTimeIn,
    required this.onTimeOut,
    required this.onBreakStart,
    required this.onBreakEnd,
  });

  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);

  bool get _isWorking  => status == 'working';
  bool get _isOnBreak  => status == 'on_break';
  bool get _isTimedIn  => status == 'working' || status == 'on_break';
  bool get _isIdle     => status == 'idle';
  bool get _isTimedOut => status == 'timed_out';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(child: _ActionButton(
          label: 'Time In',   icon: Icons.login_rounded,
          color: Colors.green.shade600, isEnabled: _isIdle || _isTimedOut, onTap: onTimeIn,
        )),
        const SizedBox(width: 10),
        Expanded(child: _ActionButton(
          label: 'Time Out',  icon: Icons.logout_rounded,
          color: navyBlue, isEnabled: _isTimedIn, onTap: onTimeOut,
        )),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _ActionButton(
          label: 'Start Break', icon: Icons.free_breakfast_rounded,
          color: steelBlue, isEnabled: _isWorking, onTap: onBreakStart,
        )),
        const SizedBox(width: 10),
        Expanded(child: _ActionButton(
          label: 'End Break',   icon: Icons.play_arrow_rounded,
          color: orange, isEnabled: _isOnBreak, onTap: onBreakEnd,
        )),
      ]),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final bool     isEnabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label, required this.icon, required this.color,
    required this.isEnabled, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isEnabled ? color : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(13),
          boxShadow: isEnabled
              ? [BoxShadow(color: color.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
    );
  }
}