import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
// LocalDB
// Centralized local JSON store via SharedPreferences.
// All methods are static — call LocalDB.method() anywhere.
// ─────────────────────────────────────────────────────────────
class LocalDB {

  // ── Storage keys ──────────────────────────────────────────
  static const _kUsers      = 'db_users_v1';
  static const _kAttendance = 'db_attendance_v1';
  static const _kLeaves     = 'db_leaves_v1';
  static const _kTasks      = 'db_tasks_v1';

  // ─────────────────────────────────────────────────────────
  // UTILITIES
  // ─────────────────────────────────────────────────────────

  /// Unique ID from epoch ms.
  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  /// "yyyy-MM-dd" date key.
  static String dateKey(DateTime dt) =>
      '${dt.year}-'
          '${dt.month.toString().padLeft(2, '0')}-'
          '${dt.day.toString().padLeft(2, '0')}';

  // ─────────────────────────────────────────────────────────
  // PRIVATE GENERIC HELPERS
  // ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(key);
    if (raw == null) return [];
    final decoded = json.decode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> _writeList(
      String key, List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(list));
  }

  /// Upsert by matching [idField].
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

  /// Delete by [idField] value.
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
  // DEMO SEED
  // Seeds the demo account if it doesn't exist yet.
  // Call once at app startup (e.g. in main()).
  // ─────────────────────────────────────────────────────────
  static Future<void> seedDemoUser() async {
    const demoEmail = 'julesanesco07@gmail.com';
    final existing  = await getUserByEmail(demoEmail);
    if (existing != null) return; // already seeded

    await saveUser({
      'id':           'demo_001',
      'name':         'Jules Anesco',
      'email':        'julesanesco@gmail.com',
      'password':     'password123',
      'phone':        '+63 912 345 6789',
      'employeeId':   'EMP-00142',
      'department':   'Engineering',
      'position':     'Senior Developer',
      'vacationDays': 10,
      'sickDays':     10,
      'createdAt':    '2025-01-01T00:00:00.000',
    });
  }

  // ─────────────────────────────────────────────────────────
  // USERS
  // Schema:
  // {
  //   "id":           "demo_001",
  //   "name":         "Jules Anesco",
  //   "email":        "julesanesco07@gmail.com",
  //   "password":     "password123",
  //   "phone":        "+63 912 345 6789",
  //   "employeeId":   "EMP-00142",
  //   "department":   "Engineering",
  //   "position":     "Senior Developer",
  //   "vacationDays": 10,
  //   "sickDays":     10,
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

  static Future<void> deleteUser(String id) => _delete(_kUsers, id);

  // ─────────────────────────────────────────────────────────
  // ATTENDANCE
  // Schema:
  // {
  //   "id":        "demo_001_2025-02-25",   ← userId + date (unique per user)
  //   "userId":    "demo_001",
  //   "date":      "2025-02-25",
  //   "timeIn":    "8:00 AM",               ← null until clocked in
  //   "timeOut":   "5:00 PM",               ← null until clocked out
  //   "hours":     "9h 0m",                 ← null until clocked out
  //   "status":    "Present"                ← Present | Late | Absent | On Leave | Rest Day
  // }
  // ─────────────────────────────────────────────────────────

  static String _attendanceId(String userId, String date) => '${userId}_$date';

  static Future<List<Map<String, dynamic>>> getAttendance() =>
      _readList(_kAttendance);

  /// Save (upsert) one attendance record for a user.
  static Future<void> saveAttendanceRecord(
      Map<String, dynamic> record) async {
    // Ensure composite id is set
    if (record['id'] == null) {
      record['id'] = _attendanceId(
          record['userId'] as String, record['date'] as String);
    }
    await _upsert(_kAttendance, record);
  }

  /// All records for a specific user.
  static Future<List<Map<String, dynamic>>> getAttendanceByUser(
      String userId) async {
    final list = await getAttendance();
    return list.where((r) => r['userId'] == userId).toList();
  }

  /// Records for a specific user, year, and month.
  static Future<List<Map<String, dynamic>>> getAttendanceByMonth(
      String userId, int year, int month) async {
    final list = await getAttendanceByUser(userId);
    return list.where((r) {
      final d = DateTime.tryParse(r['date'] as String? ?? '');
      return d != null && d.year == year && d.month == month;
    }).toList();
  }

  /// Single record for a user on a specific date key ("yyyy-MM-dd").
  static Future<Map<String, dynamic>?> getAttendanceByDate(
      String userId, String date) async {
    final id = _attendanceId(userId, date);
    final list = await getAttendance();
    try {
      return list.firstWhere((r) => r['id'] == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteAttendanceRecord(
      String userId, String date) async {
    final id = _attendanceId(userId, date);
    await _delete(_kAttendance, id);
  }

  // ─────────────────────────────────────────────────────────
  // LEAVE REQUESTS
  // Schema:
  // {
  //   "id":        "1740000000000",
  //   "userId":    "demo_001",
  //   "type":      "Sick Leave",
  //   "startDate": "2025-03-01",
  //   "endDate":   "2025-03-02",
  //   "days":      2,
  //   "reason":    "Fever",
  //   "status":    "Pending",
  //   "createdAt": "2025-02-25T10:00:00.000"
  // }
  // ─────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getLeaves() =>
      _readList(_kLeaves);

  static Future<void> saveLeave(Map<String, dynamic> leave) =>
      _upsert(_kLeaves, leave);

  static Future<List<Map<String, dynamic>>> getPendingLeaves(
      String userId) async {
    final list = await getLeaves();
    return list
        .where((l) => l['userId'] == userId && l['status'] == 'Pending')
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getLeaveHistory(
      String userId) async {
    final list = await getLeaves();
    return list
        .where((l) => l['userId'] == userId && l['status'] != 'Pending')
        .toList()
      ..sort((a, b) => (b['createdAt'] as String)
          .compareTo(a['createdAt'] as String));
  }

  static Future<void> updateLeaveStatus(String id, String status) async {
    final list = await getLeaves();
    final idx  = list.indexWhere((l) => l['id'] == id);
    if (idx >= 0) {
      list[idx]['status'] = status;
      await _writeList(_kLeaves, list);
    }
  }

  static Future<void> deleteLeave(String id) => _delete(_kLeaves, id);

  // ─────────────────────────────────────────────────────────
  // TASKS
  // Schema:
  // {
  //   "id":          "1740000000001",
  //   "userId":      "demo_001",
  //   "title":       "Submit Q1 Report",
  //   "description": "Compile and submit...",
  //   "priority":    "High",
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

  static Future<void> toggleTaskDone(String id) async {
    final list = await getTasks();
    final idx  = list.indexWhere((t) => t['id'] == id);
    if (idx >= 0) {
      list[idx]['done'] = !(list[idx]['done'] as bool? ?? false);
      await _writeList(_kTasks, list);
    }
  }

  static Future<List<Map<String, dynamic>>> getTasksByUser(
      String userId) async {
    final list = await getTasks();
    return list.where((t) => t['userId'] == userId).toList();
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

  static Future<void> deleteTask(String id) => _delete(_kTasks, id);

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
    ]);
  }
}