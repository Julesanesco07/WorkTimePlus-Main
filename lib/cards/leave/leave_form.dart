import 'package:flutter/material.dart';

class LeaveForm extends StatefulWidget {
  final void Function(String type, DateTime start, DateTime end, String reason) onSubmit;

  const LeaveForm({super.key, required this.onSubmit});

  @override
  State<LeaveForm> createState() => _LeaveFormState();
}

class _LeaveFormState extends State<LeaveForm> {
  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);
  static const softGray  = Color(0xFFF2F2F2);

  String?   _selectedLeaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();
  final List<Map<String, String>> _attachedFiles = [];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ── Date Picker ───────────────────────────────────────────
  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: navyBlue, secondary: orange),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Select date';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  // ── File Picker (simulated) ───────────────────────────────
  // For production: replace with FilePicker.platform.pickFiles()
  void _pickFile() {
    final fakeFiles = [
      {'name': 'medical_certificate.pdf', 'size': '245 KB'},
      {'name': 'doctor_note.jpg',         'size': '1.2 MB'},
      {'name': 'lab_result.png',          'size': '880 KB'},
      {'name': 'prescription.pdf',        'size': '112 KB'},
    ];
    final available = fakeFiles
        .where((f) => !_attachedFiles.any((a) => a['name'] == f['name']))
        .toList();
    if (available.isEmpty) return;
    setState(() => _attachedFiles.add(Map<String, String>.from(available.first)));
  }

  void _removeFile(int index) => setState(() => _attachedFiles.removeAt(index));

  IconData _fileIcon(String name) {
    if (name.endsWith('.pdf'))  return Icons.picture_as_pdf_rounded;
    if (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png'))
      return Icons.image_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _fileIconColor(String name) {
    if (name.endsWith('.pdf'))  return Colors.red.shade400;
    if (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png'))
      return Colors.blue.shade400;
    return steelBlue;
  }

  // ── Submit ────────────────────────────────────────────────
  void _submit() {
    if (_selectedLeaveType == null || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please fill in all required fields'),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }
    widget.onSubmit(_selectedLeaveType!, _startDate!, _endDate!, _reasonController.text);
    setState(() {
      _selectedLeaveType = null;
      _startDate         = null;
      _endDate           = null;
      _attachedFiles.clear();
      _reasonController.clear();
    });
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F2F2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Navy blue header ────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [navyBlue, steelBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(children: [
              Icon(Icons.edit_calendar_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'New Leave Request',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Leave Type ──────────────────────────────────────
          _SectionLabel(label: 'Leave Type'),
          const SizedBox(height: 8),
          _buildLeaveTypeSelector(),
          const SizedBox(height: 20),

          // ── Duration ───────────────────────────────────────
          _SectionLabel(label: 'Duration'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _DatePickerCard(label: 'From', date: _formatDate(_startDate), onTap: () => _pickDate(true))),
            const SizedBox(width: 12),
            Expanded(child: _DatePickerCard(label: 'To',   date: _formatDate(_endDate),   onTap: () => _pickDate(false))),
          ]),
          if (_startDate != null && _endDate != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_endDate!.difference(_startDate!).inDays + 1} day(s) requested',
                style: const TextStyle(color: orange, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // ── Reason ─────────────────────────────────────────
          _SectionLabel(label: 'Reason (optional)'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: softGray, borderRadius: BorderRadius.circular(14)),
            child: TextField(
              controller: _reasonController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14, color: navyBlue),
              decoration: const InputDecoration(
                hintText: 'Describe the reason for your leave...',
                hintStyle: TextStyle(color: Color(0xFFBDBDBD)),
                contentPadding: EdgeInsets.all(14),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Supporting Files ────────────────────────────────
          _SectionLabel(label: 'Supporting Files (optional)'),
          const SizedBox(height: 8),
          _buildFileUploader(),
          const SizedBox(height: 20),

          // ── Submit button ───────────────────────────────────
          GestureDetector(
            onTap: _submit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: orange,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: orange.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Center(
                child: Text(
                  'Submit Request',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTypeSelector() {
    final types = ['Vacation Leave', 'Sick Leave'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final selected = _selectedLeaveType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedLeaveType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? navyBlue : softGray,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? navyBlue : Colors.transparent),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: selected ? Colors.white : steelBlue,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFileUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_attachedFiles.isNotEmpty) ...[
          Column(
            children: _attachedFiles.asMap().entries.map((e) {
              final idx  = e.key;
              final file = e.value;
              final name = file['name']!;
              final size = file['size']!;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: softGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: steelBlue.withOpacity(0.15)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _fileIconColor(name).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_fileIcon(name), size: 18, color: _fileIconColor(name)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: navyBlue),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(size, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
                    ]),
                  ),
                  GestureDetector(
                    onTap: () => _removeFile(idx),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Icon(Icons.close_rounded, size: 14, color: Colors.red.shade400),
                    ),
                  ),
                ]),
              );
            }).toList(),
          ),
        ],
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: steelBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: steelBlue.withOpacity(0.25), width: 1.5),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.upload_file_rounded, size: 18, color: steelBlue),
              const SizedBox(width: 8),
              Text(
                _attachedFiles.isEmpty ? 'Attach Supporting File' : 'Attach Another File',
                style: const TextStyle(color: steelBlue, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ]),
          ),
        ),
        if (_attachedFiles.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '${_attachedFiles.length} file(s) attached',
            style: TextStyle(fontSize: 11, color: steelBlue.withOpacity(0.6)),
          ),
        ],
      ],
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4A698F), letterSpacing: 0.3),
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  final String    label;
  final String    date;
  final VoidCallback onTap;

  const _DatePickerCard({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF4A698F)),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
            Text(date,  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2B457B))),
          ]),
        ]),
      ),
    );
  }
}