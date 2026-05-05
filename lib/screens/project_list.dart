import 'package:flutter/material.dart';
import 'package:worktime/app_state.dart';
import 'package:worktime/services/local_db.dart';

class ProjectListPage extends StatefulWidget {
  const ProjectListPage({super.key});

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);

  bool   _loading  = true;
  List<Map<String, dynamic>>                  _projects       = [];
  Map<String, List<Map<String, dynamic>>>     _tasksByProject = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Called by navigation.dart on tab re-select to stay in sync
  // with any task status changes made in ProjectTasksPage.
  void refresh() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId   = AppState().userId;
    final projects = await LocalDB.getProjectsByUser(userId);

    // Fetch ALL tasks per project so counts include team members' tasks.
    final Map<String, List<Map<String, dynamic>>> tasksByProject = {};
    final allTasks = await LocalDB.getTasks();
    for (final p in projects) {
      final pid = p['id'] as String;
      tasksByProject[pid] = allTasks
          .where((t) => (t['projectId'] as String? ?? '') == pid)
          .toList();
    }

    if (!mounted) return;
    setState(() {
      _projects       = projects;
      _tasksByProject = tasksByProject;
      _loading        = false;
    });
  }

  List<Map<String, dynamic>> _tasksFor(String projectId) =>
      _tasksByProject[projectId] ?? [];

  double _progress(String projectId) {
    final pt = _tasksFor(projectId);
    if (pt.isEmpty) return 0;
    final done = pt.where((t) => t['done'] as bool? ?? false).length;
    return done / pt.length;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':    return Colors.green.shade600;
      case 'On Hold':   return orange;
      case 'Completed': return steelBlue;
      default:          return const Color(0xFF9E9E9E);
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':   return Colors.red.shade400;
      case 'Medium': return orange;
      default:       return Colors.green.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            floating: true,
            snap: true,
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: const Text('Projects',
                style: TextStyle(
                    color: navyBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ),

          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_projects.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, i) {
                    final project   = _projects[i];
                    final projectId = project['id'] as String;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ProjectCard(
                        project:       project,
                        tasks:         _tasksFor(projectId),
                        progress:      _progress(projectId),
                        statusColor:   _statusColor(project['status']    as String? ?? ''),
                        priorityColor: _priorityColor(project['priority'] as String? ?? ''),
                      ),
                    );
                  },
                  childCount: _projects.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No projects yet',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
        const SizedBox(height: 6),
        Text('Projects assigned to you will appear here.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Project Card — stateful so we can expand/collapse task list
// ─────────────────────────────────────────────────────────────
class _ProjectCard extends StatefulWidget {
  final Map<String, dynamic>       project;
  final List<Map<String, dynamic>> tasks;
  final double progress;
  final Color  statusColor;
  final Color  priorityColor;

  const _ProjectCard({
    required this.project,
    required this.tasks,
    required this.progress,
    required this.statusColor,
    required this.priorityColor,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  static const navyBlue        = Color(0xFF2B457B);
  static const orange          = Color(0xFFE97638);
  static const steelBlue       = Color(0xFF4A698F);
  static const inProgressColor = Color(0xFF7B5EA7);

  bool _expanded = false;

  int get _done       => widget.tasks.where((t) =>  (t['done']       as bool? ?? false)).length;
  int get _inProgress => widget.tasks.where((t) =>
  !(t['done'] as bool? ?? false) &&  (t['inProgress'] as bool? ?? false)).length;
  int get _pending    => widget.tasks.where((t) =>
  !(t['done'] as bool? ?? false) && !(t['inProgress'] as bool? ?? false)).length;

  String _taskStatus(Map<String, dynamic> t) {
    if (t['done']       as bool? ?? false) return 'done';
    if (t['inProgress'] as bool? ?? false) return 'inProgress';
    return 'pending';
  }

  Color _taskStatusColor(String s) {
    switch (s) {
      case 'done':        return Colors.green.shade600;
      case 'inProgress':  return inProgressColor;
      default:            return orange;
    }
  }

  Color _priorityChipColor(String p) {
    switch (p) {
      case 'High':   return Colors.red.shade400;
      case 'Medium': return orange;
      default:       return Colors.green.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name        = widget.project['title']       as String? ?? 'Untitled';
    final description = widget.project['description'] as String? ?? '';
    final status      = widget.project['status']      as String? ?? '';
    final priority    = widget.project['priority']    as String? ?? '';
    final dueDate     = widget.project['dueDate']     as String? ?? '';
    final leaderId    = widget.project['leaderId']    as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Header ──────────────────────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: navyBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder_rounded, color: navyBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: navyBlue)),
                  const SizedBox(height: 2),
                  Row(children: [
                    // Leader badge if current user leads this project
                    if (leaderId == AppState().userId) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.star_rounded, size: 9, color: orange),
                          SizedBox(width: 3),
                          Text('Leader', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: orange)),
                        ]),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(Icons.group_rounded, size: 12, color: steelBlue.withOpacity(0.5)),
                    const SizedBox(width: 3),
                    Text(
                      '${(widget.project['members'] as List<dynamic>? ?? []).length} member${(widget.project['members'] as List<dynamic>? ?? []).length == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 11, color: steelBlue.withOpacity(0.6)),
                    ),
                  ]),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: widget.statusColor)),
              ),
            ]),

            // ── Description ─────────────────────────────────
            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 14),

            // ── Progress ─────────────────────────────────────
            Row(children: [
              const Text('Progress',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: steelBlue)),
              const Spacer(),
              Text('${(widget.progress * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: navyBlue)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: widget.progress,
                minHeight: 6,
                backgroundColor: const Color(0xFFF0F0F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.progress == 1.0 ? Colors.green.shade600 : navyBlue,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Task count chips ──────────────────────────────
            Row(children: [
              _TaskCountChip(label: 'Pending',     count: _pending,    color: orange),
              const SizedBox(width: 8),
              _TaskCountChip(label: 'In Progress', count: _inProgress, color: inProgressColor),
              const SizedBox(width: 8),
              _TaskCountChip(label: 'Done',        count: _done,       color: Colors.green.shade600),
            ]),

            const SizedBox(height: 14),

            // ── Footer: priority + due date ───────────────────
            Row(children: [
              if (priority.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.priorityColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.flag_rounded, size: 11, color: widget.priorityColor),
                    const SizedBox(width: 4),
                    Text(priority,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.priorityColor)),
                  ]),
                ),
              const Spacer(),
              if (dueDate.isNotEmpty)
                Row(children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text('Due $dueDate',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ]),
            ]),
          ]),
        ),

        // ── Tasks expand/collapse toggle ──────────────────────
        if (widget.tasks.isNotEmpty)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: navyBlue.withOpacity(0.03),
                borderRadius: _expanded
                    ? BorderRadius.zero
                    : const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: const Border(
                    top: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              child: Row(children: [
                Icon(Icons.checklist_rounded, size: 15, color: steelBlue),
                const SizedBox(width: 6),
                Text(
                  '${widget.tasks.length} task${widget.tasks.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: steelBlue),
                ),
                const Spacer(),
                Text(
                  _expanded ? 'Hide tasks' : 'Show tasks',
                  style: const TextStyle(fontSize: 12, color: steelBlue),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: steelBlue),
                ),
              ]),
            ),
          ),

        // ── Expanded task list ────────────────────────────────
        if (_expanded && widget.tasks.isNotEmpty)
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              children: widget.tasks.asMap().entries.map((entry) {
                final i    = entry.key;
                final task = entry.value;
                final s    = _taskStatus(task);
                final isDone       = s == 'done';
                final isInProgress = s == 'inProgress';
                final pColor       = _priorityChipColor(task['priority'] as String? ?? 'Low');
                final isLast       = i == widget.tasks.length - 1;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : const Border(
                        bottom: BorderSide(color: Color(0xFFF5F5F5))),
                  ),
                  child: Row(children: [
                    // Status dot
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: _taskStatusColor(s),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Title
                    Expanded(
                      child: Text(
                        task['title'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDone ? const Color(0xFF9E9E9E) : navyBlue,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Due date
                    if ((task['due'] as String? ?? '').isNotEmpty)
                      Text(task['due'] as String,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400)),
                    const SizedBox(width: 8),

                    // Priority badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: pColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(task['priority'] as String? ?? '',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: pColor)),
                    ),

                    // In Progress label
                    if (isInProgress) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: inProgressColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text('In Progress',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: inProgressColor)),
                      ),
                    ],
                  ]),
                );
              }).toList(),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Task count chip
// ─────────────────────────────────────────────────────────────
class _TaskCountChip extends StatelessWidget {
  final String label;
  final int    count;
  final Color  color;

  const _TaskCountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$count',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }
}