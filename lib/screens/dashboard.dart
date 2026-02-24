import 'dart:async';
import 'package:flutter/material.dart';
import 'profile.dart';
import 'login.dart';
import '../app_state.dart';
import '../cards/dashboard/greeting_card.dart';
import '../cards/dashboard/tracking_card.dart';
import '../cards/dashboard/action_buttons_card.dart';
import '../cards/dashboard/timestamp_cards.dart';
import '../cards/dashboard/stats_card.dart';
import '../cards/dashboard/pending_leave_card.dart';
import '../cards/dashboard/task_summary_card.dart';
import '../cards/dashboard/device_card.dart';

class DashboardPage extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const DashboardPage({super.key, this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const navyBlue   = Color(0xFF2B457B);
  static const steelBlue  = Color(0xFF4A698F);
  static const cloudWhite = Color(0xFFFFFFFF);
  static const softGray   = Color(0xFFF2F2F2);

  // ── Live Clock ────────────────────────────────────────────
  Timer?   _clockTimer;
  DateTime _now = DateTime.now();

  // ── Time Tracking ─────────────────────────────────────────
  String    _status             = 'idle';
  DateTime? _timeIn;
  DateTime? _timeOut;
  DateTime? _breakStart;
  DateTime? _lastBreakStart;
  DateTime? _breakEnd;
  Duration  _totalBreakDuration = Duration.zero;
  Timer?    _workTimer;
  Duration  _workedDuration     = Duration.zero;
  String    _availability       = 'Available';

  // ── Task counts (sample) ──────────────────────────────────
  final int _taskPending    = 3;
  final int _taskInProgress = 2;
  final int _taskCompleted  = 2;

  bool get _isWorking  => _status == 'working';
  bool get _isOnBreak  => _status == 'on_break';
  bool get _isTimedIn  => _status == 'working' || _status == 'on_break';
  bool get _isTimedOut => _status == 'timed_out';
  bool get _isIdle     => _status == 'idle';

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

  // ── Handlers ──────────────────────────────────────────────
  void _handleTimeIn() {
    if (_isTimedIn) return;
    final now = DateTime.now();
    setState(() {
      _status             = 'working';
      _timeIn             = now;
      _timeOut            = null;
      _workedDuration     = Duration.zero;
      _totalBreakDuration = Duration.zero;
      _lastBreakStart     = null;
      _breakEnd           = null;
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
    setState(() { _status = 'timed_out'; _timeOut = now; });
    _showSnack('Clocked out at ${_formatTime(now)}', navyBlue);
  }

  void _handleBreakStart() {
    if (!_isWorking) return;
    _workTimer?.cancel();
    final now = DateTime.now();
    setState(() {
      _status         = 'on_break';
      _breakStart     = now;
      _lastBreakStart = now;
      _breakEnd       = null;
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
    setState(() { _status = 'working'; _breakEnd = now; });
    _startWorkTimer();
    _showSnack('Break ended. Back to work!', const Color(0xFFE97638));
  }

  void _startWorkTimer() {
    _workTimer?.cancel();
    _workTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeIn == null) return;
      final gross        = DateTime.now().difference(_timeIn!);
      final currentBreak = (_isOnBreak && _breakStart != null)
          ? DateTime.now().difference(_breakStart!)
          : Duration.zero;
      setState(() {
        _workedDuration = gross - _totalBreakDuration - currentBreak;
        if (_workedDuration.isNegative) _workedDuration = Duration.zero;
      });
    });
  }

  String _formatTime(DateTime dt) {
    final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m  = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }

  String _breakDurationText() {
    Duration total = _totalBreakDuration;
    if (_isOnBreak && _breakStart != null) {
      total += DateTime.now().difference(_breakStart!);
    }
    return '${total.inMinutes}m ${total.inSeconds % 60}s';
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

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user     = AppState().currentUser;
    final name     = user?.name ?? 'User';
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    return Scaffold(
      backgroundColor: cloudWhite,
      body: CustomScrollView(
        slivers: [

          // ── Scrollable App Bar ───────────────────────────
          SliverAppBar(
            backgroundColor: cloudWhite,
            elevation: 0,
            floating: true,       // reappears as soon as you scroll up
            snap: true,           // snaps fully in/out — no half-visible state
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: Transform.scale(
              scale: 5.4,
              child: Transform.translate(
                offset: const Offset(4.5, 1),
                child: Image.asset(
                  'images/LogoNBG.png',
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text(
                    'W+',
                    style: TextStyle(
                        color: navyBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage())),
                child: Row(children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: navyBlue,
                    child: Text(initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text(name,
                      style: const TextStyle(
                          fontSize: 13,
                          color: navyBlue,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: steelBlue),
                onPressed: () {
                  AppState().logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
              ),
            ],
          ),

          // ── Page content ─────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Greeting + clock
                GreetingCard(
                  now:                   _now,
                  status:                _status,
                  availability:          _availability,
                  onAvailabilityChanged: (v) => setState(() => _availability = v),
                ),
                const SizedBox(height: 16),

                // Work hours tracker
                TrackingCard(
                  status:             _status,
                  workedDuration:     _workedDuration,
                  totalBreakDuration: _totalBreakDuration,
                  isOnBreak:          _isOnBreak,
                  breakStart:         _breakStart,
                  breakDurationText:  _breakDurationText,
                ),
                const SizedBox(height: 12),

                // Time in/out + break buttons
                ActionButtonsCard(
                  status:       _status,
                  onTimeIn:     _handleTimeIn,
                  onTimeOut:    _handleTimeOut,
                  onBreakStart: _handleBreakStart,
                  onBreakEnd:   _handleBreakEnd,
                ),
                const SizedBox(height: 18),

                // Timestamp cards
                TimestampCards(
                  timeIn:         _timeIn,
                  timeOut:        _timeOut,
                  lastBreakStart: _lastBreakStart,
                  breakEnd:       _breakEnd,
                ),
                const SizedBox(height: 20),

                // Quick stats label
                const Text(
                  'Quick Stats',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: navyBlue,
                      letterSpacing: 0.2),
                ),
                const SizedBox(height: 10),
                const StatsCard(),
                const SizedBox(height: 16),

                // Pending leave
                PendingLeaveCard(
                  pendingCount: 2,
                  onViewTap:    () => widget.onNavigate?.call(2),
                ),
                const SizedBox(height: 16),

                // Task summary
                TaskSummaryCard(
                  pendingCount:    _taskPending,
                  inProgressCount: _taskInProgress,
                  completedCount:  _taskCompleted,
                  onViewTap:       () => widget.onNavigate?.call(3),
                ),
                const SizedBox(height: 16),

                // Device info
                const DeviceCard(),

              ]),
            ),
          ),
        ],
      ),
    );
  }
}