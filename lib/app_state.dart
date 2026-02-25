import 'services/local_db.dart';

// ─────────────────────────────────────────────────────────────
// AppState  —  single-instance session store
// Loaded from LocalDB on login; cleared on logout.
// ─────────────────────────────────────────────────────────────
class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // ── Current user (plain map from LocalDB) ────────────────
  Map<String, dynamic>? _user;
  Map<String, dynamic>? get currentUser => _user;
  bool get isLoggedIn => _user != null;

  // ── Convenience getters ───────────────────────────────────
  String get userId   => _user?['id']           as String? ?? '';
  String get userName => _user?['name']         as String? ?? 'User';
  String get userEmail=> _user?['email']        as String? ?? '';
  int get vacationBalance => _user?['vacationDays'] as int? ?? 0;
  int get sickBalance     => _user?['sickDays']     as int? ?? 0;

  // ── Login / Logout ────────────────────────────────────────
  /// Returns true and stores user if credentials match.
  Future<bool> login(String email, String password) async {
    final user = await LocalDB.getUserByEmail(email);
    if (user == null) return false;
    if (user['password'] != password) return false;
    _user = user;
    return true;
  }

  Future<void> logout() async {
    _user = null;
  }

  // ── Reload user from DB (e.g. after profile edit) ─────────
  Future<void> reloadUser() async {
    if (userId.isEmpty) return;
    final fresh = await LocalDB.getUserById(userId);
    if (fresh != null) _user = fresh;
  }
}