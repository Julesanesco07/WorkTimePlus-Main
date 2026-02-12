import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'profile.dart';
import 'login.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ── Colors ────────────────────────────────────────────────
  static const navyBlue   = Color(0xFF2B457B);
  static const orange     = Color(0xFFE97638);
  static const steelBlue  = Color(0xFF4A698F);
  static const cloudWhite = Color(0xFFFFFFFF);
  static const softGray   = Color(0xFFF2F2F2);

  // ── Live Clock ────────────────────────────────────────────
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  // ── Time Tracking  ────────────────────────────────────────
  // _status: 'idle' | 'working' | 'on_break' | 'timed_out'
  String   _status             = 'idle';
  DateTime? _timeIn;
  DateTime? _timeOut;
  DateTime? _breakStart;
  Duration  _totalBreakDuration = Duration.zero;
  Timer?    _workTimer;
  Duration  _workedDuration     = Duration.zero;
  String    _availability       = 'Available';

  // ── Task summary (sample) ─────────────────────────────────
  final int _taskPending    = 3;
  final int _taskInProgress = 2;
  final int _taskCompleted  = 2;

  // ── Getters ───────────────────────────────────────────────
  bool get _isWorking  => _status == 'working';
  bool get _isOnBreak  => _status == 'on_break';
  bool get _isTimedIn  => _status == 'working' || _status == 'on_break';
  bool get _isIdle     => _status == 'idle';
  bool get _isTimedOut => _status == 'timed_out';

  String get _elapsedText {
    final h = _workedDuration.inHours.toString().padLeft(2, '0');
    final m = (_workedDuration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_workedDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ── Device info ───────────────────────────────────────────
  String get _deviceName {
    if (kIsWeb) return 'Web Browser';
    try {
      if (Platform.isAndroid) return 'Android Device';
      if (Platform.isIOS)     return 'iPhone / iPad';
      if (Platform.isWindows) return 'Windows PC';
      if (Platform.isMacOS)   return 'Mac';
      if (Platform.isLinux)   return 'Linux';
    } catch (_) {}
    return 'Unknown Device';
  }

  IconData get _deviceIcon {
    if (kIsWeb) return Icons.language_rounded;
    try {
      if (Platform.isAndroid) return Icons.phone_android_rounded;
      if (Platform.isIOS)     return Icons.phone_iphone_rounded;
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
        return Icons.computer_rounded;
    } catch (_) {}
    return Icons.devices_rounded;
  }

  // ── Init / Dispose ────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _workTimer?.cancel();
    super.dispose();
  }

  // ── Handlers ─────────────────────────────────────────────
  void _handleTimeIn() {
    if (_isTimedIn) return;
    final now = DateTime.now();
    setState(() {
      _status              = 'working';
      _timeIn              = now;
      _timeOut             = null;
      _workedDuration      = Duration.zero;
      _totalBreakDuration  = Duration.zero;
    });
    _startWorkTimer();
    _showSnack('Clocked in at ${_formatTime(now)}', Colors.green.shade600);
  }

  void _handleTimeOut() {
    if (!_isTimedIn) return;
    _workTimer?.cancel();
    final now = DateTime.now();
    if (_isOnBreak && _breakStart != null) {
      _totalBreakDuration += now.difference(_breakStart!);
      _breakStart = null;
    }
    setState(() {
      _status  = 'timed_out';
      _timeOut = now;
    });
    _showSnack('Clocked out at ${_formatTime(now)}', navyBlue);
  }

  void _handleBreakStart() {
    if (!_isWorking) return;
    _workTimer?.cancel();
    final now = DateTime.now();
    setState(() {
      _status     = 'on_break';
      _breakStart = now;
    });
    _showSnack('Break started at ${_formatTime(now)}', steelBlue);
  }

  void _handleBreakEnd() {
    if (!_isOnBreak) return;
    final now = DateTime.now();
    if (_breakStart != null) {
      _totalBreakDuration += now.difference(_breakStart!);
      _breakStart = null;
    }
    setState(() => _status = 'working');
    _startWorkTimer();
    _showSnack('Break ended. Back to work!', orange);
  }

  void _startWorkTimer() {
    _workTimer?.cancel();
    _workTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeIn == null) return;
      final gross         = DateTime.now().difference(_timeIn!);
      final currentBreak  = (_isOnBreak && _breakStart != null)
          ? DateTime.now().difference(_breakStart!)
          : Duration.zero;
      setState(() {
        _workedDuration = gross - _totalBreakDuration - currentBreak;
        if (_workedDuration.isNegative) _workedDuration = Duration.zero;
      });
    });
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Formatters ────────────────────────────────────────────
  String _formatTime(DateTime dt) {
    final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m  = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }

  String _formatFullDate(DateTime dt) {
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatClockTime(DateTime dt) {
    final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m  = dt.minute.toString().padLeft(2, '0');
    final s  = dt.second.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m:$s $ap';
  }

  String _breakDurationText() {
    Duration total = _totalBreakDuration;
    if (_isOnBreak && _breakStart != null) {
      total += DateTime.now().difference(_breakStart!);
    }
    final m = total.inMinutes;
    final s = total.inSeconds % 60;
    return '${m}m ${s}s';
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cloudWhite,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingAndClock(),
            const SizedBox(height: 16),
            _buildMainTrackingCard(),
            const SizedBox(height: 12),
            _buildActionButtons(),
            const SizedBox(height: 18),
            _buildTimeInOutCards(),
            const SizedBox(height: 20),
            _buildSectionLabel('Quick Stats'),
            const SizedBox(height: 10),
            _buildStatsRow(),
            const SizedBox(height: 16),
            _buildPendingLeaveCard(),
            const SizedBox(height: 16),
            _buildTaskSummaryCard(),
            const SizedBox(height: 16),
            _buildDeviceCard(),
          ],
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: cloudWhite,
      title: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: navyBlue, borderRadius: BorderRadius.circular(8)),
          child: const Center(child: Text('W+', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 8),
        const Text('Worktime+', style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 18)),
      ]),
      actions: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: softGray),
            child: Row(children: [
              CircleAvatar(radius: 14, backgroundColor: navyBlue,
                  child: const Text('JD', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
              const SizedBox(width: 8),
              const Text('John Doe', style: TextStyle(fontSize: 13, color: navyBlue, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: steelBlue),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Greeting + Live Clock ─────────────────────────────────
  Widget _buildGreetingAndClock() {
    final hour = _now.hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    Color statusColor;
    Color statusBg;
    String statusLabel;
    if (_isOnBreak) {
      statusLabel = 'On Break';
      statusColor = steelBlue;
      statusBg    = steelBlue.withOpacity(0.1);
    } else if (_isWorking) {
      statusLabel = 'Clocked In';
      statusColor = Colors.green.shade600;
      statusBg    = const Color(0xFFE8F5E9);
    } else if (_isTimedOut) {
      statusLabel = 'Clocked Out';
      statusColor = Colors.red.shade400;
      statusBg    = Colors.red.shade50;
    } else {
      statusLabel = 'Not Clocked In';
      statusColor = const Color(0xFF9E9E9E);
      statusBg    = softGray;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting, John 👋',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: navyBlue)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 7, height: 7,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(statusLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                    ]),
                  ),
                  // Availability dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _availability == 'Available' ? const Color(0xFFFFF3E0) : softGray,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _availability,
                        isDense: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 16, color: orange),
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: _availability == 'Available' ? orange : const Color(0xFF9E9E9E),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Available',     child: Text('Available')),
                          DropdownMenuItem(value: 'Not Available', child: Text('Not Available')),
                        ],
                        onChanged: (val) => setState(() => _availability = val!),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Live date + time
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_formatClockTime(_now),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navyBlue, letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Text(_formatFullDate(_now),
                style: const TextStyle(fontSize: 10, color: steelBlue)),
          ],
        ),
      ],
    );
  }

  // ── Main Tracking Card ────────────────────────────────────
  Widget _buildMainTrackingCard() {
    String trackStatus;
    Color  trackStatusColor;
    if (_isOnBreak) {
      trackStatus      = 'On Break';
      trackStatusColor = Colors.amberAccent.shade400;
    } else if (_isWorking) {
      trackStatus      = 'Working';
      trackStatusColor = Colors.greenAccent.shade400;
    } else if (_isTimedOut) {
      trackStatus      = 'Shift Ended';
      trackStatusColor = Colors.redAccent.shade100;
    } else {
      trackStatus      = 'Not Started';
      trackStatusColor = Colors.white38;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navyBlue, steelBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: navyBlue.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Today's Work Hours",
                style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.3)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: trackStatusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: trackStatusColor.withOpacity(0.5)),
              ),
              child: Row(children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(color: trackStatusColor, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(trackStatus, style: TextStyle(color: trackStatusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _elapsedText,
          style: const TextStyle(color: Colors.white, fontSize: 46, fontWeight: FontWeight.w300, letterSpacing: 4),
        ),
        const SizedBox(height: 4),
        Text(
          _isTimedIn  ? 'Elapsed work time (breaks excluded)'
              : _isTimedOut ? 'Final hours logged'
              : 'Clock in to start tracking',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Goal  8h', style: TextStyle(color: Colors.white60, fontSize: 11)),
              Text(
                '${(_workedDuration.inSeconds / (8 * 3600) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_workedDuration.inSeconds / (8 * 3600)).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.2),
              color: orange,
              minHeight: 6,
            ),
          ),
        ]),
        if (_totalBreakDuration > Duration.zero || _isOnBreak) ...[
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.free_breakfast_rounded, color: Colors.amber, size: 14),
            const SizedBox(width: 6),
            Text('Total break: ${_breakDurationText()}',
                style: const TextStyle(color: Colors.amber, fontSize: 11)),
          ]),
        ],
      ]),
    );
  }

  // ── Action Buttons ────────────────────────────────────────
  Widget _buildActionButtons() {
    return Column(children: [
      Row(children: [
        Expanded(child: _ActionButton(
          label: 'Time In',
          icon: Icons.login_rounded,
          color: Colors.green.shade600,
          isEnabled: _isIdle || _isTimedOut,
          onTap: _handleTimeIn,
        )),
        const SizedBox(width: 10),
        Expanded(child: _ActionButton(
          label: 'Time Out',
          icon: Icons.logout_rounded,
          color: navyBlue,
          isEnabled: _isTimedIn,
          onTap: _handleTimeOut,
        )),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _ActionButton(
          label: 'Start Break',
          icon: Icons.free_breakfast_rounded,
          color: steelBlue,
          isEnabled: _isWorking,
          onTap: _handleBreakStart,
        )),
        const SizedBox(width: 10),
        Expanded(child: _ActionButton(
          label: 'End Break',
          icon: Icons.play_arrow_rounded,
          color: orange,
          isEnabled: _isOnBreak,
          onTap: _handleBreakEnd,
        )),
      ]),
    ]);
  }

  // ── Time In / Out Timestamp Cards ────────────────────────
  Widget _buildTimeInOutCards() {
    return Row(children: [
      Expanded(child: _TimeStampCard(
        label: 'Time In',
        time: _timeIn != null ? _formatTime(_timeIn!) : '--:-- --',
        icon: Icons.login_rounded,
        color: Colors.green.shade600,
        isSet: _timeIn != null,
      )),
      const SizedBox(width: 12),
      Expanded(child: _TimeStampCard(
        label: 'Time Out',
        time: _timeOut != null ? _formatTime(_timeOut!) : '--:-- --',
        icon: Icons.logout_rounded,
        color: navyBlue,
        isSet: _timeOut != null,
      )),
    ]);
  }

  // ── Stats Row ─────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(children: [
      Expanded(child: _StatCard(label: 'This Week', value: '34h 20m', icon: Icons.bar_chart_rounded,      color: steelBlue)),
      const SizedBox(width: 10),
      Expanded(child: _StatCard(label: 'Overtime',  value: '2h 10m',  icon: Icons.more_time_rounded,      color: orange)),
      const SizedBox(width: 10),
      Expanded(child: _StatCard(label: 'Leave Left', value: '12 days', icon: Icons.event_available_rounded, color: navyBlue)),
    ]);
  }

  // ── Pending Leave Card ────────────────────────────────────
  Widget _buildPendingLeaveCard() {
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
        const Expanded(child: Text('Pending Leave Requests',
            style: TextStyle(color: steelBlue, fontWeight: FontWeight.w600, fontSize: 13))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(20)),
          child: const Text('2 Pending', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  // ── Task Summary Card ─────────────────────────────────────
  Widget _buildTaskSummaryCard() {
    final total = _taskPending + _taskInProgress + _taskCompleted;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cloudWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: softGray, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: navyBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.task_alt_rounded, color: navyBlue, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Task Summary', style: TextStyle(color: navyBlue, fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          Text('$total total', style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _TaskPill(label: 'Pending',     count: _taskPending,    color: orange)),
          const SizedBox(width: 8),
          Expanded(child: _TaskPill(label: 'In Progress', count: _taskInProgress, color: steelBlue)),
          const SizedBox(width: 8),
          Expanded(child: _TaskPill(label: 'Completed',   count: _taskCompleted,  color: Colors.green.shade600)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(children: [
            if (_taskPending    > 0) Expanded(flex: _taskPending,    child: Container(height: 6, color: orange)),
            if (_taskInProgress > 0) Expanded(flex: _taskInProgress, child: Container(height: 6, color: steelBlue)),
            if (_taskCompleted  > 0) Expanded(flex: _taskCompleted,  child: Container(height: 6, color: Colors.green.shade600)),
          ]),
        ),
      ]),
    );
  }

  // ── Device Card ───────────────────────────────────────────
  Widget _buildDeviceCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cloudWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: softGray, width: 1.5),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: steelBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(_deviceIcon, color: steelBlue, size: 22),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Connected Device',
              style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(_deviceName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: navyBlue)),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            const Text('Active', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: navyBlue, letterSpacing: 0.2));
  }
}

// ── Reusable Widgets ──────────────────────────────────────────

class _TimeStampCard extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color color;
  final bool isSet;

  const _TimeStampCard({required this.label, required this.time, required this.icon, required this.color, required this.isSet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSet ? color.withOpacity(0.06) : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isSet ? color.withOpacity(0.2) : Colors.transparent),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSet ? color.withOpacity(0.12) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: isSet ? color : Colors.grey, size: 18),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(time, style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold,
            color: isSet ? color : const Color(0xFFBDBDBD),
          )),
        ]),
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.color, required this.isEnabled, required this.onTap});

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
          boxShadow: isEnabled ? [BoxShadow(color: color.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 3))] : [],
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
      ]),
    );
  }
}

class _TaskPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

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