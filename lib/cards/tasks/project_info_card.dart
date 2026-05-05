import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────
const _navy   = Color(0xFF2B457B);
const _orange = Color(0xFFE97638);
const _steel  = Color(0xFF4A698F);
const _wip    = Color(0xFF7B5EA7);

// ─────────────────────────────────────────────────────────────
// ProjectInfoCard
// Gradient card showing project description, meta badges,
// progress bar, and team members list.
// ─────────────────────────────────────────────────────────────
class ProjectInfoCard extends StatelessWidget {
  final Map<String, dynamic>       project;
  final List<Map<String, dynamic>> members;
  final int    doneCount;
  final int    totalTasks;
  final double progress;

  const ProjectInfoCard({
    super.key,
    required this.project,
    required this.members,
    required this.doneCount,
    required this.totalTasks,
    required this.progress,
  });

  Color _priorityColor(String p) {
    switch (p) {
      case 'High':   return Colors.red.shade400;
      case 'Medium': return _orange;
      default:       return Colors.green.shade500;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'In Progress': return _wip;
      case 'Completed':   return Colors.green.shade600;
      case 'On Hold':     return Colors.red.shade400;
      default:            return _steel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final desc     = project['description'] as String? ?? '';
    final due      = project['dueDate']     as String? ?? '—';
    final priority = project['priority']    as String? ?? 'Medium';
    final status   = project['status']      as String? ?? 'Not Started';
    final leaderId = project['leaderId']    as String? ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, _steel],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Description
          if (desc.isNotEmpty) ...[
            Text(desc,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
          ],

          // Meta badges
          Wrap(spacing: 8, runSpacing: 4, children: [
            _MetaBadge(
                icon: Icons.calendar_today_rounded,
                label: 'Due $due'),
            _MetaBadge(
                icon: Icons.flag_rounded,
                label: priority,
                color: _priorityColor(priority)),
            _MetaBadge(
                icon: Icons.circle,
                label: status,
                color: _statusColor(status)),
          ]),
          const SizedBox(height: 8),

          // Progress bar
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  color: _orange,
                  minHeight: 5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('$doneCount / $totalTasks',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ]),

          // Team section
          if (members.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TEAM',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white54,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  ...members.map((m) {
                    final mId   = m['id']       as String? ?? '';
                    final mName = m['name']     as String? ?? '';
                    final mPos  = m['position'] as String? ?? '';
                    final isLdr = mId == leaderId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(children: [
                        // Avatar
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: isLdr
                                ? _orange
                                : Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              mName.isNotEmpty
                                  ? mName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            mPos.isNotEmpty
                                ? '$mName · $mPos'
                                : mName,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Leader badge
                        if (isLdr)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _orange,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 9, color: Colors.white),
                                SizedBox(width: 2),
                                Text('Leader',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                      ]),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Meta badge used inside the card ──────────────────────────
class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color?   color;

  const _MetaBadge({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color ?? Colors.white70),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 11)),
    ]),
  );
}