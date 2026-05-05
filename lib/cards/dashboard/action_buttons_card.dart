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

  bool get _isWorking  => status == 'working';
  bool get _isOnBreak  => status == 'on_break';
  bool get _isTimedIn  => status == 'working' || status == 'on_break';

  // ── Time button ───────────────────────────────────────────
  String       get _timeLabel  => _isTimedIn ? 'Time Out'    : 'Time In';
  IconData     get _timeIcon   => _isTimedIn ? Icons.logout_rounded : Icons.login_rounded;
  Color        get _timeColor  => _isTimedIn ? Colors.red.shade600  : Colors.green.shade600;
  VoidCallback get _timeAction => _isTimedIn ? onTimeOut     : onTimeIn;

  // ── Break button ──────────────────────────────────────────
  String       get _breakLabel  => _isOnBreak ? 'End Break'          : 'Start Break';
  IconData     get _breakIcon   => _isOnBreak ? Icons.play_arrow_rounded : Icons.free_breakfast_rounded;
  Color        get _breakColor  => _isOnBreak ? Colors.red.shade600   : Colors.green.shade600;
  VoidCallback get _breakAction => _isOnBreak ? onBreakEnd            : onBreakStart;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: _ActionButton(
          label:     _timeLabel,
          icon:      _timeIcon,
          color:     _timeColor,
          isEnabled: true,
          onTap:     _timeAction,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _ActionButton(
          label:     _breakLabel,
          icon:      _breakIcon,
          color:     _breakColor,
          isEnabled: _isTimedIn,
          onTap:     _breakAction,
        ),
      ),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final Color        color;
  final bool         isEnabled;
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