import 'package:flutter/material.dart';
import 'package:worktime/services/local_db.dart';

const _navy   = Color(0xFF2B457B);
const _orange = Color(0xFFE97638);
const _steel  = Color(0xFF4A698F);

// Returns 'approved' | 'rejected' | null (dismissed)
Future<String?> showApproveTaskDialog({
  required BuildContext          context,
  required Map<String, dynamic>  task,
  required Map<String, dynamic>  request,
  required List<Map<String, dynamic>> members,
}) async {
  return await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ApproveTaskSheet(
      task:    task,
      request: request,
      members: members,
    ),
  );
}

class _ApproveTaskSheet extends StatefulWidget {
  final Map<String, dynamic>       task;
  final Map<String, dynamic>       request;
  final List<Map<String, dynamic>> members;

  const _ApproveTaskSheet({
    required this.task,
    required this.request,
    required this.members,
  });

  @override
  State<_ApproveTaskSheet> createState() => _ApproveTaskSheetState();
}

class _ApproveTaskSheetState extends State<_ApproveTaskSheet> {
  bool _processing = false;

  String get _submitterName {
    final uid = widget.request['submittedBy'] as String? ?? '';
    try {
      return widget.members
          .firstWhere((m) => (m['id'] as String? ?? '') == uid)['name']
      as String? ?? 'Team member';
    } catch (_) {
      return 'Team member';
    }
  }

  Future<void> _resolve(String decision) async {
    setState(() => _processing = true);

    // Update the completion request status
    final updated = Map<String, dynamic>.from(widget.request);
    updated['status']      = decision;
    updated['resolvedAt']  = DateTime.now().toIso8601String();
    await LocalDB.saveCompletionRequest(updated);

    // If approved → mark task as done
    if (decision == 'approved') {
      final taskId = widget.task['id'] as String;
      final tasks  = await LocalDB.getTasks();
      final idx    = tasks.indexWhere((t) => t['id'] == taskId);
      if (idx >= 0) {
        tasks[idx]['done']       = true;
        tasks[idx]['inProgress'] = false;
        await LocalDB.saveTask(tasks[idx]);
      }
    }

    if (mounted) Navigator.pop(context, decision);
  }

  @override
  Widget build(BuildContext context) {
    final note       = widget.request['note'] as String? ?? '';
    final visibility = widget.request['visibility'] as String? ?? 'leader';
    final createdAt  = widget.request['createdAt'] as String? ?? '';
    final taskTitle  = widget.task['title'] as String? ?? '';

    // Format date
    String dateStr = '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      const months = ['','Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      dateStr = '${months[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) {}

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // ── Header ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade700, Colors.green.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            const Text('REVIEW REQUEST',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: Colors.white54, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            const Text('Completion Submission',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text('$_submitterName submitted this task for your approval.',
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.8))),
          ]),
        ),

        // ── Body ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Task name
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
                      child: Text(taskTitle,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: _navy)),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),

                // Submitted by + date
                Row(children: [
                  Icon(Icons.person_outline_rounded,
                      size: 14, color: _steel.withOpacity(0.6)),
                  const SizedBox(width: 6),
                  Text(_submitterName,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: _steel)),
                  const Spacer(),
                  if (dateStr.isNotEmpty)
                    Text(dateStr,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9E9E9E))),
                ]),

                // Visibility badge
                const SizedBox(height: 8),
                Row(children: [
                  Icon(visibility == 'leader'
                      ? Icons.star_rounded
                      : Icons.admin_panel_settings_rounded,
                      size: 13, color: _orange),
                  const SizedBox(width: 5),
                  Text(
                    visibility == 'leader'
                        ? 'Leader review requested'
                        : 'Manager approval only',
                    style: const TextStyle(fontSize: 11, color: _orange,
                        fontWeight: FontWeight.w600),
                  ),
                ]),

                // Completion note
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('COMPLETION NOTE',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: Color(0xFF9E9E9E), letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Text(note,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF333333), height: 1.5)),
                  ),
                ],

                // Attached files
                if ((widget.request['files'] as List<dynamic>? ?? []).isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('COMPLETION FILES',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: Color(0xFF9E9E9E), letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  ...(widget.request['files'] as List<dynamic>).map((f) {
                    final name = f as String;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Row(children: [
                        Icon(Icons.insert_drive_file_rounded,
                            size: 14, color: _steel.withOpacity(0.6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(name,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _navy),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    );
                  }),
                ],

                const SizedBox(height: 20),

                // ── Approve / Reject buttons ─────────────────
                Row(children: [
                  // Reject
                  Expanded(
                    child: GestureDetector(
                      onTap: _processing ? null : () => _resolve('rejected'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close_rounded,
                                size: 16, color: Colors.red.shade500),
                            const SizedBox(width: 6),
                            Text('Reject',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700,
                                    color: Colors.red.shade500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Approve
                  Expanded(
                    child: GestureDetector(
                      onTap: _processing ? null : () => _resolve('approved'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.green.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: _processing
                            ? const Center(
                            child: SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white)))
                            : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded,
                                size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text('Approve',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ]),
        ),
      ]),
    );
  }
}