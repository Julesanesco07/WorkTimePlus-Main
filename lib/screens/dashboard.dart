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
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
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

  // ── Countdown / Overtime ──────────────────────────────────
  // Countdown = 8h of actual work time (breaks are paused, not counted)
  static const _shiftDuration = Duration(hours: 8);
  bool _isOvertime            = false;
  bool _overtimeDialogShown   = false;   // only prompt once per session

  // ── Task counts (live from DB) ────────────────────────────
  int _taskPending    = 0;
  int _taskInProgress = 0;
  int _taskCompleted  = 0;

  // ── Pending leave count (live from DB) ────────────────────
  int _pendingLeaveCount = 0;

  // ── Weekly stats (live from DB) ───────────────────────────
  String   _thisWeekStr       = '0h 0m';
  String   _overtimeStr       = '0h 0m';
  int      _leaveLeft         = 0;
  // Base totals from DB (past days, excluding today's live session)
  Duration _weeklyBaseWorked   = Duration.zero;
  Duration _weeklyBaseOvertime = Duration.zero;

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
    WidgetsBinding.instance.addObserver(this);
    _clockTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
    // Load today first, then stats (stats need _workedDuration to be ready)
    _loadTodayRecord().then((_) => _loadWeeklyStats());
    _loadCounts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _workTimer?.cancel();
    super.dispose();
  }

  /// Called by navigation when switching back to Dashboard tab
  void refresh() {
    _loadCounts();
    _loadWeeklyStats();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCounts();
      _loadWeeklyStats();
    }
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

  // ── Compute this-week hours + overtime from DB ───────────
  Future<void> _loadWeeklyStats() async {
    final now       = DateTime.now();
    final monday    = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);

    final allRecords = await LocalDB.getAttendanceByUser(_userId);

    final weekRecords = allRecords.where((r) {
      final d = DateTime.tryParse(r['date'] as String? ?? '');
      return d != null && !d.isBefore(weekStart) && !d.isAfter(now);
    }).toList();

    Duration parseHours(String? s) {
      if (s == null || s.isEmpty || s == '—') return Duration.zero;
      final hMatch = RegExp(r'(\d+)h').firstMatch(s);
      final mMatch = RegExp(r'(\d+)m').firstMatch(s);
      final h = hMatch != null ? int.parse(hMatch.group(1)!) : 0;
      final m = mMatch != null ? int.parse(mMatch.group(1)!) : 0;
      return Duration(hours: h, minutes: m);
    }

    const standardDay = Duration(hours: 8);
    Duration baseWorked   = Duration.zero;
    Duration baseOvertime = Duration.zero;

    for (final r in weekRecords) {
      final status = r['status'] as String? ?? '';
      if (status != 'Present' && status != 'Late') continue;

      // Skip today's record — today is handled live via _workedDuration
      if ((r['date'] as String? ?? '') == _todayKey) continue;

      final worked = parseHours(r['hours'] as String?);
      baseWorked += worked;
      if (worked > standardDay) baseOvertime += worked - standardDay;
    }

    // Leave left = vacation + sick remaining
    await AppState().reloadUser();
    final leaveLeft = AppState().vacationBalance + AppState().sickBalance;

    // Today's contribution: use saved hours if clocked out, else live duration
    final todayRec = weekRecords.firstWhere(
          (r) => (r['date'] as String? ?? '') == _todayKey,
      orElse: () => {},
    );
    final savedHours = parseHours(todayRec['hours'] as String?);
    final todayWorked = savedHours > Duration.zero
        ? savedHours          // clocked out — use saved value
        : _workedDuration;    // still working — use live timer

    final totalWorked   = baseWorked + todayWorked;
    final totalOvertime = baseOvertime +
        (todayWorked > standardDay ? todayWorked - standardDay : Duration.zero);

    if (mounted) {
      setState(() {
        _weeklyBaseWorked   = baseWorked;
        _weeklyBaseOvertime = baseOvertime;
        _thisWeekStr = '${totalWorked.inHours}h ${totalWorked.inMinutes % 60}m';
        _overtimeStr = '${totalOvertime.inHours}h ${totalOvertime.inMinutes % 60}m';
        _leaveLeft   = leaveLeft;
      });
    }
  }

  // ── Load task + leave counts from DB ──────────────────────
  Future<void> _loadCounts() async {
    final allTasks   = await LocalDB.getTasksByUser(_userId);
    final pending    = allTasks.where((t) =>
    !(t['done'] as bool? ?? false) &&
        !(t['inProgress'] as bool? ?? false)).length;
    final inProgress = allTasks.where((t) =>
    (t['inProgress'] as bool? ?? false) &&
        !(t['done'] as bool? ?? false)).length;
    final done       = allTasks.where((t) =>
    (t['done'] as bool? ?? false)).length;

    final pendingLeaves = await LocalDB.getPendingLeaves(_userId);

    if (mounted) {
      setState(() {
        _taskPending       = pending;
        _taskInProgress    = inProgress;
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
        final newWorked = gross - _totalBreakDuration - brk;
        final clamped   = newWorked.isNegative ? Duration.zero : newWorked;

        // Overtime dialog triggers 30 min after shift ends
        final newIsOvertime = clamped >= _shiftDuration;
        final overtimeThreshold = _shiftDuration + const Duration(minutes: 30);
        final shouldPrompt = clamped >= overtimeThreshold;

        setState(() {
          _workedDuration = clamped;
          _isOvertime     = newIsOvertime;
        });

        // Show overtime dialog once when 8h 30m threshold is crossed
        if (shouldPrompt && !_overtimeDialogShown) {
          _overtimeDialogShown = true;
          _showOvertimeDialog();
        }

        // Update "This Week" live every second
        _updateWeeklyStatsLive();
      }
    });
  }

  // ── Overtime prompt ───────────────────────────────────────
  void _showOvertimeDialog() {
    if (!mounted) return;
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE97638).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time_rounded,
                color: Color(0xFFE97638), size: 22),
          ),
          const SizedBox(width: 12),
          const Flexible(
            child: Text('Still Working?',
                style: TextStyle(
                    color: navyBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "You've been working for 8 hours and 30 minutes.",
              style: TextStyle(fontSize: 14, color: Color(0xFF4A698F)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE97638).withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFE97638).withOpacity(0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFE97638), size: 16),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Any additional time will be logged as overtime.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE97638),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            const Text(
              'Are you working overtime?',
              style: TextStyle(
                  fontSize: 14,
                  color: navyBlue,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context, 'clockout'),
                child: const Text('Clock Out Now',
                    style: TextStyle(
                        color: Color(0xFF4A698F),
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE97638),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context, 'overtime'),
                child: const Text('Yes, Overtime',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ),
          ]),
        ],
      ),
    ).then((choice) {
      if (choice == 'clockout') {
        _handleTimeOut();
      }
      // If 'overtime' or dismissed — do nothing, keep tracking
    });
  }

  // ── Live weekly stats update (no DB call — uses _workedDuration) ─
  void _updateWeeklyStatsLive() {
    const standardDay = Duration(hours: 8);

    // Re-use the last DB-loaded base (without today's live contribution)
    // by recomputing from _workedDuration on top of _weeklyBaseWorked
    final total    = _weeklyBaseWorked + _workedDuration;
    final overtime = _weeklyBaseOvertime +
        (_workedDuration > standardDay
            ? _workedDuration - standardDay
            : Duration.zero);

    setState(() {
      _thisWeekStr = '${total.inHours}h ${total.inMinutes % 60}m';
      _overtimeStr = '${overtime.inHours}h ${overtime.inMinutes % 60}m';
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
      _isOvertime         = false;
      _overtimeDialogShown = false;
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

    // ── Confirmation dialog ───────────────────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: navyBlue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout_rounded,
                color: navyBlue, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Clock Out?',
              style: TextStyle(
                  color: navyBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 17)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to clock out?',
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF4A698F)),
            ),
            const SizedBox(height: 12),
            // Summary row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _DialogStat(
                    label: 'Time In',
                    value: _timeIn != null
                        ? _formatTime(_timeIn!)
                        : '--:--',
                    icon: Icons.login_rounded,
                    color: Colors.green.shade600,
                  ),
                  Container(
                      width: 1, height: 36,
                      color: const Color(0xFFE0E0E0)),
                  _DialogStat(
                    label: 'Worked',
                    value: '${_workedDuration.inHours}h '
                        '${_workedDuration.inMinutes % 60}m',
                    icon: Icons.timer_rounded,
                    color: navyBlue,
                  ),
                  Container(
                      width: 1, height: 36,
                      color: const Color(0xFFE0E0E0)),
                  _DialogStat(
                    label: 'Now',
                    value: _formatTime(DateTime.now()),
                    icon: Icons.logout_rounded,
                    color: const Color(0xFFE97638),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding:
        const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(
                      color: Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: Color(0xFF4A698F),
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: navyBlue,
                  padding:
                  const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clock Out',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ],
      ),
    );

    if (confirmed != true) {
      // User cancelled — resume the work timer
      if (_isWorking) _restoreWorkTimer();
      return;
    }

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
    _loadWeeklyStats(); // refresh stats with final hours
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
                  isOvertime:         _isOvertime,
                  shiftDuration:      _shiftDuration,
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
                StatsCard(
                  thisWeek:  _thisWeekStr,
                  overtime:  _overtimeStr,
                  leaveLeft: _leaveLeft,
                ),
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

// ── Dialog stat tile used in clock-out confirmation ───────────
class _DialogStat extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  const _DialogStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(
              fontSize: 10, color: Color(0xFF9E9E9E))),
    ]);
  }
}