import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

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

  // Each entry: { 'name': String, 'size': String, 'bytes': Uint8List }
  final List<Map<String, dynamic>> _attachedFiles = [];
  bool _pickingFile = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ── First allowed date — tomorrow at midnight ─────────────
  // Past dates and today are disabled; leave must be filed in advance.
  DateTime get _firstAllowedDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  // ── Date Pickers ──────────────────────────────────────────
  Future<void> _pickStartDate() async {
    final first  = _firstAllowedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: (_startDate != null && !_startDate!.isBefore(first))
          ? _startDate!
          : first,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
              primary: navyBlue, secondary: orange),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Reset end date if it's now before the new start
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final earliest = _startDate ?? _firstAllowedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: (_endDate != null && !_endDate!.isBefore(earliest))
          ? _endDate!
          : earliest,
      firstDate: earliest,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
              primary: navyBlue, secondary: orange),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Select date';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  // ── File Picker ───────────────────────────────────────────
  Future<void> _pickFile() async {
    if (_pickingFile) return;
    setState(() => _pickingFile = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Check for duplicates by name
        final alreadyAdded =
        _attachedFiles.any((f) => f['name'] == file.name);
        if (alreadyAdded) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${file.name} is already attached'),
              backgroundColor: orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ));
          }
          return;
        }

        // Format size
        final bytes = file.size;
        String sizeLabel;
        if (bytes >= 1024 * 1024) {
          sizeLabel = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        } else if (bytes >= 1024) {
          sizeLabel = '${(bytes / 1024).toStringAsFixed(0)} KB';
        } else {
          sizeLabel = '$bytes B';
        }

        setState(() {
          _attachedFiles.add({
            'name':  file.name,
            'size':  sizeLabel,
            'bytes': file.bytes,
            'path':  file.path ?? '',
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not open file picker: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  void _removeFile(int index) => setState(() => _attachedFiles.removeAt(index));

  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf')  return Icons.picture_as_pdf_rounded;
    if (['jpg', 'jpeg', 'png'].contains(ext)) return Icons.image_rounded;
    if (['doc', 'docx'].contains(ext)) return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _fileIconColor(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf')  return Colors.red.shade400;
    if (['jpg', 'jpeg', 'png'].contains(ext)) return Colors.blue.shade400;
    if (['doc', 'docx'].contains(ext)) return Colors.blue.shade700;
    return steelBlue;
  }

  // ── Submit ────────────────────────────────────────────────
  void _submit() {
    if (_selectedLeaveType == null ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please fill in all required fields'),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }
    widget.onSubmit(
        _selectedLeaveType!, _startDate!, _endDate!, _reasonController.text);
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
    final dayCount = (_startDate != null && _endDate != null)
        ? _endDate!.difference(_startDate!).inDays + 1
        : 0;

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
          // ── Header ─────────────────────────────────────────
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
              Text('New Leave Request',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Leave Type ──────────────────────────────────────
          const _SectionLabel(label: 'Leave Type'),
          const SizedBox(height: 8),
          _buildLeaveTypeSelector(),
          const SizedBox(height: 20),

          // ── Duration ───────────────────────────────────────
          const _SectionLabel(label: 'Duration'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _DatePickerCard(
                label: 'From',
                date: _formatDate(_startDate),
                onTap: _pickStartDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DatePickerCard(
                label: 'To',
                date: _formatDate(_endDate),
                onTap: _startDate == null ? null : _pickEndDate,
                disabled: _startDate == null,
              ),
            ),
          ]),

          // Helper hint
          if (_startDate == null) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 13, color: Color(0xFF9E9E9E)),
              const SizedBox(width: 4),
              const Text('Select a start date first',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
            ]),
          ],

          // Day count pill
          if (dayCount > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$dayCount day${dayCount == 1 ? '' : 's'} requested',
                style: const TextStyle(
                    color: orange,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // ── Reason ─────────────────────────────────────────
          const _SectionLabel(label: 'Reason (optional)'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: softGray, borderRadius: BorderRadius.circular(14)),
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
          const _SectionLabel(label: 'Supporting Files (optional)'),
          const SizedBox(height: 4),
          Text(
            'Any file type supported',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 10),
          _buildFileUploader(),
          const SizedBox(height: 20),

          // ── Submit ──────────────────────────────────────────
          GestureDetector(
            onTap: _submit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: orange,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: orange.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Center(
                child: Text('Submit Request',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Leave type selector ───────────────────────────────────
  Widget _buildLeaveTypeSelector() {
    final types = [
      {'label': 'Vacation Leave',  'icon': Icons.beach_access_rounded},
      {'label': 'Sick Leave',      'icon': Icons.medical_services_rounded},
      {'label': 'Paternity Leave', 'icon': Icons.man_rounded},
      {'label': 'Maternity Leave', 'icon': Icons.pregnant_woman_rounded},
      {'label': 'Emergency Leave', 'icon': Icons.warning_amber_rounded},
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        final label    = t['label']! as String;
        final icon     = t['icon']!  as IconData;
        final selected = _selectedLeaveType == label;
        return GestureDetector(
          onTap: () => setState(() => _selectedLeaveType = label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? navyBlue : softGray,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected ? navyBlue : Colors.transparent),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon,
                  size: 15,
                  color: selected ? Colors.white : steelBlue),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: selected ? Colors.white : steelBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ── File uploader ─────────────────────────────────────────
  Widget _buildFileUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attached file rows
        if (_attachedFiles.isNotEmpty) ...[
          ..._attachedFiles.asMap().entries.map((e) {
            final idx  = e.key;
            final file = e.value;
            final name = file['name'] as String;
            final size = file['size'] as String;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: softGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: steelBlue.withOpacity(0.15)),
              ),
              child: Row(children: [
                // File type icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _fileIconColor(name).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_fileIcon(name),
                      size: 18, color: _fileIconColor(name)),
                ),
                const SizedBox(width: 10),

                // Name + size
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: navyBlue),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(size,
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF9E9E9E))),
                      ]),
                ),

                // Remove button
                GestureDetector(
                  onTap: () => _removeFile(idx),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6)),
                    child: Icon(Icons.close_rounded,
                        size: 14, color: Colors.red.shade400),
                  ),
                ),
              ]),
            );
          }),
          const SizedBox(height: 4),
          Text('${_attachedFiles.length} file(s) attached',
              style: TextStyle(
                  fontSize: 11, color: steelBlue.withOpacity(0.6))),
          const SizedBox(height: 8),
        ],

        // Pick file button
        GestureDetector(
          onTap: _pickingFile ? null : _pickFile,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _pickingFile
                  ? steelBlue.withOpacity(0.03)
                  : steelBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: steelBlue.withOpacity(0.25), width: 1.5),
            ),
            child: _pickingFile
                ? const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: steelBlue),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.upload_file_rounded,
                    size: 18, color: steelBlue),
                const SizedBox(width: 8),
                Text(
                  _attachedFiles.isEmpty
                      ? 'Attach Supporting File'
                      : 'Attach Another File',
                  style: const TextStyle(
                      color: steelBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4A698F),
            letterSpacing: 0.3));
  }
}

class _DatePickerCard extends StatelessWidget {
  final String        label;
  final String        date;
  final VoidCallback? onTap;
  final bool          disabled;

  static const navyBlue  = Color(0xFF2B457B);
  static const steelBlue = Color(0xFF4A698F);
  static const softGray  = Color(0xFFF2F2F2);

  const _DatePickerCard({
    required this.label,
    required this.date,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: disabled ? softGray.withOpacity(0.5) : softGray,
          borderRadius: BorderRadius.circular(12),
          border: disabled
              ? Border.all(color: const Color(0xFFDDDDDD), width: 1)
              : null,
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded,
              size: 16,
              color: disabled
                  ? const Color(0xFFBDBDBD)
                  : steelBlue),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: disabled
                        ? const Color(0xFFBDBDBD)
                        : const Color(0xFF9E9E9E))),
            Text(date,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: disabled
                        ? const Color(0xFFBDBDBD)
                        : navyBlue)),
          ]),
        ]),
      ),
    );
  }
}