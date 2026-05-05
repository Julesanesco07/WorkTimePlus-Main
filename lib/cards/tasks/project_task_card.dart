import 'package:flutter/material.dart';
import 'package:worktime/services/local_db.dart';
import 'assign_task_dialog.dart';
import 'completion_request_dialog.dart';

// ─────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────
const _navy     = Color(0xFF2B457B);
const _orange   = Color(0xFFE97638);
const _steel    = Color(0xFF4A698F);
const _softGray = Color(0xFFF2F2F2);
const _wip      = Color(0xFF7B5EA7);

// ─────────────────────────────────────────────────────────────
// ProjectTaskCard
// Dismissible task card with checkbox, progress toggle,
// assignee display, and leader assign/reassign controls.
// ─────────────────────────────────────────────────────────────
class ProjectTaskCard extends StatelessWidget {
  final Map<String, dynamic>       task;
  final List<Map<String, dynamic>> members;
  final bool                       isLeader;
  final String                     currentUserId;
  final String                     projectTitle;
  final Future<void> Function()    onReload;
  final VoidCallback               onChanged;

  final bool                       hasPendingRequest;

  const ProjectTaskCard({
    super.key,
    required this.task,
    required this.members,
    required this.isLeader,
    required this.currentUserId,
    required this.projectTitle,
    required this.onReload,
    required this.onChanged,
    this.hasPendingRequest = false,
  });

  // ── Permission: only the assignee or the leader can act ──
  bool get _canAct {
    final assignedTo = task['assignedTo'] as String? ?? '';
    return isLeader || assignedTo == currentUserId;
  }

  // ── Status ───────────────────────────────────────────────
  String get _st {
    if (task['done']       as bool? ?? false) return 'done';
    if (task['inProgress'] as bool? ?? false) return 'inProgress';
    return 'pending';
  }

  bool get _isDone       => _st == 'done';
  bool get _isInProgress => _st == 'inProgress';

  // ── Colors ───────────────────────────────────────────────
  Color _priorityColor(String p) {
    switch (p) {
      case 'High':   return Colors.red.shade400;
      case 'Medium': return _orange;
      default:       return Colors.green.shade500;
    }
  }

  // ── Assignee name lookup ──────────────────────────────────
  String get _assigneeName {
    final assignedTo = task['assignedTo'] as String? ?? '';
    try {
      return members
          .firstWhere((m) => (m['id'] as String? ?? '') == assignedTo)['name']
      as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  // ── Actions ───────────────────────────────────────────────
  Future<void> _setStatus(BuildContext ctx, String newStatus) async {
    final id = task['id'] as String;

    // Non-leaders requesting "done" → show approval request dialog
    if (newStatus == 'done' && !isLeader && !_isDone) {
      final submitted = await showCompletionRequestDialog(
        context: ctx,
        task: task,
        projectTitle: projectTitle,
      );
      if (submitted) {
        // Don't mark as done yet — mark as "awaiting approval"
        // by setting inProgress so it shows a visual indicator
        // The leader will approve/reject from their view
        if (!_isInProgress) {
          await LocalDB.toggleTaskInProgress(id);
        }
        await onReload();
        onChanged();
      }
      return;
    }

    switch (newStatus) {
      case 'done':
        if (!_isDone) await LocalDB.toggleTaskDone(id);
        break;
      case 'inProgress':
        if (_isDone)        await LocalDB.toggleTaskDone(id);
        if (!_isInProgress) await LocalDB.toggleTaskInProgress(id);
        break;
      case 'pending':
        if (_isDone)       await LocalDB.toggleTaskDone(id);
        if (_isInProgress) await LocalDB.toggleTaskInProgress(id);
        break;
    }
    await onReload();
    onChanged();
  }

  Future<void> _delete(BuildContext ctx) async {
    await LocalDB.deleteTask(task['id'] as String);
    await onReload();
    onChanged();
  }

  Future<void> _assign(BuildContext ctx) async {
    await showAssignTaskDialog(
      context: ctx,
      task: task,
      members: members,
      onAssigned: () async {
        await onReload();
        onChanged();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final priority     = task['priority'] as String? ?? 'Medium';
    final pColor       = _priorityColor(priority);
    final assigneeName = _assigneeName;
    final canAct       = _canAct; // assignee or leader only

    Color borderColor;
    if (_isDone)            borderColor = Colors.transparent;
    else if (_isInProgress) borderColor = _wip.withOpacity(0.35);
    else                    borderColor = pColor.withOpacity(0.2);

    return Dismissible(
      key: ValueKey(task['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Task',
              style: TextStyle(color: _navy, fontWeight: FontWeight.bold)),
          content: Text('Delete "${task['title']}"?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: _steel))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete',
                    style: TextStyle(color: Colors.red.shade400))),
          ],
        ),
      ) ?? false,
      onDismissed: (_) => _delete(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _isDone
              ? _softGray.withOpacity(0.6)
              : _isInProgress
              ? _wip.withOpacity(0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Checkbox ────────────────────────────────
            GestureDetector(
              onTap: canAct ? () => _setStatus(context, _isDone ? 'pending' : 'done') : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: _isDone
                      ? Colors.green.shade500
                      : _isInProgress
                      ? _wip.withOpacity(0.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isDone
                        ? Colors.green.shade500
                        : _isInProgress
                        ? _wip
                        : canAct
                        ? const Color(0xFFBDBDBD)
                        : const Color(0xFFDDDDDD),
                    width: 2,
                  ),
                ),
                child: _isDone
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : _isInProgress
                    ? Icon(Icons.hourglass_top_rounded,
                    size: 12, color: _wip)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // ── Content ─────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Title + priority badge
                  Row(children: [
                    Expanded(
                      child: Text(
                        task['title'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _isDone
                              ? const Color(0xFF9E9E9E)
                              : _navy,
                          decoration: _isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: pColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(priority,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: pColor)),
                    ),
                  ]),

                  // Description
                  if ((task['description'] as String? ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(task['description'] as String,
                        style: TextStyle(
                            fontSize: 12,
                            color: _isDone
                                ? const Color(0xFFBDBDBD)
                                : _steel),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],

                  // Due + tag + in-progress chip
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 4),
                        Text('Due ${task['due'] ?? '—'}',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF9E9E9E))),
                      ]),
                      if ((task['tag'] as String? ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _navy.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(task['tag'] as String,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: _navy,
                                  fontWeight: FontWeight.w600)),
                        ),
                      if (_isInProgress)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _wip.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('In Progress',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _wip,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),

                  // Assignee row
                  if (assigneeName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          color: _steel.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            assigneeName[0].toUpperCase(),
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _steel),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(assigneeName,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9E9E9E))),
                      if (isLeader) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _assign(context),
                          child: const Text('reassign',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _orange,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ]),
                  ],

                  // Pending approval badge
                  if (hasPendingRequest) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _orange.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _orange.withOpacity(0.35),
                            width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_top_rounded,
                              size: 11, color: _orange),
                          SizedBox(width: 5),
                          Text('Awaiting Leader Approval',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _orange)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Action buttons ───────────────────────────
            const SizedBox(width: 8),
            Column(mainAxisSize: MainAxisSize.min, children: [

              // Assign button (leader, no assignee yet)
              if (isLeader && assigneeName.isEmpty) ...[
                GestureDetector(
                  onTap: () => _assign(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _orange.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _orange.withOpacity(0.3), width: 1),
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        size: 15, color: _orange),
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // ── Status dropdown ──────────────────────────
              _StatusDropdown(
                status:  _st,
                canAct:  canAct,
                onSelect: (newStatus) => _setStatus(context, newStatus),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Status dropdown button
// ─────────────────────────────────────────────────────────────
class _StatusDropdown extends StatelessWidget {
  final String   status;   // 'pending' | 'inProgress' | 'done'
  final bool     canAct;
  final void Function(String) onSelect;

  const _StatusDropdown({
    required this.status,
    required this.canAct,
    required this.onSelect,
  });

  Color get _color {
    switch (status) {
      case 'done':       return Colors.green.shade500;
      case 'inProgress': return const Color(0xFF7B5EA7);
      default:           return const Color(0xFF9E9E9E);
    }
  }

  IconData get _icon {
    switch (status) {
      case 'done':       return Icons.check_circle_rounded;
      case 'inProgress': return Icons.hourglass_top_rounded;
      default:           return Icons.radio_button_unchecked_rounded;
    }
  }

  String get _label {
    switch (status) {
      case 'done':       return 'Done';
      case 'inProgress': return 'In Progress';
      default:           return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = canAct ? _color : const Color(0xFFCCCCCC);

    return GestureDetector(
      onTap: canAct
          ? () => _showStatusMenu(context)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(_label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color)),
          const SizedBox(width: 2),
          Icon(Icons.arrow_drop_down_rounded, size: 14, color: color),
        ]),
      ),
    );
  }

  void _showStatusMenu(BuildContext context) {
    final RenderBox button =
    context.findRenderObject() as RenderBox;
    final RenderBox overlay =
    Navigator.of(context).overlay!.context.findRenderObject()
    as RenderBox;
    final offset = button.localToGlobal(
        Offset(0, button.size.height + 4),
        ancestor: overlay);

    final items = [
      {'value': 'pending',    'label': 'Pending',     'icon': Icons.radio_button_unchecked_rounded, 'color': const Color(0xFF9E9E9E)},
      {'value': 'inProgress', 'label': 'In Progress', 'icon': Icons.hourglass_top_rounded,          'color': const Color(0xFF7B5EA7)},
      {'value': 'done',       'label': 'Done',        'icon': Icons.check_circle_rounded,           'color': Colors.green.shade500},
    ];

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          offset.dx, offset.dy,
          offset.dx + button.size.width,
          offset.dy + 200),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      color: Colors.white,
      items: items.map((item) {
        final val      = item['value']  as String;
        final label    = item['label']  as String;
        final icon     = item['icon']   as IconData;
        final color    = item['color']  as Color;
        final selected = status == val;

        return PopupMenuItem<String>(
          value: val,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? color.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected ? color : const Color(0xFF333333))),
              if (selected) ...[
                const Spacer(),
                Icon(Icons.check_rounded, size: 14, color: color),
              ],
            ]),
          ),
        );
      }).toList(),
    ).then((val) {
      if (val != null && val != status) onSelect(val);
    });
  }
}