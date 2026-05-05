import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:worktime/app_state.dart';
import 'package:worktime/services/local_db.dart';

const _navy   = Color(0xFF2B457B);
const _orange = Color(0xFFE97638);
const _steel  = Color(0xFF4A698F);

Future<bool> showCompletionRequestDialog({
  required BuildContext          context,
  required Map<String, dynamic>  task,
  required String                projectTitle,
}) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CompletionRequestSheet(
      task:         task,
      projectTitle: projectTitle,
    ),
  ) ?? false;
}

class _CompletionRequestSheet extends StatefulWidget {
  final Map<String, dynamic> task;
  final String               projectTitle;

  const _CompletionRequestSheet({
    required this.task,
    required this.projectTitle,
  });

  @override
  State<_CompletionRequestSheet> createState() =>
      _CompletionRequestSheetState();
}

class _CompletionRequestSheetState extends State<_CompletionRequestSheet> {
  final _noteController = TextEditingController();
  final List<Map<String, dynamic>> _attachedFiles = []; // {name, size, bytes}
  String _visibility    = 'leader';
  bool   _confirmed     = false;
  bool   _submitting    = false;
  bool   _pickingFile   = false;

  static const _maxFiles = 3;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (_pickingFile || _attachedFiles.length >= _maxFiles) return;
    setState(() => _pickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final alreadyAdded = _attachedFiles.any((f) => f['name'] == file.name);
        if (!alreadyAdded) {
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
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  void _removeFile(int index) =>
      setState(() => _attachedFiles.removeAt(index));

  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (['jpg', 'jpeg', 'png'].contains(ext)) return Icons.image_rounded;
    if (['doc', 'docx'].contains(ext)) return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _fileIconColor(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return Colors.red.shade400;
    if (['jpg', 'jpeg', 'png'].contains(ext)) return Colors.blue.shade400;
    if (['doc', 'docx'].contains(ext)) return Colors.blue.shade700;
    return _steel;
  }

  Future<void> _submit() async {
    if (!_confirmed) return;
    setState(() => _submitting = true);

    await LocalDB.saveCompletionRequest({
      'id':          LocalDB.generateId(),
      'taskId':      widget.task['id'] as String,
      'projectId':   widget.task['projectId'] as String? ?? '',
      'submittedBy': AppState().userId,
      'note':        _noteController.text.trim(),
      'visibility':  _visibility,
      'files':       _attachedFiles.map((f) => f['name'] as String).toList(),
      'status':      'pending',
      'createdAt':   DateTime.now().toIso8601String(),
    });

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [

        // ── Navy header ──────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: const BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('COMPLETION SUBMISSION',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700,
                              color: Colors.white54, letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      const Text('Send task for leader approval',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 6),
                      Text(
                        'Completed status is locked until the project leader approves this submission.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.white.withOpacity(0.7),
                            height: 1.4),
                      ),
                    ]),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ]),
          ]),
        ),

        // ── Scrollable body ──────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Task chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _navy.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.task_alt_rounded, size: 14, color: _navy),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(widget.task['title'] as String? ?? '',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: _navy)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Completion note
                  const _Label('COMPLETION NOTE'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 14, color: _navy),
                      decoration: const InputDecoration(
                        hintText: 'Summarize what was finished, tested, or handed off.',
                        hintStyle: TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
                        contentPadding: EdgeInsets.all(14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Review visibility
                  const _Label('REVIEW VISIBILITY'),
                  const SizedBox(height: 10),
                  _VisibilityOption(
                    value: 'leader', groupValue: _visibility,
                    title: 'Project leader must review it',
                    description: 'Use this when the finished output should be seen by the project leader before approval.',
                    onChanged: (v) => setState(() => _visibility = v),
                  ),
                  const SizedBox(height: 8),
                  _VisibilityOption(
                    value: 'manager', groupValue: _visibility,
                    title: 'Manager approval only',
                    description: 'Use this when completion can be approved without the project leader inspecting the output.',
                    onChanged: (v) => setState(() => _visibility = v),
                  ),
                  const SizedBox(height: 20),

                  // ── Completion files ──────────────────────
                  Row(children: [
                    const _Label('COMPLETION FILES'),
                    const Spacer(),
                    Text(
                      '${_attachedFiles.length} / $_maxFiles files',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _attachedFiles.length >= _maxFiles
                              ? _orange
                              : const Color(0xFF9E9E9E)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  const Text(
                    'Upload finished output, screenshots, or handoff files',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                  ),
                  const SizedBox(height: 10),

                  // Attached files
                  ..._attachedFiles.asMap().entries.map((e) {
                    final idx  = e.key;
                    final file = e.value;
                    final name = file['name'] as String;
                    final size = file['size'] as String;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _fileIconColor(name).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_fileIcon(name),
                              size: 16, color: _fileIconColor(name)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _navy),
                                  overflow: TextOverflow.ellipsis),
                              Text(size,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF9E9E9E))),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _removeFile(idx),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6)),
                            child: Icon(Icons.close_rounded,
                                size: 13, color: Colors.red.shade400),
                          ),
                        ),
                      ]),
                    );
                  }),

                  // Pick file button
                  if (_attachedFiles.length < _maxFiles)
                    GestureDetector(
                      onTap: _pickingFile ? null : _pickFile,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: _steel.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _steel.withOpacity(0.2), width: 1.5),
                        ),
                        child: _pickingFile
                            ? const Center(
                            child: SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _steel)))
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.attach_file_rounded,
                                size: 16, color: _steel),
                            const SizedBox(width: 8),
                            Text(
                              _attachedFiles.isEmpty
                                  ? 'Attach File  (max $_maxFiles)'
                                  : 'Attach Another File',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _steel),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Confirmation checkbox
                  GestureDetector(
                    onTap: () => setState(() => _confirmed = !_confirmed),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              color: _confirmed ? _navy : Colors.transparent,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: _confirmed ? _navy : const Color(0xFFBDBDBD),
                                width: 2,
                              ),
                            ),
                            child: _confirmed
                                ? const Icon(Icons.check_rounded,
                                size: 13, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'I confirm this task is finished and should be reviewed for completion.',
                              style: TextStyle(fontSize: 13,
                                  color: Color(0xFF333333), height: 1.4),
                            ),
                          ),
                        ]),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  GestureDetector(
                    onTap: (_confirmed && !_submitting) ? _submit : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: _confirmed ? _orange : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _confirmed
                            ? [BoxShadow(
                            color: _orange.withOpacity(0.35),
                            blurRadius: 12, offset: const Offset(0, 4))]
                            : [],
                      ),
                      child: Center(
                        child: _submitting
                            ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                            : Text('Submit for Approval',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold,
                                color: _confirmed
                                    ? Colors.white
                                    : const Color(0xFF9E9E9E))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel',
                          style: TextStyle(color: _steel, fontSize: 14)),
                    ),
                  ),
                ]),
          ),
        ),
      ]),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final String value, groupValue, title, description;
  final void Function(String) onChanged;

  const _VisibilityOption({
    required this.value, required this.groupValue,
    required this.title,  required this.description,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _navy.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _navy.withOpacity(0.4) : const Color(0xFFEEEEEE),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 18, height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: selected ? _navy : const Color(0xFFBDBDBD), width: 2),
            ),
            child: selected
                ? Center(child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                    color: _navy, shape: BoxShape.circle)))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: selected ? _navy : const Color(0xFF333333))),
                  const SizedBox(height: 3),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9E9E9E), height: 1.4)),
                ]),
          ),
        ]),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: Color(0xFF9E9E9E), letterSpacing: 0.8));
}