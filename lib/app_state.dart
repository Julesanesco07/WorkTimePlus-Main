import 'models/user_model.dart';

class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // ── Current logged-in user ────────────────────────────────
  DemoUser? _currentUser;
  DemoUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // ── Leave balances (sourced from user model at login) ─────
  int vacationBalance = 0;
  int sickBalance     = 0;

  // ── Login / Logout ────────────────────────────────────────
  bool login(String email, String password) {
    final user = DemoUser.authenticate(email, password);
    if (user != null) {
      _currentUser    = user;
      vacationBalance = user.vacationBalance;
      sickBalance     = user.sickBalance;
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser    = null;
    vacationBalance = 0;
    sickBalance     = 0;
    _isClockedIn    = false;
    _clockInTime    = null;
    _clockOutTime   = null;
    _attendanceRecords.clear();
  }

  // ── Clock in/out state ────────────────────────────────────
  bool _isClockedIn = false;
  DateTime? _clockInTime;
  DateTime? _clockOutTime;

  bool get isClockedIn => _isClockedIn;
  DateTime? get clockInTime => _clockInTime;
  DateTime? get clockOutTime => _clockOutTime;

  // ── Attendance records (key: yyyy-MM-dd) ──────────────────
  final Map<String, Map<String, dynamic>> _attendanceRecords = {};
  Map<String, Map<String, dynamic>> get attendanceRecords => _attendanceRecords;

  void clockIn() {
    _isClockedIn  = true;
    _clockInTime  = DateTime.now();
    _clockOutTime = null;

    final today = _formatDate(DateTime.now());
    _attendanceRecords[today] = {
      'date':    DateTime.now(),
      'timeIn':  _formatTime(_clockInTime!),
      'timeOut': '–',
      'hours':   '–',
      'status':  'Present',
    };
  }

  void clockOut() {
    if (!_isClockedIn || _clockInTime == null) return;

    _clockOutTime = DateTime.now();
    _isClockedIn  = false;

    final today    = _formatDate(DateTime.now());
    final duration = _clockOutTime!.difference(_clockInTime!);
    final hours    = duration.inHours;
    final mins     = duration.inMinutes % 60;

    _attendanceRecords[today] = {
      'date':    DateTime.now(),
      'timeIn':  _formatTime(_clockInTime!),
      'timeOut': _formatTime(_clockOutTime!),
      'hours':   '${hours}h ${mins}m',
      'status':  'Present',
    };
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _formatTime(DateTime dt) {
    final hour   = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min    = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }
}


// ── Clock in/out state ────────────────────────────────────
bool _isClockedIn = false;
DateTime? _clockInTime;
DateTime? _clockOutTime;

bool get isClockedIn => _isClockedIn;
DateTime? get clockInTime => _clockInTime;
DateTime? get clockOutTime => _clockOutTime;

// ── Attendance records (key: yyyy-MM-dd) ──────────────────
final Map<String, Map<String, dynamic>> _attendanceRecords = {};
Map<String, Map<String, dynamic>> get attendanceRecords => _attendanceRecords;

void clockIn() {
  _isClockedIn = true;
  _clockInTime = DateTime.now();
  _clockOutTime = null;

  final today = _formatDate(DateTime.now());
  _attendanceRecords[today] = {
    'date': DateTime.now(),
    'timeIn': _formatTime(_clockInTime!),
    'timeOut': '–',
    'hours': '–',
    'status': 'Present',
  };
}

void clockOut() {
  if (!_isClockedIn || _clockInTime == null) return;

  _clockOutTime = DateTime.now();
  _isClockedIn = false;

  final today = _formatDate(DateTime.now());
  final duration = _clockOutTime!.difference(_clockInTime!);
  final hours = duration.inHours;
  final mins = duration.inMinutes % 60;

  _attendanceRecords[today] = {
    'date': DateTime.now(),
    'timeIn': _formatTime(_clockInTime!),
    'timeOut': _formatTime(_clockOutTime!),
    'hours': '${hours}h ${mins}m',
    'status': 'Present',
  };
}

String _formatDate(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

String _formatTime(DateTime dt) {
  final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final min = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$min $period';
}
