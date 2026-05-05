import 'package:flutter/material.dart';
import 'package:worktime/services/local_db.dart';

// ─────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────
const _navy  = Color(0xFF2B457B);
const _steel = Color(0xFF4A698F);
const _orange = Color(0xFFE97638);

// ─────────────────────────────────────────────────────────────
// showAssignTaskDialog
// Shows a centered popup letting a project leader assign (or
// reassign) a task to any project member.
//
// Usage:
//   await showAssignTaskDialog(
//     context: context,
//     task: task,
//     members: _members,
//     onAssigned: _loadTasks,
//   );
// ─────────────────────────────────────────────────────────────
Future<void> showAssignTaskDialog({
  required BuildContext                  context,
  required Map<String, dynamic>          task,
  required List<Map<String, dynamic>>    members,
  required Future<void> Function()       onAssigned,
}) async {
  final currentAssignee = task['assignedTo'] as String? ?? '';
  final screenH = MediaQuery.of(context).size.height;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      height: (members.length * 72.0 + 140).clamp(200.0, screenH * 0.75),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Handle ──────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),

          // ── Header ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _navy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_pin_rounded,
                    color: _navy, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Assign Task',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _navy)),
                    Text(task['title'] as String? ?? '',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9E9E9E)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF2F2F2)),

          // ── Scrollable member list ───────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: members.length,
              itemBuilder: (_, i) {
                final member     = members[i];
                final memberId   = member['id']       as String? ?? '';
                final memberName = member['name']     as String? ?? '';
                final position   = member['position'] as String? ?? '';
                final isSelected = memberId == currentAssignee;

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    LocalDB.assignTask(task['id'] as String, memberId)
                        .then((_) => onAssigned());
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _navy.withOpacity(0.06)
                          : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? _navy.withOpacity(0.3)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _navy
                              : _steel.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            memberName.isNotEmpty
                                ? memberName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : _steel),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(memberName,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? _navy
                                        : const Color(0xFF333333))),
                            if (position.isNotEmpty)
                              Text(position,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF9E9E9E))),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            size: 18, color: _navy),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}