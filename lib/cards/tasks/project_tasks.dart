import 'package:flutter/material.dart';
import 'package:worktime/app_state.dart';
import 'package:worktime/services/local_db.dart';
import 'project_info_card.dart';
import 'project_task_card.dart';
import 'assign_task_dialog.dart';

// ─────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────
const _navy     = Color(0xFF2B457B);
const _orange   = Color(0xFFE97638);
const _steel    = Color(0xFF4A698F);
const _softGray = Color(0xFFF2F2F2);
const _wip      = Color(0xFF7B5EA7);

// ─────────────────────────────────────────────────────────────
// ProjectTasksPage
// ─────────────────────────────────────────────────────────────
class ProjectTasksPage extends StatefulWidget {
  final Map<String, dynamic> project;
  final VoidCallback          onChanged;

  const ProjectTasksPage({
    super.key,
    required this.project,
    required this.onChanged,
  });

  @override
  State<ProjectTasksPage> createState() => _ProjectTasksPageState();
}

class _ProjectTasksPageState extends State<ProjectTasksPage> {

  List<Map<String, dynamic>> _tasks    = [];
  List<Map<String, dynamic>> _members  = [];
  List<Map<String, dynamic>> _pending  = []; // completion requests
  bool   _loading        = true;
  bool   _isLeader       = false;
  String _statusFilter   = 'All';
  String _priorityFilter = 'All';
  String _dateSort       = 'Oldest';
  bool   _sortByPriority = false;

  static const _priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // ── Load ──────────────────────────────────────────────────
  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    final pid      = widget.project['id'] as String;
    final uid      = AppState().userId;
    final list     = await LocalDB.getTasksByProject(pid);
    final members  = await LocalDB.getProjectMembers(pid);
    final isLeader = await LocalDB.isProjectLeader(uid, pid);
    final pending  = await LocalDB.getPendingRequestsForProject(pid);
    if (!mounted) return;
    setState(() {
      _tasks    = list;
      _members  = members;
      _isLeader = isLeader;
      _pending  = pending;
      _loading  = false;
    });
  }

  // ── Helpers ───────────────────────────────────────────────
  String _status(Map<String, dynamic> t) {
    if (t['done']       as bool? ?? false) return 'done';
    if (t['inProgress'] as bool? ?? false) return 'inProgress';
    return 'pending';
  }

  DateTime _parseDue(String due) {
    const mo = {
      'Jan':1,'Feb':2,'Mar':3,'Apr':4,'May':5,'Jun':6,
      'Jul':7,'Aug':8,'Sep':9,'Oct':10,'Nov':11,'Dec':12,
    };
    try {
      final p = due.trim().split(' ');
      return DateTime(DateTime.now().year, mo[p[0]] ?? 1,
          int.tryParse(p[1]) ?? 1);
    } catch (_) {
      return DateTime(9999);
    }
  }

  // ── Filtered + sorted list ────────────────────────────────
  List<Map<String, dynamic>> get _filtered {
    var list = List<Map<String, dynamic>>.from(_tasks);
    switch (_statusFilter) {
      case 'Pending':
        list = list.where((t) => _status(t) == 'pending').toList();
        break;
      case 'In Progress':
        list = list.where((t) => _status(t) == 'inProgress').toList();
        break;
      case 'Done':
        list = list.where((t) => _status(t) == 'done').toList();
        break;
    }
    if (_priorityFilter != 'All') {
      list = list.where((t) => t['priority'] == _priorityFilter).toList();
    }
    if (_sortByPriority) {
      list.sort((a, b) =>
          (_priorityOrder[a['priority']] ?? 3)
              .compareTo(_priorityOrder[b['priority']] ?? 3));
    } else {
      list.sort((a, b) {
        final da = _parseDue(a['due'] as String? ?? '');
        final db = _parseDue(b['due'] as String? ?? '');
        return _dateSort == 'Newest'
            ? db.compareTo(da)
            : da.compareTo(db);
      });
    }
    return list;
  }

  // ── Counts for filter sheets ──────────────────────────────
  int get _pendingCount    => _tasks.where((t) => _status(t) == 'pending').length;
  int get _inProgressCount => _tasks.where((t) => _status(t) == 'inProgress').length;
  int get _doneCount       => _tasks.where((t) => _status(t) == 'done').length;
  int get _highCount   => _tasks.where((t) => t['priority'] == 'High'   && _status(t) != 'done').length;
  int get _mediumCount => _tasks.where((t) => t['priority'] == 'Medium' && _status(t) != 'done').length;
  int get _lowCount    => _tasks.where((t) => t['priority'] == 'Low'    && _status(t) != 'done').length;
  double get _progress => _tasks.isEmpty ? 0.0 : _doneCount / _tasks.length;

  void _setFilter(VoidCallback fn) => setState(fn);

  Color _statusColor(String s) {
    switch (s) {
      case 'Pending':     return _orange;
      case 'In Progress': return _wip;
      case 'Done':        return Colors.green.shade600;
      default:            return _navy;
    }
  }

  Color _priorityActiveColor(String p) {
    switch (p) {
      case 'High':   return Colors.red.shade400;
      case 'Medium': return _orange;
      case 'Low':    return Colors.green.shade500;
      default:       return _steel;
    }
  }

  // ── Filter sheets ─────────────────────────────────────────
  Future<void> _openStatusSheet() async {
    final r = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SheetPicker(
        title: 'Filter by Status',
        selected: _statusFilter,
        items: [
          {'label': 'All',         'count': _tasks.length,    'color': _navy},
          {'label': 'Pending',     'count': _pendingCount,    'color': _orange},
          {'label': 'In Progress', 'count': _inProgressCount, 'color': _wip},
          {'label': 'Done',        'count': _doneCount,       'color': Colors.green.shade600},
        ],
      ),
    );
    if (r != null) _setFilter(() => _statusFilter = r);
  }

  Future<void> _openPrioritySheet() async {
    final r = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SheetPicker(
        title: 'Filter by Priority',
        selected: _priorityFilter,
        items: [
          {'label': 'All',    'count': _tasks.where((t) => _status(t) != 'done').length, 'color': _steel},
          {'label': 'High',   'count': _highCount,   'color': Colors.red.shade400},
          {'label': 'Medium', 'count': _mediumCount, 'color': _orange},
          {'label': 'Low',    'count': _lowCount,    'color': Colors.green.shade500},
        ],
      ),
    );
    if (r != null) _setFilter(() => _priorityFilter = r);
  }

  Future<void> _openDateSheet() async {
    final r = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SheetPicker(
        title: 'Sort by Due Date',
        selected: _dateSort,
        items: [
          {'label': 'Oldest', 'count': _filtered.length, 'color': _navy,  'subtitle': 'Earliest due date first'},
          {'label': 'Newest', 'count': _filtered.length, 'color': _steel, 'subtitle': 'Latest due date first'},
        ],
      ),
    );
    if (r != null) _setFilter(() { _dateSort = r; _sortByPriority = false; });
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final title    = widget.project['title'] as String? ?? 'Project';
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _navy))
          : CustomScrollView(slivers: [

        // App Bar
        SliverAppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          floating: true,
          snap: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _navy, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _setFilter(
                        () => _sortByPriority = !_sortByPriority),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _sortByPriority
                        ? _orange.withOpacity(0.12)
                        : _softGray,
                    borderRadius: BorderRadius.circular(8),
                    border: _sortByPriority
                        ? Border.all(color: _orange.withOpacity(0.4))
                        : null,
                  ),
                  child: Row(children: [
                    Icon(Icons.sort_rounded,
                        size: 14,
                        color: _sortByPriority ? _orange : _steel),
                    const SizedBox(width: 4),
                    Text('Sort',
                        style: TextStyle(
                            fontSize: 11,
                            color: _sortByPriority ? _orange : _steel,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
          ],
        ),

        // Project info card
        SliverToBoxAdapter(
          child: ProjectInfoCard(
            project:    widget.project,
            members:    _members,
            doneCount:  _doneCount,
            totalTasks: _tasks.length,
            progress:   _progress,
          ),
        ),

        // Filter row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(children: [
              Expanded(child: _filterColumn(
                  label: 'STATUS',
                  value: _statusFilter,
                  isActive: _statusFilter != 'All',
                  activeColor: _statusColor(_statusFilter),
                  onTap: _openStatusSheet)),
              const SizedBox(width: 10),
              Expanded(child: _filterColumn(
                  label: 'PRIORITY',
                  value: _priorityFilter,
                  isActive: _priorityFilter != 'All',
                  activeColor: _priorityActiveColor(_priorityFilter),
                  onTap: _openPrioritySheet)),
              const SizedBox(width: 10),
              Expanded(child: _filterColumn(
                  label: 'DUE DATE',
                  value: _dateSort,
                  isActive: true,
                  activeColor: _navy,
                  onTap: _openDateSheet)),
            ]),
          ),
        ),

        const SliverToBoxAdapter(
            child: Divider(height: 1, color: Color(0xFFF0F0F0))),

        // Count label
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              '${filtered.length} task${filtered.length == 1 ? '' : 's'} found',
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),

        // Empty state
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.task_alt_rounded,
                      size: 52, color: _steel.withOpacity(0.2)),
                  const SizedBox(height: 12),
                  Text(
                    _tasks.isEmpty
                        ? 'No tasks in this project yet'
                        : 'No tasks match the selected filters',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _steel.withOpacity(0.5), fontSize: 14),
                  ),
                ]),
              ),
            ),
          )
        else
        // Task list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ProjectTaskCard(
                    task:               filtered[i],
                    members:            _members,
                    isLeader:           _isLeader,
                    currentUserId:      AppState().userId,
                    projectTitle:       title,
                    hasPendingRequest:  _pending.any((r) =>
                    r['taskId'] == filtered[i]['id']),
                    onReload:           _loadTasks,
                    onChanged:          widget.onChanged,
                  ),
                ),
                childCount: filtered.length,
              ),
            ),
          ),
      ]),
    );
  }

  // ── Filter column widget ──────────────────────────────────
  Widget _filterColumn({
    required String       label,
    required String       value,
    required bool         isActive,
    required Color        activeColor,
    required VoidCallback onTap,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 6),
        child: Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9E9E9E),
                letterSpacing: 0.8)),
      ),
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.08) : _softGray,
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
                width: 7, height: 7,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                    color: activeColor, shape: BoxShape.circle),
              ),
            Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? activeColor : _steel),
                  overflow: TextOverflow.ellipsis),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isActive ? activeColor : const Color(0xFFBDBDBD)),
          ]),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
// _SheetPicker — filter bottom sheet (local to this file)
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
                  color: _navy)),
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
                              color: isSel ? color : _steel)),
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
                          color: isSel ? color : const Color(0xFF9E9E9E))),
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