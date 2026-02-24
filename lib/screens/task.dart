import 'package:flutter/material.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  // ── Colors ────────────────────────────────────────────────
  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);
  static const softGray  = Color(0xFFF2F2F2);

  // ── Filters ───────────────────────────────────────────────
  String _statusFilter   = 'All';
  String _priorityFilter = 'All';
  bool   _sortByPriority = false;

  // ── Tasks ─────────────────────────────────────────────────
  final List<Map<String, dynamic>> _tasks = [
    {'title': 'Submit Q1 Report',       'description': 'Compile and submit quarterly performance report.', 'priority': 'High',   'due': 'Feb 12', 'done': false, 'tag': 'Reports'},
    {'title': 'Team Meeting Prep',       'description': 'Prepare slides and agenda for Friday team sync.',  'priority': 'Medium', 'due': 'Feb 14', 'done': false, 'tag': 'Meetings'},
    {'title': 'Update Employee Records', 'description': 'Update HR database with new hire information.',    'priority': 'Low',    'due': 'Feb 15', 'done': true,  'tag': 'Admin'},
    {'title': 'Client Proposal Draft',   'description': 'Draft proposal for the new client project.',       'priority': 'High',   'due': 'Feb 13', 'done': false, 'tag': 'Projects'},
    {'title': 'Code Review',             'description': 'Review pull requests from the engineering team.',  'priority': 'Medium', 'due': 'Feb 11', 'done': true,  'tag': 'Dev'},
    {'title': 'Onboarding Checklist',    'description': 'Complete onboarding materials for new member.',    'priority': 'Low',    'due': 'Feb 20', 'done': false, 'tag': 'HR'},
  ];

  // ── Priority ordering ─────────────────────────────────────
  static const _priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};

  // ── Filtered & sorted list ────────────────────────────────
  List<Map<String, dynamic>> get _filtered {
    List<Map<String, dynamic>> list = List.from(_tasks);
    if (_statusFilter   == 'Pending') list = list.where((t) => !t['done']).toList();
    if (_statusFilter   == 'Done')    list = list.where((t) =>  t['done']).toList();
    if (_priorityFilter != 'All')     list = list.where((t) => t['priority'] == _priorityFilter).toList();
    if (_sortByPriority) {
      list.sort((a, b) =>
          (_priorityOrder[a['priority']] ?? 3).compareTo(_priorityOrder[b['priority']] ?? 3));
    }
    return list;
  }

  // ── Counts ────────────────────────────────────────────────
  int get _pendingCount => _tasks.where((t) => !t['done']).length;
  int get _doneCount    => _tasks.where((t) =>  t['done']).length;
  int get _highCount    => _tasks.where((t) => t['priority'] == 'High'   && !t['done']).length;
  int get _mediumCount  => _tasks.where((t) => t['priority'] == 'Medium' && !t['done']).length;
  int get _lowCount     => _tasks.where((t) => t['priority'] == 'Low'    && !t['done']).length;

  Color _priorityColor(String p) {
    switch (p) {
      case 'High':   return Colors.red.shade400;
      case 'Medium': return orange;
      default:       return Colors.green.shade500;
    }
  }

  void _toggleDone(Map<String, dynamic> task) {
    setState(() {
      final idx = _tasks.indexOf(task);
      if (idx != -1) _tasks[idx]['done'] = !_tasks[idx]['done'];
    });
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [

          // ── Scrollable App Bar ───────────────────────────
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            floating: true,
            snap: true,
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: const Text('Tasks',
                style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => setState(() => _sortByPriority = !_sortByPriority),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: _sortByPriority ? navyBlue : softGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.sort_rounded,
                          size: 16,
                          color: _sortByPriority ? Colors.white : steelBlue),
                      const SizedBox(width: 4),
                      Text('Priority',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _sortByPriority ? Colors.white : steelBlue,
                          )),
                    ]),
                  ),
                ),
              ),
            ],
          ),

          // ── Progress banner ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildProgressBanner(),
            ),
          ),

          // ── Status filter chips ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _TaskFilterChip(
                    label: 'All (${_tasks.length})',
                    value: 'All', group: _statusFilter,
                    onTap: (v) => setState(() => _statusFilter = v),
                  ),
                  const SizedBox(width: 8),
                  _TaskFilterChip(
                    label: 'Pending ($_pendingCount)',
                    value: 'Pending', group: _statusFilter,
                    onTap: (v) => setState(() => _statusFilter = v),
                    color: const Color(0xFFF5A623),
                  ),
                  const SizedBox(width: 8),
                  _TaskFilterChip(
                    label: 'Done ($_doneCount)',
                    value: 'Done', group: _statusFilter,
                    onTap: (v) => setState(() => _statusFilter = v),
                    color: Colors.green.shade500,
                  ),
                ]),
              ),
            ),
          ),

          // ── Priority filter chips ────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _TaskFilterChip(
                    label: 'All',
                    value: 'All', group: _priorityFilter,
                    onTap: (v) => setState(() => _priorityFilter = v),
                    color: steelBlue,
                  ),
                  const SizedBox(width: 8),
                  _TaskFilterChip(
                    label: 'High ($_highCount)',
                    value: 'High', group: _priorityFilter,
                    onTap: (v) => setState(() => _priorityFilter = v),
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 8),
                  _TaskFilterChip(
                    label: 'Medium ($_mediumCount)',
                    value: 'Medium', group: _priorityFilter,
                    onTap: (v) => setState(() => _priorityFilter = v),
                    color: orange,
                  ),
                  const SizedBox(width: 8),
                  _TaskFilterChip(
                    label: 'Low ($_lowCount)',
                    value: 'Low', group: _priorityFilter,
                    onTap: (v) => setState(() => _priorityFilter = v),
                    color: Colors.green.shade500,
                  ),
                ]),
              ),
            ),
          ),

          // ── Empty state ──────────────────────────────────
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.task_alt_rounded,
                        size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      _statusFilter == 'Done'
                          ? 'No completed tasks yet'
                          : 'No tasks found',
                      style: const TextStyle(
                          color: Color(0xFF9E9E9E), fontSize: 14),
                    ),
                  ],
                ),
              ),
            )

          // ── Task cards ───────────────────────────────────
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildTaskCard(filtered[i]),
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),

        ],
      ),
    );
  }

  // ── Progress Banner ───────────────────────────────────────
  Widget _buildProgressBanner() {
    final total = _tasks.length;
    final done  = _doneCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [navyBlue, steelBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: navyBlue.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Today's Progress",
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text('$done of $total tasks completed',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : done / total,
                backgroundColor: Colors.white.withOpacity(0.2),
                color: orange,
                minHeight: 6,
              ),
            ),
          ]),
        ),
        const SizedBox(width: 16),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
          child: Center(
            child: Text(
              '${total == 0 ? 0 : (done / total * 100).toInt()}%',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Task Card ─────────────────────────────────────────────
  Widget _buildTaskCard(Map<String, dynamic> task) {
    final isDone        = task['done'] as bool;
    final priorityColor = _priorityColor(task['priority']);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDone ? softGray.withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? Colors.transparent : priorityColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Checkbox
        GestureDetector(
          onTap: () => _toggleDone(task),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: isDone ? Colors.green.shade500 : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone
                    ? Colors.green.shade500
                    : const Color(0xFFBDBDBD),
                width: 2,
              ),
            ),
            child: isDone
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(
                  task['title'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDone ? const Color(0xFF9E9E9E) : navyBlue,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(task['priority'],
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: priorityColor)),
              ),
            ]),
            if ((task['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(task['description'],
                  style: TextStyle(
                      fontSize: 12,
                      color: isDone
                          ? const Color(0xFFBDBDBD)
                          : steelBlue),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: Color(0xFF9E9E9E)),
              const SizedBox(width: 4),
              Text('Due ${task['due']}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9E9E9E))),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: navyBlue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(task['tag'],
                    style: const TextStyle(
                        fontSize: 10,
                        color: navyBlue,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),
        ),

        // Complete / undo button
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _toggleDone(task),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDone
                  ? Icons.undo_rounded
                  : Icons.check_circle_outline_rounded,
              size: 16,
              color: Colors.green.shade500,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Filter Chip
// ─────────────────────────────────────────────────────────────
class _TaskFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String group;
  final void Function(String) onTap;
  final Color? color;

  const _TaskFilterChip({
    required this.label,
    required this.value,
    required this.group,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final sel       = group == value;
    final chipColor = color ?? const Color(0xFF2B457B);
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? chipColor : chipColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              color: sel ? Colors.white : chipColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            )),
      ),
    );
  }
}