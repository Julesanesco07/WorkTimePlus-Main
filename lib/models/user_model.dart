// ── Attendance Record ─────────────────────────────────────────
class AttendanceRecord {
  final DateTime date;
  final String timeIn;
  final String timeOut;
  final String hours;
  final String status;

  const AttendanceRecord({
    required this.date,
    required this.timeIn,
    required this.timeOut,
    required this.hours,
    required this.status,
  });

  static String fmt(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static Map<String, AttendanceRecord> buildSampleData() {
    final m   = <String, AttendanceRecord>{};
    final now = DateTime.now();
    final y   = now.year;
    final mth = now.month;

    void add(int y, int mo, int d, String s,
        {String ti = '—', String to = '—', String h = '—'}) {
      final dt = DateTime(y, mo, d);
      m[fmt(dt)] = AttendanceRecord(
        date: dt, timeIn: ti, timeOut: to, hours: h, status: s,
      );
    }

    add(y, mth, 1, 'Rest Day');
    add(y, mth, 2, 'Present', ti: '08:00 AM', to: '05:00 PM', h: '9h');
    add(y, mth, 3, 'Late',    ti: '09:00 AM', to: '05:00 PM', h: '8h');
    add(y, mth, 4, 'Absent');
    add(y, mth, 5, 'On Leave');

    return m;
  }
}

// ── Demo User ─────────────────────────────────────────────────
class DemoUser {
  final String id;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String position;
  final String department;
  final String employeeId;
  final int vacationBalance;
  final int sickBalance;

  const DemoUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.position,
    required this.department,
    required this.employeeId,
    required this.vacationBalance,
    required this.sickBalance,
  });

  // ── Registered demo accounts ────────────────────────────────
  static final List<DemoUser> users = [
    DemoUser(
      id: 'demo_001',
      name: 'Jules Anesco',
      email: 'julesanesco07@gmail.com',
      password: 'password123',
      phone: '+63 912 345 6789',
      position: 'Senior Developer',
      department: 'Engineering',
      employeeId: 'EMP-00142',
      vacationBalance: 12,
      sickBalance: 7,
    ),
  ];

  // Returns the matching user or null if credentials are wrong
  static DemoUser? authenticate(String email, String password) {
    for (final user in users) {
      if (user.email.toLowerCase() == email.toLowerCase() &&
          user.password == password) {
        return user;
      }
    }
    return null;
  }

  // Returns the user by email — always reads fresh from the list
  static DemoUser? findByEmail(String email) {
    for (final user in users) {
      if (user.email.toLowerCase() == email.toLowerCase()) return user;
    }
    return null;
  }
}