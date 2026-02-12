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
  // Status filter: All | Pending | Done
  String _statusFilter   = 'All';
  // Priority filter: All | High | Medium | Low
  String _priorityFilter = 'All';
  // Sort by priority (High → Medium → Low)
  bool _sortByPriority   = false;

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

    // Status filter
    if (_statusFilter == 'Pending') list = list.where((t) => !t['done']).toList();
    if (_statusFilter == 'Done')    list = list.where((t) =>  t['done']).toList();

    // Priority filter
    if (_priorityFilter != 'All')   list = list.where((t) => t['priority'] == _priorityFilter).toList();

    // Sort by priority
    if (_sortByPriority) {
      list.sort((a, b) =>
          (_priorityOrder[a['priority']] ?? 3).compareTo(_priorityOrder[b['priority']] ?? 3));
    }

    return list;
  }

  // ── Counts ────────────────────────────────────────────────
  int get _pendingCount  => _tasks.where((t) => !t['done']).length;
  int get _doneCount     => _tasks.where((t) =>  t['done']).length;
  int get _highCount     => _tasks.where((t) => t['priority'] == 'High'   && !t['done']).length;
  int get _mediumCount   => _tasks.where((t) => t['priority'] == 'Medium' && !t['done']).length;
  int get _lowCount      => _tasks.where((t) => t['priority'] == 'Low'    && !t['done']).length;

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':   return Colors.red.shade400;
      case 'Medium': return orange;
      default:       return Colors.green.shade500;
    }
  }

  // ── Handlers ─────────────────────────────────────────────
  void _toggleDone(Map<String, dynamic> task) {
    setState(() {
      final idx = _tasks.indexOf(task);
      if (idx != -1) _tasks[idx]['done'] = !_tasks[idx]['done'];
    });
  }

  void _deleteTask(Map<String, dynamic> task) {
    final idx = _tasks.indexOf(task);
    if (idx == -1) return;
    final removed = Map<String, dynamic>.from(_tasks[idx]);
    setState(() => _tasks.removeAt(idx));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Deleted "${removed['title']}"', style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.red.shade400,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'Undo',
        textColor: Colors.white,
        onPressed: () => setState(() => _tasks.insert(idx, removed)),
      ),
    ));
  }

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddTaskSheet(
        onAdd: (title, priority, due) {
          setState(() {
            _tasks.insert(0, {
              'title': title, 'description': '', 'priority': priority,
              'due': due, 'done': false, 'tag': 'General',
            });
          });
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Tasks', style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold)),
        actions: [
          // Sort toggle
          Padding(
            padding: const EdgeInsets.only(right: 4),
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
                  Icon(Icons.sort_rounded, size: 16, color: _sortByPriority ? Colors.white : steelBlue),
                  const SizedBox(width: 4),
                  Text('Priority', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: _sortByPriority ? Colors.white : steelBlue,
                  )),
                ]),
              ),
            ),
          ),
          // Add button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _showAddTaskSheet,
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Progress banner
        _buildProgressBanner(),
        const SizedBox(height: 12),

        // ── Status filter chips ───────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FilterChip(label: 'All (${_tasks.length})',     value: 'All',     group: _statusFilter,   onTap: (v) => setState(() => _statusFilter = v)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Pending ($_pendingCount)',   value: 'Pending', group: _statusFilter,   onTap: (v) => setState(() => _statusFilter = v)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Done ($_doneCount)',         value: 'Done',    group: _statusFilter,   onTap: (v) => setState(() => _statusFilter = v)),
            ]),
          ),
        ),
        const SizedBox(height: 8),

        // ── Priority filter chips ─────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FilterChip(label: 'All Priority',   value: 'All',    group: _priorityFilter, onTap: (v) => setState(() => _priorityFilter = v), color: steelBlue),
              const SizedBox(width: 8),
              _FilterChip(label: '🔴 High ($_highCount)',   value: 'High',   group: _priorityFilter, onTap: (v) => setState(() => _priorityFilter = v), color: Colors.red.shade400),
              const SizedBox(width: 8),
              _FilterChip(label: '🟠 Medium ($_mediumCount)', value: 'Medium', group: _priorityFilter, onTap: (v) => setState(() => _priorityFilter = v), color: orange),
              const SizedBox(width: 8),
              _FilterChip(label: '🟢 Low ($_lowCount)',    value: 'Low',    group: _priorityFilter, onTap: (v) => setState(() => _priorityFilter = v), color: Colors.green.shade500),
            ]),
          ),
        ),
        const SizedBox(height: 10),

        // ── Task list ─────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _buildTaskCard(filtered[i]),
          ),
        ),
      ]),
    );
  }

  // ── Progress Banner ───────────────────────────────────────
  Widget _buildProgressBanner() {
    final total = _tasks.length;
    final done  = _doneCount;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [navyBlue, steelBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: navyBlue.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Today's Progress", style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text('$done of $total tasks completed',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
        ])),
        const SizedBox(width: 16),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
          child: Center(child: Text(
            '${total == 0 ? 0 : (done / total * 100).toInt()}%',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          )),
        ),
      ]),
    );
  }

  // ── Task Card ─────────────────────────────────────────────
  Widget _buildTaskCard(Map<String, dynamic> task) {
    final isDone        = task['done'] as bool;
    final priorityColor = _priorityColor(task['priority']);

    return Dismissible(
      key: ValueKey(task['title'] + task['due']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => _deleteTask(task),
      child: Container(
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
                border: Border.all(color: isDone ? Colors.green.shade500 : const Color(0xFFBDBDBD), width: 2),
              ),
              child: isDone ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(
                task['title'],
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: isDone ? const Color(0xFF9E9E9E) : navyBlue,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              )),
              // Priority badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(task['priority'],
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor)),
              ),
            ]),
            if ((task['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(task['description'],
                  style: TextStyle(fontSize: 12, color: isDone ? const Color(0xFFBDBDBD) : steelBlue),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF9E9E9E)),
              const SizedBox(width: 4),
              Text('Due ${task['due']}', style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: navyBlue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(task['tag'],
                    style: const TextStyle(fontSize: 10, color: navyBlue, fontWeight: FontWeight.w600)),
              ),
            ]),
          ])),
          // Delete button
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _confirmDelete(task),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade400),
            ),
          ),
        ]),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task', style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Remove "${task['title']}"?', style: const TextStyle(fontSize: 14, color: steelBlue)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: steelBlue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(task);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.task_alt_rounded, size: 60, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text(
        _statusFilter == 'Done' ? 'No completed tasks yet' : 'No tasks found',
        style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
      ),
    ]));
  }
}

// ── Filter Chip ───────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String group;
  final void Function(String) onTap;
  final Color? color;

  const _FilterChip({
    required this.label, required this.value, required this.group, required this.onTap, this.color,
  });

  @override
  Widget build(BuildContext context) {
    final sel        = group == value;
    final chipColor  = color ?? const Color(0xFF2B457B);
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? chipColor : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
          color: sel ? Colors.white : const Color(0xFF4A698F),
          fontWeight: FontWeight.w600, fontSize: 12,
        )),
      ),
    );
  }
}

// ── Add Task Bottom Sheet ─────────────────────────────────────
class _AddTaskSheet extends StatefulWidget {
  final void Function(String title, String priority, String due) onAdd;
  const _AddTaskSheet({required this.onAdd});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  static const navyBlue  = Color(0xFF2B457B);
  static const orange    = Color(0xFFE97638);
  static const steelBlue = Color(0xFF4A698F);
  static const softGray  = Color(0xFFF2F2F2);

  final _titleController = TextEditingController();
  String    _priority    = 'Medium';
  DateTime? _dueDate;

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Select';
    return '${dt.month}/${dt.day}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: navyBlue, secondary: orange)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: softGray, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        const Text('New Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyBlue)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: softGray, borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Task title',
              hintStyle: TextStyle(color: Color(0xFFBDBDBD)),
              contentPadding: EdgeInsets.all(14),
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 14, color: navyBlue),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Priority', style: TextStyle(fontSize: 12, color: steelBlue, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(children: ['High', 'Medium', 'Low'].map((p) {
              final sel = _priority == p;
              final c   = p == 'High' ? Colors.red.shade400 : p == 'Medium' ? orange : Colors.green.shade500;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _priority = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: sel ? c : softGray, borderRadius: BorderRadius.circular(8)),
                    child: Text(p, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : steelBlue)),
                  ),
                ),
              );
            }).toList()),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Due Date', style: TextStyle(fontSize: 12, color: steelBlue, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: softGray, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: steelBlue),
                  const SizedBox(width: 6),
                  Text(_formatDate(_dueDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: navyBlue)),
                ]),
              ),
            ),
          ]),
        ]),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            if (_titleController.text.trim().isEmpty) return;
            widget.onAdd(
              _titleController.text.trim(), _priority,
              _dueDate != null ? '${_dueDate!.month}/${_dueDate!.day}' : 'TBD',
            );
            Navigator.pop(context);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(color: navyBlue, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Add Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
          ),
        ),
      ]),
    );
  }
}