import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ── Colors ────────────────────────────────────────────────
  static const navyBlue   = Color(0xFF2B457B);
  static const orange     = Color(0xFFE97638);
  static const steelBlue  = Color(0xFF4A698F);
  static const cloudWhite = Color(0xFFFFFFFF);
  static const softGray   = Color(0xFFF2F2F2);

  // ── Editable profile state ────────────────────────────────
  bool _isEditing = false;

  final _nameController       = TextEditingController(text: 'John Doe');
  final _emailController      = TextEditingController(text: 'john.doe@company.com');
  final _phoneController      = TextEditingController(text: '+63 912 345 6789');
  final _departmentController = TextEditingController(text: 'Engineering');
  final _positionController   = TextEditingController(text: 'Senior Developer');
  final _employeeIdController = TextEditingController(text: 'EMP-00142');

  // ── Notification toggles ──────────────────────────────────
  bool _notifyLeave      = true;
  bool _notifyAttendance = true;
  bool _notifyTasks      = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_isEditing) {
      // Save
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile updated successfully!', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
    setState(() => _isEditing = !_isEditing);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(fontSize: 14, color: steelBlue)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: steelBlue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cloudWhite,
      appBar: AppBar(
        backgroundColor: cloudWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: navyBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile', style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _toggleEdit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _isEditing ? Colors.green.shade600 : navyBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                      size: 15,
                      color: _isEditing ? Colors.white : navyBlue,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isEditing ? 'Save' : 'Edit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _isEditing ? Colors.white : navyBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHero(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Personal Information'),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _ProfileField(label: 'Full Name',    icon: Icons.person_rounded,       controller: _nameController,    isEditing: _isEditing),
                    _ProfileField(label: 'Email',        icon: Icons.email_outlined,       controller: _emailController,   isEditing: _isEditing, keyboardType: TextInputType.emailAddress),
                    _ProfileField(label: 'Phone',        icon: Icons.phone_rounded,        controller: _phoneController,   isEditing: _isEditing, keyboardType: TextInputType.phone),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Work Information'),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _ProfileField(label: 'Employee ID',  icon: Icons.badge_rounded,         controller: _employeeIdController, isEditing: false),
                    _ProfileField(label: 'Department',   icon: Icons.business_rounded,      controller: _departmentController, isEditing: _isEditing),
                    _ProfileField(label: 'Position',     icon: Icons.work_outline_rounded,  controller: _positionController,   isEditing: _isEditing),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Notifications'),
                  const SizedBox(height: 12),
                  _buildNotificationsCard(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Account'),
                  const SizedBox(height: 12),
                  _buildAccountCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Profile Hero ──────────────────────────────────────────
  Widget _buildProfileHero() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [navyBlue, steelBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: navyBlue,
                ),
                child: const Center(
                  child: Text(
                    'JD',
                    style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (_isEditing)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _nameController.text,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _positionController.text,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _employeeIdController.text,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          // Stats strip
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _HeroStat(value: '3.2', label: 'Yrs Tenure'),
                _VertDivider(),
                _HeroStat(value: '97%', label: 'Attendance'),
                _VertDivider(),
                _HeroStat(value: '12',  label: 'Leave Days'),
                _VertDivider(),
                _HeroStat(value: '14',  label: 'Tasks Done'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Wave clip
          ClipPath(
            clipper: _WaveClipper(),
            child: Container(height: 32, color: cloudWhite),
          ),
        ],
      ),
    );
  }

  // ── Notifications Card ────────────────────────────────────
  Widget _buildNotificationsCard() {
    return Container(
      decoration: BoxDecoration(
        color: cloudWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: softGray, width: 1.5),
      ),
      child: Column(
        children: [
          _ToggleRow(
            icon: Icons.beach_access_rounded,
            iconColor: steelBlue,
            label: 'Leave Approvals',
            subtitle: 'Get notified when leave status changes',
            value: _notifyLeave,
            onChanged: (v) => setState(() => _notifyLeave = v),
          ),
          _Divider(),
          _ToggleRow(
            icon: Icons.calendar_month_rounded,
            iconColor: orange,
            label: 'Attendance Alerts',
            subtitle: 'Reminders for clock-in and clock-out',
            value: _notifyAttendance,
            onChanged: (v) => setState(() => _notifyAttendance = v),
          ),
          _Divider(),
          _ToggleRow(
            icon: Icons.task_alt_rounded,
            iconColor: navyBlue,
            label: 'Task Reminders',
            subtitle: 'Alerts for upcoming task deadlines',
            value: _notifyTasks,
            onChanged: (v) => setState(() => _notifyTasks = v),
          ),
        ],
      ),
    );
  }

  // ── Account Card ──────────────────────────────────────────
  Widget _buildAccountCard() {
    return Container(
      decoration: BoxDecoration(
        color: cloudWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: softGray, width: 1.5),
      ),
      child: Column(
        children: [
          _AccountRow(
            icon: Icons.lock_outline_rounded,
            iconColor: steelBlue,
            label: 'Change Password',
            onTap: () {},
          ),
          _Divider(),
          _AccountRow(
            icon: Icons.privacy_tip_outlined,
            iconColor: steelBlue,
            label: 'Privacy Policy',
            onTap: () {},
          ),
          _Divider(),
          _AccountRow(
            icon: Icons.help_outline_rounded,
            iconColor: steelBlue,
            label: 'Help & Support',
            onTap: () {},
          ),
          _Divider(),
          _AccountRow(
            icon: Icons.logout_rounded,
            iconColor: Colors.red.shade400,
            label: 'Sign Out',
            labelColor: Colors.red.shade400,
            onTap: _showLogoutDialog,
            showArrow: false,
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: navyBlue, letterSpacing: 0.2),
    );
  }

  Widget _buildInfoCard(List<Widget> fields) {
    return Container(
      decoration: BoxDecoration(
        color: cloudWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: softGray, width: 1.5),
      ),
      child: Column(
        children: fields.asMap().entries.map((e) {
          return Column(
            children: [
              e.value,
              if (e.key < fields.length - 1) _Divider(),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Wave Clipper ──────────────────────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.75, 0, size.width, size.height * 0.5);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}

// ── Reusable sub-widgets ──────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ]),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2));
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2), indent: 16, endIndent: 16);
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool isEditing;
  final TextInputType keyboardType;

  static const navyBlue  = Color(0xFF2B457B);
  static const steelBlue = Color(0xFF4A698F);
  static const softGray  = Color(0xFFF2F2F2);
  static const orange    = Color(0xFFE97638);

  const _ProfileField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.isEditing,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: steelBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: steelBlue, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                isEditing
                    ? TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: navyBlue),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: softGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: navyBlue, width: 1.5),
                    ),
                  ),
                )
                    : Text(
                  controller.text,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: navyBlue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   label;
  final String   subtitle;
  final bool     value;
  final void Function(bool) onChanged;

  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: navyBlue)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
        ])),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: orange,
          activeTrackColor: orange.withOpacity(0.3),
        ),
      ]),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   label;
  final Color?   labelColor;
  final VoidCallback onTap;
  final bool     showArrow;

  static const navyBlue  = Color(0xFF2B457B);
  static const steelBlue = Color(0xFF4A698F);

  const _AccountRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: labelColor ?? navyBlue))),
          if (showArrow)
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9E9E9E)),
        ]),
      ),
    );
  }
}