import 'package:alzcare/core/shared-prefrences/shared-prefrences-helper.dart';
import 'package:alzcare/core/supabase/activities-service.dart';
import 'package:alzcare/core/supabase/patient-family-service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Colors/Gradient
const Color kTeal900 = Color(0xFF134E4A);
const Color kGray600 = Color(0xFF4B5563);
const Color kGray500 = Color(0xFF6B7280);
const Color kGray50 = Color(0xFFF9FAFB);
const Color kTeal500 = Color(0xFF14B8A6);
const Color kCyan500 = Color(0xFF06B6D4);
const LinearGradient kTealGradient = LinearGradient(
  colors: [kTeal500, kCyan500],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class FamilyActivitiesScreen extends StatefulWidget {
  const FamilyActivitiesScreen({super.key});

  @override
  State<FamilyActivitiesScreen> createState() => _FamilyActivitiesScreenState();
}

class _FamilyActivitiesScreenState extends State<FamilyActivitiesScreen> {
  final ActivitiesService _activitiesService = ActivitiesService();
  final PatientFamilyService _patientFamilyService = PatientFamilyService();

  List<Map<String, dynamic>> activities = [];
  bool _loading = false;
  String? _patientRecordId;
  String? _patientUserId;

  // Week state
  DateTime _weekStart = _startOfWeek(DateTime.now());
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _loading = true);
    try {
      final familyUid = SharedPrefsHelper.getString('familyUid') ??
          SharedPrefsHelper.getString('userId');
      if (familyUid == null) {
        setState(() => _loading = false);
        return;
      }

      // Get first patient linked to this family member
      final patients = await _patientFamilyService.getPatientsByFamily(familyUid);
      if (patients.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final patientData = patients.first;
      final patient = patientData['patients'] as Map<String, dynamic>?;
      if (patient == null) {
        setState(() => _loading = false);
        return;
      }

      _patientRecordId = patient['id'] as String;
      _patientUserId = patient['user_id'] as String;

      // Load activities for the week
      final weekEnd = _weekStart.add(const Duration(days: 6));
      final loadedActivities = await _activitiesService
          .getActivitiesForPatientByRecordId(
        _patientRecordId!,
        startDate: _weekStart,
        endDate: weekEnd,
      );

      setState(() {
        activities = loadedActivities.map((a) {
          // Convert database format to UI format
          final scheduledDate = a['scheduled_date'] as String?;
          DateTime? date;
          if (scheduledDate != null) {
            date = DateTime.tryParse(scheduledDate);
          }

          return {
            'id': a['id'],
            'name': a['name'] ?? '',
            'description': a['description'] ?? '',
            'done': a['is_completed'] == true,
            'date': date ?? DateTime.now(),
            'time': a['scheduled_time'] ?? '',
            'reminderType': a['reminder_type'] ?? 'alarm',
          };
        }).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load activities: $e')),
        );
      }
      setState(() => _loading = false);
    }
  }

  static String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static DateTime _startOfWeek(DateTime dt) {
    final wd = dt.weekday; // Mon=1
    return DateTime(dt.year, dt.month, dt.day).subtract(Duration(days: wd - 1));
  }

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  List<Map<String, dynamic>> _activitiesForDay(DateTime day) {
    final ds = _fmt(day);
    final list = activities
        .where((a) {
          final date = a['date'];
          if (date is DateTime) {
            return _fmt(date) == ds;
          }
          return false;
        })
        .toList();
    list.sort((a, b) =>
        ((a['time'] ?? '') as String).compareTo((b['time'] ?? '') as String));
    return list;
  }

  // CRUD helpers
  Future<bool> _confirmDelete() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this activity?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    return res == true;
  }

  Future<void> _deleteActivity(Map<String, dynamic> activity) async {
    if (!await _confirmDelete()) return;

    final activityId = activity['id'] as String?;
    if (activityId == null) {
      // Local only activity, just remove from list
      setState(() {
        activities.remove(activity);
      });
      return;
    }

    try {
      await _activitiesService.deleteActivity(activityId);
      await _loadActivities();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete activity: $e')),
        );
      }
    }
  }

  Future<void> _openEdit(Map<String, dynamic> activity) async {
    final updated = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(builder: (_) => EditActivitiesView(activity: activity)),
    );
    if (updated != null && _patientUserId != null) {
      final activityId = activity['id'] as String?;
      if (activityId != null) {
        // Update existing activity
        try {
          final date = updated['date'] as DateTime? ?? DateTime.now();
          await _activitiesService.updateActivity(activityId, {
            'name': updated['name'] ?? '',
            'description': updated['description'] ?? '',
            'scheduled_date': date.toIso8601String().split('T')[0],
            'scheduled_time': updated['time'] ?? '',
            'reminder_type': updated['reminderType'] ?? 'alarm',
          });
          await _loadActivities();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update activity: $e')),
            );
          }
        }
      } else {
        // New activity
        await _addNewActivity(updated);
      }
    }
  }

  Future<void> _addNew() async {
    final newActivity = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(builder: (_) => const EditActivitiesView()),
    );
    if (newActivity != null) {
      await _addNewActivity(newActivity);
    }
  }

  Future<void> _addNewActivity(Map<String, dynamic> activity) async {
    if (_patientUserId == null) return;

    try {
      final familyUid = SharedPrefsHelper.getString('familyUid') ??
          SharedPrefsHelper.getString('userId');
      final date = activity['date'] as DateTime? ?? DateTime.now();

      await _activitiesService.createActivity(
        patientId: _patientUserId!,
        familyMemberId: familyUid,
        name: activity['name'] ?? '',
        description: activity['description'] ?? '',
        scheduledDate: date,
        scheduledTime: activity['time'] ?? '',
        reminderType: activity['reminderType'] ?? 'alarm',
      );

      await _loadActivities();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add activity: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayList = _activitiesForDay(DateTime.now());
    final todayDone = todayList.where((e) => e['done'] == true).length;
    final todayTotal = todayList.length;
    final todayProgress = todayTotal == 0 ? 0.0 : todayDone / todayTotal;

    final selectedList = _activitiesForDay(_selectedDay);
    final selectedDone = selectedList.where((e) => e['done'] == true).length;
    final selectedTotal = selectedList.length;
    final selectedProgress =
        selectedTotal == 0 ? 0.0 : selectedDone / selectedTotal;

    if (_loading && activities.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Memory Activities',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: kTeal900)),
                    SizedBox(height: 4),
                    Text('Keep your mind active and engaged',
                        style: TextStyle(fontSize: 14, color: kGray600)),
                  ],
                ),
                // زر إضافة: +
                GestureDetector(
                  onTap: _addNew,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                        gradient: kTealGradient, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),

          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12)),
              child: const TabBar(
                indicator: BoxDecoration(
                    gradient: kTealGradient,
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: kGray600,
                tabs: [
                  Tab(text: 'Today'),
                  Tab(text: 'Schedule'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tab views
          Expanded(
            child: TabBarView(
              children: [
                // Today
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _ProgressCard(
                          done: todayDone,
                          total: todayTotal,
                          progress: todayProgress),
                      const SizedBox(height: 16),
                      Expanded(child: _buildFamilyList(todayList)),
                    ],
                  ),
                ),

                // Schedule
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            onPressed: () {
                              setState(() {
                                final idx = _weekDays.indexWhere(
                                    (d) => _fmt(d) == _fmt(_selectedDay));
                                _weekStart = _weekStart
                                    .subtract(const Duration(days: 7));
                                _selectedDay = _weekStart
                                    .add(Duration(days: idx < 0 ? 0 : idx));
                              });
                              _loadActivities();
                            },
                          ),
                          Text(
                            "${DateFormat('MMM d').format(_weekDays.first)} - ${DateFormat('MMM d').format(_weekDays.last)}",
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kTeal900),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: () {
                              setState(() {
                                final idx = _weekDays.indexWhere(
                                    (d) => _fmt(d) == _fmt(_selectedDay));
                                _weekStart =
                                    _weekStart.add(const Duration(days: 7));
                                _selectedDay = _weekStart
                                    .add(Duration(days: idx < 0 ? 0 : idx));
                              });
                              _loadActivities();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 96,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _weekDays.length,
                          itemBuilder: (context, i) {
                            final day = _weekDays[i];
                            final isSelected = _fmt(day) == _fmt(_selectedDay);
                            return GestureDetector(
                              onTap: () => setState(() => _selectedDay = day),
                              child: Container(
                                width: 80,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? kTeal500 : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFE5E7EB)),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2))
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(DateFormat('EEE').format(day),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black)),
                                    const SizedBox(height: 6),
                                    Text(DateFormat('d').format(day),
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black)),
                                    const SizedBox(height: 4),
                                    Text(DateFormat('MMM').format(day),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: isSelected
                                                ? Colors.white
                                                : kGray600)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProgressCard(
                          done: selectedDone,
                          total: selectedTotal,
                          progress: selectedProgress),
                      const SizedBox(height: 12),
                      Expanded(child: _buildFamilyList(selectedList)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return const Center(
          child:
              Text('No activities found.', style: TextStyle(color: kGray600)));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final activity = list[i];
        final idx = activities.indexOf(activity);
        final completed = activity['done'] == true;
        final color = i.isEven ? kTeal500 : kCyan500;
        final dateStr = activity['date'] is DateTime
            ? DateFormat('yyyy-MM-dd').format(activity['date'])
            : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              // الكارت
              GestureDetector(
                onTap: () => _openEdit(activity), // Edit
                onDoubleTap: () async {
                  // Toggle Done
                  if (idx != -1) {
                    final activity = activities[idx];
                    final activityId = activity['id'] as String?;
                    final currentDone = activity['done'] == true;
                    final newDone = !currentDone;

                    if (activityId != null) {
                      try {
                        await _activitiesService.toggleActivityCompletion(
                          activityId,
                          newDone,
                        );
                        await _loadActivities();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update: $e')),
                          );
                        }
                      }
                    } else {
                      setState(() {
                        activities[idx]['done'] = newDone;
                      });
                    }
                  }
                },
                child: _ActivityCard(
                  title: activity['name'] ?? '',
                  description: activity['description'] ?? '',
                  icon: Icons.psychology,
                  date: dateStr,
                  time: (activity['time'] ?? '').toString(),
                  completed: completed,
                  color: color,
                ),
              ),

              // قائمة 3 نقط (Edit/Delete)
              Positioned(
                right: 8,
                top: 8,
                child: Material(
                  color: Colors.transparent,
                  child: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') {
                        _openEdit(activity);
                      } else if (v == 'delete') {
                        _deleteActivity(activity);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert, color: kTeal900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Shared UI
class _ProgressCard extends StatelessWidget {
  final int done;
  final int total;
  final double progress;

  const _ProgressCard(
      {required this.done, required this.total, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: kTealGradient, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('Today\'s Progress',
                style: TextStyle(color: Color(0xFFCFFAFE), fontSize: 14)),
            SizedBox(height: 4),
          ]),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child:
                const Icon(Icons.emoji_events, color: Colors.white, size: 32),
          ),
        ]),
        const SizedBox(height: 8),
        Text('$done/$total Activities',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        const Text('Great job! Keep going! 💪',
            style: TextStyle(color: Color(0xFFCFFAFE), fontSize: 14)),
      ]),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String date;
  final String time;
  final bool completed;
  final Color color;

  const _ActivityCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.date,
    required this.time,
    required this.completed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: completed ? kGray50 : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kTeal900)),
              const SizedBox(height: 4),
              Text(description,
                  style: const TextStyle(fontSize: 13, color: kGray600)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.calendar_today, size: 14, color: kGray500),
                const SizedBox(width: 4),
                Text(date,
                    style: const TextStyle(fontSize: 12, color: kGray500)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 14, color: kGray500),
                const SizedBox(width: 4),
                Text(time,
                    style: const TextStyle(fontSize: 12, color: kGray500)),
              ]),
            ]),
          ),
          if (completed)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.check_circle, color: Colors.green),
            ),
        ],
      ),
    );
  }
}

// ============== Edit Activities (بدون صور/نقاط/صعوبات) ==============
class EditActivitiesView extends StatefulWidget {
  final Map<String, dynamic>? activity;

  const EditActivitiesView({super.key, this.activity});

  @override
  State<EditActivitiesView> createState() => _EditActivitiesViewState();
}

class _EditActivitiesViewState extends State<EditActivitiesView> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  String _reminderType = 'alarm';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.activity?['name'] ?? '');
    _descCtrl =
        TextEditingController(text: widget.activity?['description'] ?? '');
    _reminderType = widget.activity?['reminderType'] ?? 'alarm';
    _selectedDate = widget.activity?['date'] ?? DateTime.now();

    final incomingTime = widget.activity?['time'];
    if (incomingTime is TimeOfDay) {
      _selectedTime = incomingTime;
    } else if (incomingTime is String && incomingTime.isNotEmpty) {
      try {
        final parsed = DateFormat('h:mm a').parse(incomingTime);
        _selectedTime = TimeOfDay.fromDateTime(parsed);
      } catch (_) {}
    }
  }

  Future<void> _pickTime() async {
    final t =
        await showTimePicker(context: context, initialTime: _selectedTime);
    if (t != null) setState(() => _selectedTime = t);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2025),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter activity name')));
      return;
    }
    final formattedTime = _selectedTime.format(context);
    final m = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'done': widget.activity?['done'] ?? false,
      'time': formattedTime,
      'reminderType': _reminderType,
      'date': _selectedDate ?? DateTime.now(),
    };
    Navigator.pop(context, m);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.activity == null ? 'Add Activity' : 'Edit Activity',
            style:
                const TextStyle(color: kTeal500, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Activity Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text('Time: ${_selectedTime.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
            ),
            ListTile(
              title: Text(_selectedDate != null
                  ? 'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}'
                  : 'Select Date'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const Text('Reminder type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(children: [
              _ReminderChip(
                  label: 'Alarm',
                  icon: Icons.alarm,
                  selected: _reminderType == 'alarm',
                  onTap: () => setState(() => _reminderType = 'alarm')),
              const SizedBox(width: 12),
              _ReminderChip(
                  label: 'Vibrate',
                  icon: Icons.notifications_active,
                  selected: _reminderType == 'vibrate',
                  onTap: () => setState(() => _reminderType = 'vibrate')),
            ]),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal500,
                  minimumSize: const Size(double.infinity, 48)),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ReminderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ReminderChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: selected ? kTeal500 : Colors.grey.shade400,
              width: selected ? 2 : 1),
        ),
        child: Icon(icon, color: selected ? kTeal500 : Colors.grey, size: 22),
      ),
    );
  }
}
