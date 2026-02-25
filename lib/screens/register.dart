import 'package:flutter/material.dart';
import 'package:worktime/services/local_db.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  // ── Colors ────────────────────────────────────────────────
  static const navyBlue   = Color(0xFF2B457B);
  static const orange     = Color(0xFFE97638);
  static const steelBlue  = Color(0xFF4A698F);
  static const cloudWhite = Color(0xFFFFFFFF);
  static const softGray   = Color(0xFFF2F2F2);

  // ── Controllers ───────────────────────────────────────────
  final _formKey            = GlobalKey<FormState>();
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _positionController   = TextEditingController();
  final _passwordController   = TextEditingController();
  final _confirmController    = TextEditingController();

  bool    _obscurePassword = true;
  bool    _obscureConfirm  = true;
  bool    _isLoading       = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(
        parent: _animController, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
            .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Register handler ──────────────────────────────────────
  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Check if email is already taken
    final existing = await LocalDB.getUserByEmail(
        _emailController.text.trim());
    if (existing != null) {
      setState(() {
        _isLoading    = false;
        _errorMessage = 'An account with this email already exists.';
      });
      return;
    }

    // Check if Employee ID is already taken
    final allUsers = await LocalDB.getUsers();
    final idTaken  = allUsers.any((u) =>
    (u['employeeId'] as String?)?.toLowerCase() ==
        _employeeIdController.text.trim().toLowerCase());
    if (idTaken) {
      setState(() {
        _isLoading    = false;
        _errorMessage = 'This Employee ID is already registered.';
      });
      return;
    }

    // Save new user
    await LocalDB.saveUser({
      'id':           LocalDB.generateId(),
      'name':         _nameController.text.trim(),
      'email':        _emailController.text.trim(),
      'password':     _passwordController.text,
      'employeeId':   _employeeIdController.text.trim(),
      'department':   _departmentController.text.trim(),
      'position':     _positionController.text.trim(),
      'vacationDays': 12,   // default leave balances
      'sickDays':     7,
      'createdAt':    DateTime.now().toIso8601String(),
    });

    setState(() => _isLoading = false);
    if (!mounted) return;

    // Show success then go back to login
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Account created! Please sign in.'),
      backgroundColor: Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cloudWhite,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              slivers: [

                // ── Back button header ─────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                    child: Row(children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            color: navyBlue, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text('Create Account',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: navyBlue)),
                    ]),
                  ),
                ),

                // ── Subtitle ──────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 4, 24, 20),
                    child: Text(
                      'Fill in your details to get started',
                      style: TextStyle(fontSize: 13, color: steelBlue),
                    ),
                  ),
                ),

                // ── Form ──────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ── Personal info section ────
                            _SectionLabel(label: 'Personal Info'),
                            const SizedBox(height: 10),

                            _InputField(
                              controller: _nameController,
                              label: 'Full Name',
                              hint: 'e.g. Juan dela Cruz',
                              icon: Icons.person_outline_rounded,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Please enter your full name'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            _InputField(
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'you@company.com',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty)
                                  return 'Please enter your email';
                                if (!v.contains('@'))
                                  return 'Enter a valid email address';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // ── Work info section ────────
                            _SectionLabel(label: 'Work Info'),
                            const SizedBox(height: 10),

                            _InputField(
                              controller: _employeeIdController,
                              label: 'Employee ID',
                              hint: 'e.g. EMP-00200',
                              icon: Icons.badge_outlined,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Please enter your Employee ID'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            _InputField(
                              controller: _departmentController,
                              label: 'Department',
                              hint: 'e.g. Engineering',
                              icon: Icons.business_outlined,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Please enter your department'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            _InputField(
                              controller: _positionController,
                              label: 'Position',
                              hint: 'e.g. Junior Developer',
                              icon: Icons.work_outline_rounded,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Please enter your position'
                                  : null,
                            ),
                            const SizedBox(height: 24),

                            // ── Password section ─────────
                            _SectionLabel(label: 'Password'),
                            const SizedBox(height: 10),

                            _InputField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'At least 6 characters',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(() =>
                                _obscurePassword = !_obscurePassword),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: steelBlue, size: 20,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Please enter a password';
                                if (v.length < 6)
                                  return 'Password must be at least 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            _InputField(
                              controller: _confirmController,
                              label: 'Confirm Password',
                              hint: 'Re-enter your password',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscureConfirm,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(() =>
                                _obscureConfirm = !_obscureConfirm),
                                child: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: steelBlue, size: 20,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Please confirm your password';
                                if (v != _passwordController.text)
                                  return 'Passwords do not match';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // ── Error banner ─────────────
                            if (_errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.red.shade200),
                                ),
                                child: Row(children: [
                                  Icon(Icons.error_outline_rounded,
                                      color: Colors.red.shade400,
                                      size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_errorMessage!,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade600)),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // ── Register button ──────────
                            GestureDetector(
                              onTap: _isLoading ? null : _handleRegister,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                decoration: BoxDecoration(
                                  color: _isLoading
                                      ? navyBlue.withOpacity(0.7)
                                      : orange,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: orange.withOpacity(
                                          _isLoading ? 0 : 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white))
                                      : const Text('Create Account',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 0.5)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ── Already have account ─────
                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: RichText(
                                  text: const TextSpan(
                                    text: 'Already have an account?  ',
                                    style: TextStyle(
                                        fontSize: 13, color: steelBlue),
                                    children: [
                                      TextSpan(
                                        text: 'Sign In',
                                        style: TextStyle(
                                            color: orange,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 3, height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFFE97638),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A698F),
              letterSpacing: 0.3)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// Reusable Input Field
// ─────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController      controller;
  final String                     label;
  final String                     hint;
  final IconData                   icon;
  final bool                       obscureText;
  final Widget?                    suffixIcon;
  final TextInputType              keyboardType;
  final String? Function(String?)? validator;

  static const navyBlue  = Color(0xFF2B457B);
  static const steelBlue = Color(0xFF4A698F);
  static const softGray  = Color(0xFFF2F2F2);

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: steelBlue)),
        const SizedBox(height: 6),
        TextFormField(
          controller:   controller,
          obscureText:  obscureText,
          keyboardType: keyboardType,
          validator:    validator,
          style: const TextStyle(fontSize: 14, color: navyBlue),
          decoration: InputDecoration(
            hintText:  hint,
            hintStyle: const TextStyle(
                color: Color(0xFFBDBDBD), fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, color: steelBlue, size: 20),
            ),
            prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffixIcon != null
                ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon)
                : null,
            suffixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
            filled:         true,
            fillColor:      softGray,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: navyBlue, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: Colors.red.shade300, width: 1.5)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: Colors.red.shade300, width: 1.5)),
          ),
        ),
      ],
    );
  }
}