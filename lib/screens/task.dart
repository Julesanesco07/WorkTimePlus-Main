import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/local_db.dart';
import 'package:worktime/cards/tasks/project_tasks.dart';

// ─────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────
const _navy      = Color(0xFF2B457B);
const _orange    = Color(0xFFE97638);
const _steel     = Color(0xFF4A698F);
const _softGray  = Color(0xFFF2F2F2);
const _wip       = Color(0xFF7B5EA7);

// ─────────────────────────────────────────────────────────────
// TaskPage  —  shows project cards; tapping opens task list
// ─────────────────────────────────────────────────────────────
class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => TaskPageState();
}

class TaskPageState extends State<TaskPage> {

  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _allTasks = [];
  bool   _loading       = true;
  String _statusFilter  = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Called by navigation.dart on tab re-select
  void refresh() => _load();

  // ── Load ──────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() => _loading = true);
    final uid      = AppState().userId;
    final projects = await LocalDB.getProjectsByUser(uid);
    final tasks    = await LocalDB.getTasksByUser(uid);
    if (!mounted) return;
    setState(() {
      _projects = projects;
      _allTasks = tasks;
      _loading  = false;
    });
  }

  // ── Derived data ──────────────────────────────────────────
  List<Map<String, dynamic>> get _filtered {
    if (_statusFilter == 'All') return _projects;
    return _projects
        .where((p) => (p['status'] as String? ?? '') == _statusFilter)
        .toList();
  }

  List<Map<String, dynamic>> _tasksFor(String pid) =>
      _allTasks.where((t) => t['projectId'] == pid).toList();

  int    _doneFor(String pid) =>
      _tasksFor(pid).where((t) => t['done'] == true).length;

  double _progressFor(String pid) {
    final ts = _tasksFor(pid);
    return ts.isEmpty ? 0 : _doneFor(pid) / ts.length;
  }

  // ── Banner totals ─────────────────────────────────────────
  int get _totalProjects  => _projects.length;
  int get _activeProjects =>
      _projects.where((p) => p['status'] == 'In Progress').length;
  int get _totalTasks     => _allTasks.length;
  int get _doneTasks      =>
      _allTasks.where((t) => t['done'] == true).length;

  // ── Colors ────────────────────────────────────────────────
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

  IconData _statusIcon(String s) {
    switch (s) {
      case 'In Progress': return Icons.timelapse_rounded;
      case 'Completed':   return Icons.check_circle_rounded;
      case 'On Hold':     return Icons.pause_circle_rounded;
      default:            return Icons.radio_button_unchecked_rounded;
    }
  }

  // ── Filter sheet ──────────────────────────────────────────
  Future<void> _openFilter() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SheetPicker(
        title: 'Filter Projects',
        selected: _statusFilter,
        items: [
          {'label': 'All',         'count': _projects.length,                                             'color': _navy},
          {'label': 'In Progress', 'count': _projects.where((p) => p['status'] == 'In Progress').length, 'color': _wip},
          {'label': 'Not Started', 'count': _projects.where((p) => p['status'] == 'Not Started').length, 'color': _steel},
          {'label': 'On Hold',     'count': _projects.where((p) => p['status'] == 'On Hold').length,     'color': Colors.red.shade400},
          {'label': 'Completed',   'count': _projects.where((p) => p['status'] == 'Completed').length,   'color': Colors.green.shade600},
        ],
      ),
    );
    if (result != null) setState(() => _statusFilter = result);
  }

  // ── Navigate to task list ─────────────────────────────────
  Future<void> _openProject(Map<String, dynamic> project) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectTasksPage(
          project:   project,
          onChanged: _load,
        ),
      ),
    );
    _load();
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _navy))
          : CustomScrollView(
        slivers: [

          // App Bar
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            floating: true,
            snap: true,
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: const Text('Projects & Tasks',
                style: TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded,
                      color: _steel, size: 22),
                ),
              ),
            ],
          ),

          // Summary banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildBanner(),
            ),
          ),

          // Filter row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 2, bottom: 6),
                    child: Text('STATUS',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9E9E9E),
                            letterSpacing: 0.8)),
                  ),
                  _FilterBtn(
                    value: _statusFilter,
                    isActive: _statusFilter != 'All',
                    activeColor: _statusFilter == 'All'
                        ? _navy
                        : _statusColor(_statusFilter),
                    onTap: _openFilter,
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
              child: Divider(height: 1, color: Color(0xFFF0F0F0))),

          // Count label
          if (!_loading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                child: Text(
                  '${filtered.length} project${filtered.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),

          // Empty state
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.folder_open_rounded,
                      size: 60, color: _steel.withOpacity(0.2)),
                  const SizedBox(height: 14),
                  Text(
                    _projects.isEmpty
                        ? 'No projects assigned yet'
                        : 'No projects match this filter',
                    style: TextStyle(
                        color: _steel.withOpacity(0.5),
                        fontSize: 14),
                  ),
                ]),
              ),
            )
          else
          // Project card list
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ProjectCard(
                      project:    filtered[i],
                      tasks:      _tasksFor(filtered[i]['id'] as String),
                      done:       _doneFor(filtered[i]['id'] as String),
                      progress:   _progressFor(filtered[i]['id'] as String),
                      onTap:      () => _openProject(filtered[i]),
                      isLeader:   (filtered[i]['leaderId'] as String? ?? '')
                          == AppState().userId,
                      priorityColor: _priorityColor(
                          filtered[i]['priority'] as String? ?? 'Medium'),
                      statusColor:   _statusColor(
                          filtered[i]['status']   as String? ?? 'Not Started'),
                      statusIcon:    _statusIcon(
                          filtered[i]['status']   as String? ?? 'Not Started'),
                    ),
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Summary banner ────────────────────────────────────────
  Widget _buildBanner() {
    final pct = _totalTasks == 0 ? 0.0 : _doneTasks / _totalTasks;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_navy, _steel],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _totalTasks == 0
                        ? 'No tasks assigned'
                        : _doneTasks == _totalTasks
                        ? '🎉 All tasks complete!'
                        : '$_doneTasks of $_totalTasks tasks done',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      color: _orange,
                      minHeight: 6,
                    ),
                  ),
                ]),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle),
            child: Center(
              child: Text('${(pct * 100).toInt()}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _Stat(icon: Icons.folder_rounded,    label: 'Projects', value: '$_totalProjects'),
          const SizedBox(width: 20),
          _Stat(icon: Icons.timelapse_rounded, label: 'Active',   value: '$_activeProjects'),
          const SizedBox(width: 20),
          _Stat(icon: Icons.task_alt_rounded,  label: 'Tasks',    value: '$_totalTasks'),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Project Card widget
// ─────────────────────────────────────────────────────────────
class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic>       project;
  final List<Map<String, dynamic>> tasks;
  final int                        done;
  final double                     progress;
  final VoidCallback               onTap;
  final bool                       isLeader;
  final Color                      priorityColor;
  final Color                      statusColor;
  final IconData                   statusIcon;

  const _ProjectCard({
    required this.project,
    required this.tasks,
    required this.done,
    required this.progress,
    required this.onTap,
    required this.isLeader,
    required this.priorityColor,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final title    = project['title']       as String? ?? 'Untitled Project';
    final desc     = project['description'] as String? ?? '';
    final due      = project['dueDate']     as String? ?? '—';
    final priority = project['priority']    as String? ?? 'Medium';
    final status   = project['status']      as String? ?? 'Not Started';
    final members  = (project['members'] as List<dynamic>? ?? []).length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2B457B).withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Coloured top accent bar ───────────────────
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Title + status badge
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2B457B))),
                        if (isLeader) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded,
                                      size: 11, color: _orange),
                                  SizedBox(width: 4),
                                  Text('Project Leader',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _orange)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.group_rounded,
                                size: 12, color: _steel.withOpacity(0.5)),
                            const SizedBox(width: 3),
                            Text('$members member${members == 1 ? '' : 's'}',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: _steel.withOpacity(0.6))),
                          ]),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(statusIcon, size: 11, color: statusColor),
                      const SizedBox(width: 4),
                      Text(status,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor)),
                    ]),
                  ),
                ]),

                // Description
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4A698F),
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],

                const SizedBox(height: 14),

                // Progress bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$done / ${tasks.length} tasks',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF4A698F))),
                    Text('${(progress * 100).toInt()}%',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B457B))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFF2F2F2),
                    color: progress == 1.0
                        ? Colors.green.shade500
                        : const Color(0xFFE97638),
                    minHeight: 7,
                  ),
                ),

                const SizedBox(height: 14),

                // Footer: due + priority chip + arrow
                Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 12, color: Color(0xFF9E9E9E)),
                  const SizedBox(width: 4),
                  Text('Due $due',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9E9E9E))),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(priority,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: priorityColor)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B457B).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: Color(0xFF2B457B)),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _Stat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 13, color: Colors.white70),
    const SizedBox(width: 5),
    Text('$value $label',
        style: const TextStyle(color: Colors.white70, fontSize: 12)),
  ]);
}

class _FilterBtn extends StatelessWidget {
  final String        value;
  final bool          isActive;
  final Color         activeColor;
  final VoidCallback  onTap;

  const _FilterBtn({
    required this.value,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withOpacity(0.08)
              : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? activeColor.withOpacity(0.35)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(children: [
          if (isActive)
            Container(
              width: 8, height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                  color: activeColor, shape: BoxShape.circle),
            ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? activeColor : const Color(0xFF4A698F))),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isActive ? activeColor : const Color(0xFFBDBDBD)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom-sheet picker (reused by ProjectTasksPage too)
// ─────────────────────────────────────────────────────────────
class _SheetPicker extends StatelessWidget {
  final String                     title;
  final String                     selected;
  final List<Map<String, dynamic>> items;

  const _SheetPicker({
    required this.title,
    required this.selected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B457B))),
        ),
        const SizedBox(height: 12),
        ...items.map((item) {
          final label    = item['label']    as String;
          final count    = item['count']    as int;
          final color    = item['color']    as Color;
          final subtitle = item['subtitle'] as String?;
          final isSel    = selected == label;

          return GestureDetector(
            onTap: () => Navigator.pop(context, label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: isSel
                    ? color.withOpacity(0.08)
                    : const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSel
                      ? color.withOpacity(0.35)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSel
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSel
                                  ? color
                                  : const Color(0xFF4A698F))),
                      if (subtitle != null)
                        Text(subtitle,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9E9E9E))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSel
                        ? color.withOpacity(0.12)
                        : const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$count',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSel
                              ? color
                              : const Color(0xFF9E9E9E))),
                ),
                const SizedBox(width: 8),
                Icon(
                  isSel
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 18,
                  color: isSel ? color : const Color(0xFFBDBDBD),
                ),
              ]),
            ),
          );
        }),
      ]),
    );
  }
}