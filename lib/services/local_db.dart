import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
// LocalDB
// Centralized local JSON database using SharedPreferences.
// All methods are static — call LocalDB.method() anywhere.
// ─────────────────────────────────────────────────────────────
class LocalDB {

  // ── Storage keys ──────────────────────────────────────────
  static const _kUsers       = 'db_users_v1';
  static const _kAttendance  = 'db_attendance_v1';
  static const _kLeaves      = 'db_leaves_v1';
  static const _kTasks       = 'db_tasks_v1';
  static const _kProjects    = 'db_projects_v1';
  static const _kCompletionRequests = 'db_completion_requests_v1';

  // ─────────────────────────────────────────────────────────
  // UTILITIES
  // ─────────────────────────────────────────────────────────

  /// Generate a unique ID using current epoch milliseconds.
  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  /// Format a DateTime to "yyyy-MM-dd" for use as a date key.
  static String dateKey(DateTime dt) =>
      '${dt.year}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')}';

  // ─────────────────────────────────────────────────────────
  // PRIVATE GENERIC HELPERS
  // ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs   = await SharedPreferences.getInstance();
    final raw     = prefs.getString(key);
    if (raw == null) return [];
    final decoded = json.decode(raw) as List<dynamic>;
    return decoded
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<void> _writeList(
      String key, List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(list));
  }

  /// Upsert by matching [idField]. Updates if found, inserts if not.
  static Future<void> _upsert(
      String key,
      Map<String, dynamic> item, {
        String idField = 'id',
      }) async {
    final list = await _readList(key);
    final idx  = list.indexWhere((e) => e[idField] == item[idField]);
    if (idx >= 0) list[idx] = item;
    else          list.add(item);
    await _writeList(key, list);
  }

  /// Delete a single item from a list by [idField] value.
  static Future<void> _delete(
      String key,
      String id, {
        String idField = 'id',
      }) async {
    final list = await _readList(key);
    list.removeWhere((e) => e[idField] == id);
    await _writeList(key, list);
  }

  // ─────────────────────────────────────────────────────────
  // USERS
  // Schema:
  // {
  //   "id":           "1740000000000",
  //   "name":         "Jules Anesco",
  //   "email":        "jules@company.com",
  //   "password":     "password123",
  //   "employeeId":   "EMP-00142",
  //   "department":   "Engineering",
  //   "position":     "Senior Developer",
  //   "vacationDays": 10,
  //   "sickDays":     10,
  //   "paternalDays": 7,
  //   "maternalDays": 105,
  //   "createdAt":    "2025-01-01T00:00:00.000"
  // }
  // ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getUsers() =>
      _readList(_kUsers);

  static Future<void> saveUser(Map<String, dynamic> user) =>
      _upsert(_kUsers, user);

  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final list = await getUsers();
    try {
      return list.firstWhere(
            (u) => (u['email'] as String).toLowerCase() == email.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserById(String id) async {
    final list = await getUsers();
    try {
      return list.firstWhere((u) => u['id'] == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteUser(String id) =>
      _delete(_kUsers, id);

  /// Seed demo user on first launch.
  /// Always upserts Jules and all team members so stale cached
  /// data (wrong position, missing members) is corrected on every launch.
  static Future<void> seedDemoUser() async {
    // ── Jules Anesco (always upsert to fix stale data) ─────
    await saveUser({
      'id':           'demo_001',
      'name':         'Jules Anesco',
      'email':        'julesanesco07@gmail.com',
      'password':     'password123',
      'phone':        '+63 912 345 6789',
      'employeeId':   'EMP-00142',
      'department':   'Engineering',
      'position':     'Senior Developer',
      'vacationDays': 10,
      'sickDays':     10,
      'paternalDays': 7,
      'maternalDays': 105,
      'emergencyDays': 3,
      'createdAt':    '2025-01-01T00:00:00.000',
    });

    // ── Team members (always upsert so they always exist) ───
    final teamMembers = <Map<String, dynamic>>[
      {
        'id':           'member_001',
        'name':         'Maria Santos',
        'email':        'maria.santos@company.com',
        'password':     'password123',
        'phone':        '+63 917 111 2222',
        'employeeId':   'EMP-00201',
        'department':   'Engineering',
        'position':     'Junior Developer',
        'vacationDays': 10,
        'sickDays':     10,
        'paternalDays': 7,
        'maternalDays': 105,
        'emergencyDays': 3,
        'createdAt':    '2025-01-02T00:00:00.000',
      },
      {
        'id':           'member_002',
        'name':         'Carlo Reyes',
        'email':        'carlo.reyes@company.com',
        'password':     'password123',
        'phone':        '+63 918 333 4444',
        'employeeId':   'EMP-00202',
        'department':   'Engineering',
        'position':     'QA Engineer',
        'vacationDays': 10,
        'sickDays':     10,
        'paternalDays': 7,
        'maternalDays': 105,
        'emergencyDays': 3,
        'createdAt':    '2025-01-03T00:00:00.000',
      },
      {
        'id':           'member_003',
        'name':         'Ana Lim',
        'email':        'ana.lim@company.com',
        'password':     'password123',
        'phone':        '+63 919 555 6666',
        'employeeId':   'EMP-00203',
        'department':   'HR',
        'position':     'HR Associate',
        'vacationDays': 10,
        'sickDays':     10,
        'paternalDays': 7,
        'maternalDays': 105,
        'emergencyDays': 3,
        'createdAt':    '2025-01-04T00:00:00.000',
      },
    ];
    for (final m in teamMembers) {
      await saveUser(m);
    }

    // Always attempt — seedNewUserData skips if tasks already exist
    await seedNewUserData('demo_001');
  }

  // ─────────────────────────────────────────────────────────
  // ATTENDANCE
  // Schema:
  // {
  //   "id":      "userId_2025-02-25",   ← composite key
  //   "userId":  "demo_001",
  //   "date":    "2025-02-25",
  //   "timeIn":  "8:00 AM",
  //   "timeOut": "5:00 PM",
  //   "hours":   "9h 0m",
  //   "status":  "Present"  ← Present | Late | Absent | On Leave | Rest Day
  // }
  // ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAttendance() =>
      _readList(_kAttendance);

  static Future<void> saveAttendanceRecord(
      Map<String, dynamic> record) =>
      _upsert(_kAttendance, record);

  /// All records for a specific user (scoped by userId).
  static Future<List<Map<String, dynamic>>> getAttendanceByUser(
      String userId) async {
    final list = await getAttendance();
    return list
        .where((r) => (r['userId'] as String? ?? '') == userId)
        .toList();
  }

  /// All records for a specific user within a year + month.
  static Future<List<Map<String, dynamic>>> getAttendanceByMonth(
      String userId, int year, int month) async {
    final list = await getAttendanceByUser(userId);
    return list.where((r) {
      final d = DateTime.tryParse(r['date'] as String? ?? '');
      return d != null && d.year == year && d.month == month;
    }).toList();
  }

  /// Single record for a specific user + date key e.g. "2025-02-25".
  static Future<Map<String, dynamic>?> getAttendanceByDate(
      String userId, String dateKey) async {
    final list = await getAttendance();
    try {
      return list.firstWhere(
            (r) =>
        (r['userId'] as String? ?? '') == userId &&
            (r['date'] as String? ?? '') == dateKey,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteAttendanceRecord(String id) =>
      _delete(_kAttendance, id);

  // ─────────────────────────────────────────────────────────
  // LEAVE REQUESTS
  // Schema:
  // {
  //   "id":        "1740000000000",
  //   "userId":    "demo_001",
  //   "type":      "Sick Leave",       ← Sick Leave | Vacation Leave
  //   "startDate": "2025-03-01",
  //   "endDate":   "2025-03-02",
  //   "dates":     "Mar 1 – Mar 2, 2025",  ← display string
  //   "days":      2,
  //   "reason":    "Fever",
  //   "status":    "Pending",          ← Pending | Approved | Rejected
  //   "appliedOn": "Feb 25, 2025",
  //   "createdAt": "2025-02-25T10:00:00.000"
  // }
  // ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getLeaves() =>
      _readList(_kLeaves);

  static Future<void> saveLeave(Map<String, dynamic> leave) =>
      _upsert(_kLeaves, leave);

  /// All leaves for a specific user.
  static Future<List<Map<String, dynamic>>> getLeavesByUser(
      String userId) async {
    final list = await getLeaves();
    return list
        .where((l) => (l['userId'] as String? ?? '') == userId)
        .toList();
  }

  /// Pending leaves for a specific user.
  static Future<List<Map<String, dynamic>>> getPendingLeaves(
      String userId) async {
    final list = await getLeavesByUser(userId);
    return list.where((l) => l['status'] == 'Pending').toList();
  }

  /// Non-pending leaves for a specific user, sorted newest first.
  static Future<List<Map<String, dynamic>>> getLeaveHistory(
      String userId) async {
    final list = await getLeavesByUser(userId);
    return list
        .where((l) => l['status'] != 'Pending')
        .toList()
      ..sort((a, b) => (b['createdAt'] as String)
          .compareTo(a['createdAt'] as String));
  }

  /// Save a leave request AND write an "On Leave" attendance record
  /// for every calendar day in [startDate..endDate].
  /// Only writes attendance if no record already exists for that day.
  static Future<void> saveLeaveWithAttendance({
    required String userId,
    required Map<String, dynamic> leave,
  }) async {
    // 1. Save the leave request itself
    await saveLeave(leave);

    // 2. Write "On Leave" attendance record for each day in range
    final start = DateTime.parse(leave['startDate'] as String);
    final end   = DateTime.parse(leave['endDate']   as String);

    for (var d = start;
    !d.isAfter(end);
    d = d.add(const Duration(days: 1))) {
      final dk         = dateKey(d);
      final existingRec = await getAttendanceByDate(userId, dk);

      // Don't overwrite an existing clock-in record
      if (existingRec != null &&
          (existingRec['timeIn'] as String? ?? '').isNotEmpty) {
        continue;
      }

      await saveAttendanceRecord({
        'id':      '${userId}_$dk',
        'userId':  userId,
        'date':    dk,
        'timeIn':  '',
        'timeOut': '',
        'hours':   '',
        'status':  'Pending Leave',
      });
    }
  }

  /// Update only the status field of a leave record.
  static Future<void> updateLeaveStatus(String id, String status) async {
    final list = await getLeaves();
    final idx  = list.indexWhere((l) => l['id'] == id);
    if (idx >= 0) {
      list[idx]['status'] = status;
      await _writeList(_kLeaves, list);
    }
  }

  /// Deduct days from user's vacation, sick, paternity, maternity, or emergency balance.
  /// type: 'Vacation Leave' | 'Sick Leave' | 'Paternity Leave' | 'Maternity Leave' | 'Emergency Leave'
  static Future<void> deductLeaveBalance(
      String userId, String type, int days) async {
    final user = await getUserById(userId);
    if (user == null) return;
    final updated = Map<String, dynamic>.from(user);
    if (type == 'Vacation Leave') {
      final current = updated['vacationDays'] as int? ?? 0;
      updated['vacationDays'] = (current - days).clamp(0, 999);
    } else if (type == 'Sick Leave') {
      final current = updated['sickDays'] as int? ?? 0;
      updated['sickDays'] = (current - days).clamp(0, 999);
    } else if (type == 'Paternity Leave') {
      final current = updated['paternalDays'] as int? ?? 0;
      updated['paternalDays'] = (current - days).clamp(0, 999);
    } else if (type == 'Maternity Leave') {
      final current = updated['maternalDays'] as int? ?? 0;
      updated['maternalDays'] = (current - days).clamp(0, 999);
    } else if (type == 'Emergency Leave') {
      final current = updated['emergencyDays'] as int? ?? 0;
      updated['emergencyDays'] = (current - days).clamp(0, 999);
    }
    await saveUser(updated);
  }

  /// Restore days back to user's balance (on cancel).
  /// type: 'Vacation Leave' | 'Sick Leave' | 'Paternity Leave' | 'Maternity Leave' | 'Emergency Leave'
  static Future<void> restoreLeaveBalance(
      String userId, String type, int days) async {
    final user = await getUserById(userId);
    if (user == null) return;
    final updated = Map<String, dynamic>.from(user);
    if (type == 'Vacation Leave') {
      final current = updated['vacationDays'] as int? ?? 0;
      updated['vacationDays'] = current + days;
    } else if (type == 'Sick Leave') {
      final current = updated['sickDays'] as int? ?? 0;
      updated['sickDays'] = current + days;
    } else if (type == 'Paternity Leave') {
      final current = updated['paternalDays'] as int? ?? 0;
      updated['paternalDays'] = current + days;
    } else if (type == 'Maternity Leave') {
      final current = updated['maternalDays'] as int? ?? 0;
      updated['maternalDays'] = current + days;
    } else if (type == 'Emergency Leave') {
      final current = updated['emergencyDays'] as int? ?? 0;
      updated['emergencyDays'] = current + days;
    }
    await saveUser(updated);
  }

  /// Delete all attendance records for a user within a date range.
  /// Used when cancelling a leave to remove "Pending Leave" stamps.
  static Future<void> deleteAttendanceRange(
      String userId, String startDate, String endDate) async {
    final start = DateTime.tryParse(startDate);
    final end   = DateTime.tryParse(endDate);
    if (start == null || end == null) return;
    final list = await getAttendance();
    list.removeWhere((r) {
      if ((r['userId'] as String? ?? '') != userId) return false;
      final d = DateTime.tryParse(r['date'] as String? ?? '');
      if (d == null) return false;
      // Only remove if status is Pending Leave or On Leave
      // (don't touch actual clock-in records)
      final status = r['status'] as String? ?? '';
      return !d.isBefore(start) &&
          !d.isAfter(end) &&
          (status == 'Pending Leave' || status == 'On Leave');
    });
    await _writeList(_kAttendance, list);
  }

  static Future<void> deleteLeave(String id) =>
      _delete(_kLeaves, id);

  // ─────────────────────────────────────────────────────────
  // TASKS
  // Schema:
  // {
  //   "id":          "1740000000001",
  //   "userId":      "demo_001",            ← owner / creator
  //   "assignedTo":  "demo_001",            ← who the task is assigned to
  //   "projectId":   "proj_001",            ← links to a project
  //   "title":       "Submit Q1 Report",
  //   "description": "Compile and submit...",
  //   "priority":    "High",   ← High | Medium | Low
  //   "due":         "2025-02-28",
  //   "done":        false,
  //   "tag":         "Reports",
  //   "createdAt":   "2025-02-25T10:00:00.000"
  // }
  // ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTasks() =>
      _readList(_kTasks);

  static Future<void> saveTask(Map<String, dynamic> task) =>
      _upsert(_kTasks, task);

  /// Seed starter data (tasks + attendance + leave history) for every new user.
  /// Guards with task count so it only runs once per user.
  static Future<void> seedNewUserData(String userId) async {
    final existing = await getTasksByUser(userId);
    if (existing.isNotEmpty) return;

    // ── Seed attendance (3 months: Jan–Mar 2026) ──────────
    Future<void> addAtt(String date, String status,
        {String timeIn = '', String timeOut = '', String hours = ''}) =>
        saveAttendanceRecord({
          'id':      '${userId}_$date',
          'userId':  userId,
          'date':    date,
          'timeIn':  timeIn,
          'timeOut': timeOut,
          'hours':   hours,
          'status':  status,
        });

    // Jan 2026
    await addAtt('2026-01-02', 'Present',  timeIn: '8:02 AM', timeOut: '5:05 PM', hours: '9h 3m');
    await addAtt('2026-01-05', 'Present',  timeIn: '7:58 AM', timeOut: '5:00 PM', hours: '9h 2m');
    await addAtt('2026-01-06', 'Late',     timeIn: '9:15 AM', timeOut: '6:00 PM', hours: '8h 45m');
    await addAtt('2026-01-07', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-01-08', 'Present',  timeIn: '8:05 AM', timeOut: '5:10 PM', hours: '9h 5m');
    await addAtt('2026-01-09', 'Absent');
    await addAtt('2026-01-12', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-01-13', 'Present',  timeIn: '7:55 AM', timeOut: '5:00 PM', hours: '9h 5m');
    await addAtt('2026-01-14', 'On Leave');
    await addAtt('2026-01-15', 'On Leave');
    await addAtt('2026-01-16', 'Present',  timeIn: '8:10 AM', timeOut: '5:15 PM', hours: '9h 5m');
    await addAtt('2026-01-19', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-01-20', 'Late',     timeIn: '9:30 AM', timeOut: '6:30 PM', hours: '9h 0m');
    await addAtt('2026-01-21', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-01-22', 'Present',  timeIn: '7:50 AM', timeOut: '5:00 PM', hours: '9h 10m');
    await addAtt('2026-01-23', 'Absent');
    await addAtt('2026-01-26', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-01-27', 'Present',  timeIn: '8:03 AM', timeOut: '5:05 PM', hours: '9h 2m');
    await addAtt('2026-01-28', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-01-29', 'Late',     timeIn: '9:05 AM', timeOut: '6:00 PM', hours: '8h 55m');
    await addAtt('2026-01-30', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    // Feb 2026
    await addAtt('2026-02-02', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-02-03', 'Present',  timeIn: '8:02 AM', timeOut: '5:05 PM', hours: '9h 3m');
    await addAtt('2026-02-04', 'Late',     timeIn: '9:20 AM', timeOut: '6:15 PM', hours: '8h 55m');
    await addAtt('2026-02-05', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-02-06', 'Present',  timeIn: '7:55 AM', timeOut: '5:00 PM', hours: '9h 5m');
    await addAtt('2026-02-09', 'Absent');
    await addAtt('2026-02-10', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-02-11', 'Present',  timeIn: '8:08 AM', timeOut: '5:10 PM', hours: '9h 2m');
    await addAtt('2026-02-12', 'On Leave');
    await addAtt('2026-02-13', 'On Leave');
    await addAtt('2026-02-16', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-02-17', 'Present',  timeIn: '8:03 AM', timeOut: '5:05 PM', hours: '9h 2m');
    await addAtt('2026-02-18', 'Late',     timeIn: '9:45 AM', timeOut: '6:45 PM', hours: '9h 0m');
    await addAtt('2026-02-19', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-02-20', 'Present',  timeIn: '7:52 AM', timeOut: '5:00 PM', hours: '9h 8m');
    await addAtt('2026-02-23', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-02-24', 'Absent');
    await addAtt('2026-02-25', 'Present',  timeIn: '8:05 AM', timeOut: '5:10 PM', hours: '9h 5m');
    await addAtt('2026-02-26', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-02-27', 'Late',     timeIn: '9:10 AM', timeOut: '6:05 PM', hours: '8h 55m');
    // Mar 2026
    await addAtt('2026-03-02', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-03-03', 'Present',  timeIn: '7:57 AM', timeOut: '5:02 PM', hours: '9h 5m');
    await addAtt('2026-03-04', 'Late',     timeIn: '9:00 AM', timeOut: '6:00 PM', hours: '9h 0m');
    await addAtt('2026-03-05', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-03-06', 'Present',  timeIn: '8:04 AM', timeOut: '5:05 PM', hours: '9h 1m');
    await addAtt('2026-03-09', 'Absent');
    await addAtt('2026-03-10', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-03-11', 'On Leave');
    await addAtt('2026-03-12', 'On Leave');
    await addAtt('2026-03-13', 'Present',  timeIn: '8:06 AM', timeOut: '5:10 PM', hours: '9h 4m');
    await addAtt('2026-03-16', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-03-17', 'Late',     timeIn: '9:25 AM', timeOut: '6:20 PM', hours: '8h 55m');
    await addAtt('2026-03-18', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-03-19', 'Present',  timeIn: '7:59 AM', timeOut: '5:01 PM', hours: '9h 2m');
    await addAtt('2026-03-20', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-03-23', 'Absent');
    await addAtt('2026-03-24', 'Present',  timeIn: '8:03 AM', timeOut: '5:05 PM', hours: '9h 2m');
    await addAtt('2026-03-25', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');
    await addAtt('2026-03-26', 'Late',     timeIn: '9:35 AM', timeOut: '6:30 PM', hours: '8h 55m');
    await addAtt('2026-03-27', 'Present',  timeIn: '8:00 AM', timeOut: '5:00 PM', hours: '9h 0m');

    // ── Seed leave history (8 past records) ───────────────
    final leaves = <Map<String, dynamic>>[
      {
        'id':        '${userId}_leave_001',
        'userId':    userId,
        'type':      'Vacation Leave',
        'startDate': '2024-12-23',
        'endDate':   '2024-12-25',
        'days':      3,
        'dates':     'Dec 23 – Dec 25, 2024',
        'appliedOn': 'Dec 10, 2024',
        'reason':    'Christmas holiday',
        'status':    'Approved',
        'createdAt': '2024-12-10T09:00:00.000',
      },
      {
        'id':        '${userId}_leave_002',
        'userId':    userId,
        'type':      'Sick Leave',
        'startDate': '2024-11-18',
        'endDate':   '2024-11-19',
        'days':      2,
        'dates':     'Nov 18 – Nov 19, 2024',
        'appliedOn': 'Nov 17, 2024',
        'reason':    'Fever and flu',
        'status':    'Approved',
        'createdAt': '2024-11-17T08:30:00.000',
      },
      {
        'id':        '${userId}_leave_003',
        'userId':    userId,
        'type':      'Vacation Leave',
        'startDate': '2024-10-28',
        'endDate':   '2024-10-30',
        'days':      3,
        'dates':     'Oct 28 – Oct 30, 2024',
        'appliedOn': 'Oct 15, 2024',
        'reason':    'Family trip',
        'status':    'Rejected',
        'createdAt': '2024-10-15T10:00:00.000',
      },
      {
        'id':        '${userId}_leave_004',
        'userId':    userId,
        'type':      'Sick Leave',
        'startDate': '2024-09-05',
        'endDate':   '2024-09-05',
        'days':      1,
        'dates':     'Sep 5, 2024',
        'appliedOn': 'Sep 4, 2024',
        'reason':    'Medical check-up',
        'status':    'Approved',
        'createdAt': '2024-09-04T07:45:00.000',
      },
      {
        'id':        '${userId}_leave_005',
        'userId':    userId,
        'type':      'Vacation Leave',
        'startDate': '2024-08-12',
        'endDate':   '2024-08-14',
        'days':      3,
        'dates':     'Aug 12 – Aug 14, 2024',
        'appliedOn': 'Aug 1, 2024',
        'reason':    'Personal errands',
        'status':    'Approved',
        'createdAt': '2024-08-01T09:15:00.000',
      },
      {
        'id':        '${userId}_leave_006',
        'userId':    userId,
        'type':      'Sick Leave',
        'startDate': '2024-07-22',
        'endDate':   '2024-07-23',
        'days':      2,
        'dates':     'Jul 22 – Jul 23, 2024',
        'appliedOn': 'Jul 21, 2024',
        'reason':    'Migraine',
        'status':    'Approved',
        'createdAt': '2024-07-21T11:00:00.000',
      },
      {
        'id':        '${userId}_leave_007',
        'userId':    userId,
        'type':      'Vacation Leave',
        'startDate': '2024-06-17',
        'endDate':   '2024-06-18',
        'days':      2,
        'dates':     'Jun 17 – Jun 18, 2024',
        'appliedOn': 'Jun 5, 2024',
        'reason':    'Rest and recharge',
        'status':    'Rejected',
        'createdAt': '2024-06-05T08:00:00.000',
      },
      {
        'id':        '${userId}_leave_008',
        'userId':    userId,
        'type':      'Sick Leave',
        'startDate': '2024-05-03',
        'endDate':   '2024-05-03',
        'days':      1,
        'dates':     'May 3, 2024',
        'appliedOn': 'May 2, 2024',
        'reason':    'Stomach ache',
        'status':    'Approved',
        'createdAt': '2024-05-02T09:30:00.000',
      },
    ];

    for (final l in leaves) {
      await saveLeave(l);
    }

    final now = DateTime.now().toIso8601String();


    // ── Seed projects ──────────────────────────────────────
    // Jules is leader on proj_1 and proj_2; member on proj_3.
    final isDemo = userId == 'demo_001';
    final List<Map<String, dynamic>> projects = [
      {
        'id':          '${userId}_proj_1',
        'title':       'Q1 Reporting & Client Work',
        'description': 'Compile quarterly reports and finalize client proposals.',
        'leaderId':    userId,
        'members':     isDemo
            ? [userId, 'member_001', 'member_002']
            : [userId],
        'assignedTo':  isDemo
            ? [userId, 'member_001', 'member_002']
            : [userId],
        'dueDate':     'Mar 20',
        'status':      'In Progress',
        'priority':    'High',
        'createdBy':   userId,
        'createdAt':   now,
      },
      {
        'id':          '${userId}_proj_2',
        'title':       'Team Operations & Dev',
        'description': 'Keep team in sync: meetings, code reviews, and engineering tasks.',
        'leaderId':    userId,
        'members':     isDemo
            ? [userId, 'member_001', 'member_002', 'member_003']
            : [userId],
        'assignedTo':  isDemo
            ? [userId, 'member_001', 'member_002', 'member_003']
            : [userId],
        'dueDate':     'Mar 25',
        'status':      'In Progress',
        'priority':    'Medium',
        'createdBy':   userId,
        'createdAt':   now,
      },
      {
        'id':          '${userId}_proj_3',
        'title':       'HR & Admin',
        'description': 'Handle employee records and onboarding for new team members.',
        'leaderId':    isDemo ? 'member_003' : userId,  // Ana leads this one
        'members':     isDemo
            ? [userId, 'member_003']
            : [userId],
        'assignedTo':  isDemo
            ? [userId, 'member_003']
            : [userId],
        'dueDate':     'Mar 28',
        'status':      'Not Started',
        'priority':    'Low',
        'createdBy':   userId,
        'createdAt':   now,
      },
    ];

    for (final proj in projects) {
      await saveProject(proj);
    }

    final List<Map<String, dynamic>> tasks = [
      {
        'id':          '${userId}_task_1',
        'userId':      userId,
        'assignedTo':  userId,             // Jules' own task
        'projectId':   '${userId}_proj_1',
        'title':       'Submit Q1 Report',
        'description': 'Compile and submit quarterly performance report.',
        'priority':    'High',
        'due':         'Mar 15',
        'done':        false,
        'inProgress':  false,
        'tag':         'Reports',
        'createdAt':   now,
      },
      {
        'id':          '${userId}_task_2',
        'userId':      userId,
        'assignedTo':  isDemo ? 'member_001' : userId,  // assigned to Maria
        'projectId':   '${userId}_proj_1',
        'title':       'Client Proposal Draft',
        'description': 'Draft proposal for the new client project.',
        'priority':    'High',
        'due':         'Mar 16',
        'done':        false,
        'inProgress':  false,
        'tag':         'Projects',
        'createdAt':   now,
      },
      {
        'id':          '${userId}_task_3',
        'userId':      userId,
        'assignedTo':  userId,             // Jules' own task
        'projectId':   '${userId}_proj_2',
        'title':       'Team Meeting Prep',
        'description': 'Prepare slides and agenda for the weekly team sync.',
        'priority':    'Medium',
        'due':         'Mar 18',
        'done':        false,
        'inProgress':  false,
        'tag':         'Meetings',
        'createdAt':   now,
      },
      {
        'id':          '${userId}_task_4',
        'userId':      userId,
        'assignedTo':  isDemo ? 'member_002' : userId,  // assigned to Carlo
        'projectId':   '${userId}_proj_2',
        'title':       'Code Review',
        'description': 'Review pull requests from the engineering team.',
        'priority':    'Medium',
        'due':         'Mar 14',
        'done':        false,
        'inProgress':  false,
        'tag':         'Dev',
        'createdAt':   now,
      },
      {
        'id':          '${userId}_task_5',
        'userId':      userId,
        'assignedTo':  isDemo ? 'member_003' : userId,  // assigned to Ana
        'projectId':   '${userId}_proj_3',
        'title':       'Update Employee Records',
        'description': 'Update HR database with new hire information.',
        'priority':    'Low',
        'due':         'Mar 20',
        'done':        false,
        'inProgress':  false,
        'tag':         'Admin',
        'createdAt':   now,
      },
      {
        'id':          '${userId}_task_6',
        'userId':      userId,
        'assignedTo':  userId,             // Jules' own task
        'projectId':   '${userId}_proj_3',
        'title':       'Onboarding Checklist',
        'description': 'Complete onboarding materials for new team member.',
        'priority':    'Low',
        'due':         'Mar 22',
        'done':        false,
        'inProgress':  false,
        'tag':         'HR',
        'createdAt':   now,
      },
    ];

    for (final task in tasks) {
      await saveTask(task);
    }
  }


  /// Called on every app launch — seeds starter tasks for any user who has none.
  /// Also re-seeds if the user only has the old-style tasks (with wrong states).
  static Future<void> seedTasksForAllUsers() async {
    final allUsers = await getUsers();
    for (final user in allUsers) {
      final userId = user['id'] as String? ?? '';
      if (userId.isEmpty) continue;

      // Remove old static seed tasks so they get re-seeded fresh
      final existing = await getTasksByUser(userId);
      final hasOldSeed = existing.any((t) =>
          (t['id'] as String? ?? '').contains('_task_'));
      if (hasOldSeed) {
        // Delete all old static seed tasks for this user
        for (final t in existing) {
          final id = t['id'] as String? ?? '';
          if (id.contains('_task_')) await deleteTask(id);
        }
      }

      await seedNewUserData(userId);
    }
  }

  /// Backfills paternalDays, maternalDays, and emergencyDays for any
  /// existing user who was saved before those fields were added.
  /// Safe to call on every launch — skips users who already have the fields.
  static Future<void> migrateLeaveBalances() async {
    final allUsers = await getUsers();
    for (final user in allUsers) {
      bool changed = false;
      final updated = Map<String, dynamic>.from(user);
      if (updated['paternalDays'] == null) {
        updated['paternalDays'] = 7;
        changed = true;
      }
      if (updated['maternalDays'] == null) {
        updated['maternalDays'] = 105;
        changed = true;
      }
      if (updated['emergencyDays'] == null) {
        updated['emergencyDays'] = 3;
        changed = true;
      }
      if (changed) await saveUser(updated);
    }
  }

  static Future<List<Map<String, dynamic>>> getTasksByUser(
      String userId) async {
    final list = await getTasks();
    return list
        .where((t) => (t['userId'] as String? ?? '') == userId)
        .toList();
  }

  static Future<void> toggleTaskDone(String id) async {
    final list = await getTasks();
    final idx  = list.indexWhere((t) => t['id'] == id);
    if (idx >= 0) {
      final isDone = !(list[idx]['done'] as bool? ?? false);
      list[idx]['done']       = isDone;
      list[idx]['inProgress'] = false; // done clears inProgress
      await _writeList(_kTasks, list);
    }
  }

  static Future<void> toggleTaskInProgress(String id) async {
    final list = await getTasks();
    final idx  = list.indexWhere((t) => t['id'] == id);
    if (idx >= 0) {
      final isInProgress = !(list[idx]['inProgress'] as bool? ?? false);
      list[idx]['inProgress'] = isInProgress;
      list[idx]['done']       = false; // inProgress clears done
      await _writeList(_kTasks, list);
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingTasks(
      String userId) async {
    final list = await getTasksByUser(userId);
    return list.where((t) => !(t['done'] as bool? ?? false)).toList();
  }

  static Future<List<Map<String, dynamic>>> getCompletedTasks(
      String userId) async {
    final list = await getTasksByUser(userId);
    return list.where((t) => t['done'] as bool? ?? false).toList();
  }

  static Future<void> deleteTask(String id) =>
      _delete(_kTasks, id);


  // ─────────────────────────────────────────────────────────
  // PROJECTS
  // Schema:
  // {
  //   "id":          "proj_001",
  //   "title":       "Q1 Performance Review",
  //   "description": "Compile and present Q1 results.",
  //   "leaderId":    "demo_001",          ← project leader user ID
  //   "members":     ["demo_001","u002"], ← all member user IDs
  //   "assignedTo":  ["demo_001","u002"], ← kept for backwards compat (same as members)
  //   "dueDate":     "Mar 31",
  //   "status":      "In Progress",   ← Not Started | In Progress | Completed | On Hold
  //   "priority":    "High",          ← High | Medium | Low
  //   "createdBy":   "admin",
  //   "createdAt":   "2025-02-25T10:00:00.000"
  // }
  // ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getProjects() =>
      _readList(_kProjects);

  static Future<void> saveProject(Map<String, dynamic> project) =>
      _upsert(_kProjects, project);

  /// Returns projects where [userId] is in the assignedTo/members list.
  static Future<List<Map<String, dynamic>>> getProjectsByUser(
      String userId) async {
    final list = await getProjects();
    return list.where((p) {
      final members  = p['members']    as List<dynamic>? ?? [];
      final assigned = p['assignedTo'] as List<dynamic>? ?? [];
      return members.contains(userId) || assigned.contains(userId);
    }).toList();
  }

  /// Returns true if [userId] is the project leader of [projectId].
  static Future<bool> isProjectLeader(
      String userId, String projectId) async {
    final list = await getProjects();
    try {
      final proj = list.firstWhere((p) => p['id'] == projectId);
      return (proj['leaderId'] as String? ?? '') == userId;
    } catch (_) {
      return false;
    }
  }

  /// Returns all member user records for a project.
  static Future<List<Map<String, dynamic>>> getProjectMembers(
      String projectId) async {
    final projects = await getProjects();
    Map<String, dynamic>? proj;
    try {
      proj = projects.firstWhere((p) => p['id'] == projectId);
    } catch (_) {
      return [];
    }
    final memberIds = <String>{
      ...(proj['members']    as List<dynamic>? ?? []).cast<String>(),
      ...(proj['assignedTo'] as List<dynamic>? ?? []).cast<String>(),
    };
    final allUsers = await getUsers();
    return allUsers
        .where((u) => memberIds.contains(u['id'] as String? ?? ''))
        .toList();
  }

  /// Assigns a task to a different user (project leader action).
  static Future<void> assignTask(
      String taskId, String assigneeUserId) async {
    final list = await getTasks();
    final idx  = list.indexWhere((t) => t['id'] == taskId);
    if (idx >= 0) {
      list[idx]['assignedTo'] = assigneeUserId;
      await _writeList(_kTasks, list);
    }
  }

  // ── Completion Requests ───────────────────────────────────
  // Schema:
  // {
  //   "id":            "cr_1234567890",
  //   "taskId":        "demo_001_task_1",
  //   "projectId":     "demo_001_proj_1",
  //   "requesterId":   "member_001",
  //   "requesterName": "Maria Santos",
  //   "taskTitle":     "Submit Q1 Report",
  //   "projectTitle":  "Q1 Reporting & Client Work",
  //   "note":          "Finished and uploaded the report.",
  //   "fileName":      "report.pdf",   ← empty string if none
  //   "fileSize":      "245 KB",
  //   "filePath":      "/path/to/file",
  //   "status":        "pending",      ← pending | approved | rejected
  //   "createdAt":     "2025-03-15T10:00:00.000",
  //   "reviewedAt":    "",             ← filled on approve/reject
  //   "reviewNote":    "",
  // }

  static Future<List<Map<String, dynamic>>> getCompletionRequests() =>
      _readList(_kCompletionRequests);

  static Future<void> saveCompletionRequest(
      Map<String, dynamic> request) =>
      _upsert(_kCompletionRequests, request);

  /// Returns all pending requests for tasks in a given project.
  static Future<List<Map<String, dynamic>>>
  getPendingRequestsForProject(String projectId) async {
    final all = await getCompletionRequests();
    return all
        .where((r) =>
    r['projectId'] == projectId &&
        (r['status'] as String? ?? '') == 'pending')
        .toList();
  }

  /// Returns the pending request for a specific task, or null.
  static Future<Map<String, dynamic>?> getPendingRequestForTask(
      String taskId) async {
    final all = await getCompletionRequests();
    try {
      return all.firstWhere((r) =>
      r['taskId'] == taskId &&
          (r['status'] as String? ?? '') == 'pending');
    } catch (_) {
      return null;
    }
  }

  /// Leader approves a completion request — marks task as done.
  static Future<void> approveCompletionRequest(
      String requestId) async {
    final requests = await getCompletionRequests();
    final idx = requests.indexWhere((r) => r['id'] == requestId);
    if (idx < 0) return;
    final updated = Map<String, dynamic>.from(requests[idx]);
    updated['status']     = 'approved';
    updated['reviewedAt'] = DateTime.now().toIso8601String();
    requests[idx] = updated;
    await _writeList(_kCompletionRequests, requests);
    // Also mark the task itself as done
    await toggleTaskDone(updated['taskId'] as String);
  }

  /// Leader rejects a completion request — task stays pending.
  static Future<void> rejectCompletionRequest(
      String requestId, {String note = ''}) async {
    final requests = await getCompletionRequests();
    final idx = requests.indexWhere((r) => r['id'] == requestId);
    if (idx < 0) return;
    final updated = Map<String, dynamic>.from(requests[idx]);
    updated['status']     = 'rejected';
    updated['reviewedAt'] = DateTime.now().toIso8601String();
    updated['reviewNote'] = note;
    requests[idx] = updated;
    await _writeList(_kCompletionRequests, requests);
  }

  /// Returns all tasks assigned to [userId] across all projects.
  static Future<List<Map<String, dynamic>>> getTasksAssignedTo(
      String userId) async {
    final list = await getTasks();
    return list
        .where((t) => (t['assignedTo'] as String? ?? '') == userId)
        .toList();
  }

  /// Backfills leaderId / members / task.assignedTo for projects that
  /// predate the project leader feature, AND force-updates the demo
  /// projects to always have the correct full member lists.
  /// Safe to call on every launch.
  static Future<void> migrateProjectLeaderFields() async {
    // ── Force-update demo project member lists ─────────────
    // These are the canonical member lists for Jules' projects.
    // We overwrite on every launch so adding new members is
    // always reflected even if projects were saved before.
    final demoProjectMembers = {
      'demo_001_proj_1': {
        'leaderId': 'demo_001',
        'members':  ['demo_001', 'member_001', 'member_002'],
        'assignedTo': ['demo_001', 'member_001', 'member_002'],
      },
      'demo_001_proj_2': {
        'leaderId': 'demo_001',
        'members':  ['demo_001', 'member_001', 'member_002', 'member_003'],
        'assignedTo': ['demo_001', 'member_001', 'member_002', 'member_003'],
      },
      'demo_001_proj_3': {
        'leaderId': 'member_003',
        'members':  ['demo_001', 'member_003'],
        'assignedTo': ['demo_001', 'member_003'],
      },
    };

    final projects = await getProjects();
    for (final proj in projects) {
      final updated = Map<String, dynamic>.from(proj);
      final projId  = proj['id'] as String? ?? '';
      bool  changed = false;

      // Apply canonical demo project overrides
      if (demoProjectMembers.containsKey(projId)) {
        final canonical = demoProjectMembers[projId]!;
        updated['leaderId']   = canonical['leaderId'];
        updated['members']    = canonical['members'];
        updated['assignedTo'] = canonical['assignedTo'];
        changed = true;
      } else {
        // Non-demo project: just backfill if fields are missing
        if (updated['leaderId'] == null || updated['leaderId'] == '') {
          updated['leaderId'] = updated['createdBy'] ?? '';
          changed = true;
        }
        if (updated['members'] == null) {
          updated['members'] = List<dynamic>.from(
              updated['assignedTo'] as List<dynamic>? ?? []);
          changed = true;
        }
      }

      if (changed) await saveProject(updated);
    }

    // ── Backfill assignedTo on tasks ───────────────────────
    // Also fix demo tasks that were saved with wrong assignedTo
    final demoTaskAssignees = {
      'demo_001_task_1': 'demo_001',
      'demo_001_task_2': 'member_001',
      'demo_001_task_3': 'demo_001',
      'demo_001_task_4': 'member_002',
      'demo_001_task_5': 'member_003',
      'demo_001_task_6': 'demo_001',
    };

    final tasks = await getTasks();
    for (final task in tasks) {
      final taskId = task['id'] as String? ?? '';
      final updated = Map<String, dynamic>.from(task);
      bool changed = false;

      if (demoTaskAssignees.containsKey(taskId)) {
        updated['assignedTo'] = demoTaskAssignees[taskId];
        changed = true;
      } else if (task['assignedTo'] == null) {
        updated['assignedTo'] = task['userId'] ?? '';
        changed = true;
      }

      if (changed) await saveTask(updated);
    }
  }

  static Future<void> deleteProject(String id) async {
    // Cascade: remove all tasks in this project first
    final tasks     = await getTasks();
    final remaining = tasks.where((t) => t['projectId'] != id).toList();
    await _writeList(_kTasks, remaining);
    await _delete(_kProjects, id);
  }

  /// Returns all tasks that belong to [projectId].
  static Future<List<Map<String, dynamic>>> getTasksByProject(
      String projectId) async {
    final list = await getTasks();
    return list
        .where((t) => (t['projectId'] as String? ?? '') == projectId)
        .toList();
  }

  // ─────────────────────────────────────────────────────────
  // CLEAR
  // ─────────────────────────────────────────────────────────

  static Future<void> clearCollection(String collection) async {
    final prefs = await SharedPreferences.getInstance();
    final key   = {
      'users':      _kUsers,
      'attendance': _kAttendance,
      'leaves':     _kLeaves,
      'tasks':      _kTasks,
      'projects':   _kProjects,
    }[collection];
    if (key != null) await prefs.remove(key);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_kUsers),
      prefs.remove(_kAttendance),
      prefs.remove(_kLeaves),
      prefs.remove(_kTasks),
      prefs.remove(_kProjects),
    ]);
  }
}