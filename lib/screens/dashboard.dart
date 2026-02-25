import 'dart:async';
import 'package:flutter/material.dart';
import 'profile.dart';
import 'login.dart';
import '../app_state.dart';
import '../services/local_db.dart';
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

  // ── Live Clock ────────────────────────────────────────────
  Timer?   _clockTimer;
  DateTime _now = DateTime.now();

  // ── Time Tracking ─────────────────────────────────────────
  // Status: idle | working | on_break | timed_out
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

  // ── Task counts (live from DB) ────────────────────────────
  int _taskPending    = 0;
  int _taskInProgress = 0;
  int _taskCompleted  = 0;

  // ── Pending leave count (live from DB) ────────────────────
  int _pendingLeaveCount = 0;

  // ── Loading flag ──────────────────────────────────────────
  bool _initialising = true;

  bool get _isWorking  => _status == 'working';
  bool get _isOnBreak  => _status == 'on_break';
  bool get _isTimedIn  => _status == 'working' || _status == 'on_break';
  bool get _isTimedOut => _status == 'timed_out';
  bool get _isIdle     => _status == 'idle';

  // ── Getters for today's date key ──────────────────────────
  String get _todayKey => LocalDB.dateKey(DateTime.now());
  String get _userId   => AppState().userId;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
    _loadTodayRecord();
    _loadCounts();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _workTimer?.cancel();
    super.dispose();
  }

  // ── Load today's attendance record from DB ────────────────
  Future<void> _loadTodayRecord() async {
    final record =
    await LocalDB.getAttendanceByDate(_userId, _todayKey);

    if (record != null) {
      final timeInStr  = record['timeIn']  as String?;
      final timeOutStr = record['timeOut'] as String?;

      setState(() {
        if (timeInStr != null && timeInStr.isNotEmpty) {
          _timeIn = _parseTimeStr(timeInStr);
          _status = 'working';
        }
        if (timeOutStr != null && timeOutStr.isNotEmpty) {
          _timeOut = _parseTimeStr(timeOutStr);
          _status  = 'timed_out';
        }
      });

      // Resume live timer if still working
      if (_status == 'working' && _timeIn != null) {
        _restoreWorkTimer();
      }
    }

    setState(() => _initialising = false);
  }

  // ── Load task + leave counts from DB ──────────────────────
  Future<void> _loadCounts() async {
    final allTasks = await LocalDB.getTasksByUser(_userId);
    final pending  = allTasks.where((t) => !(t['done'] as bool? ?? false)).length;
    final done     = allTasks.where((t) =>  (t['done'] as bool? ?? false)).length;

    final pendingLeaves = await LocalDB.getPendingLeaves(_userId);

    if (mounted) {
      setState(() {
        _taskPending       = pending;
        _taskInProgress    = 0;   // extend later when "in-progress" tag is added
        _taskCompleted     = done;
        _pendingLeaveCount = pendingLeaves.length;
      });
    }
  }

  // ── Parse stored "8:05 AM" back to DateTime (today's date) ─
  DateTime? _parseTimeStr(String s) {
    try {
      final parts  = s.split(' ');                // ["8:05", "AM"]
      final hm     = parts[0].split(':');         // ["8", "05"]
      int hour     = int.parse(hm[0]);
      final minute = int.parse(hm[1]);
      if (parts.length > 1) {
        if (parts[1] == 'PM' && hour != 12) hour += 12;
        if (parts[1] == 'AM' && hour == 12) hour = 0;
      }
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  // ── Restore work timer from loaded timeIn ─────────────────
  void _restoreWorkTimer() {
    _workTimer?.cancel();
    _workTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeIn == null) return;
      final gross = DateTime.now().difference(_timeIn!);
      final brk   = (_isOnBreak && _breakStart != null)
          ? DateTime.now().difference(_breakStart!)
          : Duration.zero;
      if (mounted) {
        setState(() {
          _workedDuration = gross - _totalBreakDuration - brk;
          if (_workedDuration.isNegative) _workedDuration = Duration.zero;
        });
      }
    });
  }

  // ── Handlers ──────────────────────────────────────────────
  Future<void> _handleTimeIn() async {
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
    _restoreWorkTimer();

    // Persist to LocalDB
    await LocalDB.saveAttendanceRecord({
      'id':      '${_userId}_$_todayKey',
      'userId':  _userId,
      'date':    _todayKey,
      'timeIn':  _formatTime(now),
      'timeOut': '',
      'hours':   '',
      'status':  _isLate(now) ? 'Late' : 'Present',
    });

    _showSnack('Clocked in at ${_formatTime(now)}', Colors.green.shade600);
  }

  Future<void> _handleTimeOut() async {
    if (!_isTimedIn) return;
    _workTimer?.cancel();
    final now = DateTime.now();

    if (_isOnBreak && _breakStart != null) {
      _totalBreakDuration += now.difference(_breakStart!);
      _breakStart = null;
    }

    // Calculate final hours
    final gross    = _timeIn != null ? now.difference(_timeIn!) : Duration.zero;
    final net      = gross - _totalBreakDuration;
    final netSafe  = net.isNegative ? Duration.zero : net;
    final hoursStr =
        '${netSafe.inHours}h ${netSafe.inMinutes % 60}m';

    setState(() {
      _status  = 'timed_out';
      _timeOut = now;
      _workedDuration = netSafe;
    });

    // Update record in LocalDB
    final existing =
    await LocalDB.getAttendanceByDate(_userId, _todayKey);
    await LocalDB.saveAttendanceRecord({
      'id':      '${_userId}_$_todayKey',
      'userId':  _userId,
      'date':    _todayKey,
      'timeIn':  existing?['timeIn'] ?? _formatTime(_timeIn ?? now),
      'timeOut': _formatTime(now),
      'hours':   hoursStr,
      'status':  existing?['status'] ?? 'Present',
    });

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
    _restoreWorkTimer();
    _showSnack('Break ended. Back to work!', const Color(0xFFE97638));
  }

  // ── Helpers ───────────────────────────────────────────────
  bool _isLate(DateTime dt) => dt.hour > 8 || (dt.hour == 8 && dt.minute > 0);

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
    final name     = AppState().userName;
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    if (_initialising) {
      return const Scaffold(
        backgroundColor: cloudWhite,
        body: Center(
          child: CircularProgressIndicator(color: navyBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cloudWhite,
      body: CustomScrollView(
        slivers: [

          // ── App Bar ────────────────────────────────────────
          SliverAppBar(
            backgroundColor: cloudWhite,
            elevation: 0,
            floating: true,
            snap: true,
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
              // ── Profile avatar + name ────────────────────
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfilePage()),
                  );
                  // Reload user in case profile was edited
                  await AppState().reloadUser();
                  if (mounted) setState(() {});
                },
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
              // ── Logout ────────────────────────────────────
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: steelBlue),
                onPressed: () async {
                  _workTimer?.cancel();
                  await AppState().logout();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
              ),
            ],
          ),

          // ── Page content ────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Greeting + clock
                GreetingCard(
                  now:                   _now,
                  status:                _status,
                  availability:          _availability,
                  onAvailabilityChanged: (v) =>
                      setState(() => _availability = v),
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

                // Action buttons
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

                // Quick Stats
                const Text('Quick Stats',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: navyBlue,
                        letterSpacing: 0.2)),
                const SizedBox(height: 10),
                const StatsCard(),
                const SizedBox(height: 16),

                // Pending leave
                PendingLeaveCard(
                  pendingCount: _pendingLeaveCount,
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