import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:alzcare/core/shared-prefrences/shared-prefrences-helper.dart';
import 'package:alzcare/core/supabase/activity-service.dart';
import 'package:alzcare/core/supabase/patient-family-service.dart';

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
  final ActivityService _activityService = ActivityService();
  final PatientFamilyService _patientFamilyService = PatientFamilyService();

  String? _familyMemberId;
  List<Map<String, dynamic>> _allActivities = [];
  bool _loading = true;
  String? _error;

  bool get _isAr =>
      (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ar';

  String tr(String en, String ar) => _isAr ? ar : en;

  // Week state
  DateTime _weekStart = _startOfWeek(DateTime.now());
  DateTime _selectedDay = DateTime.now();

  static String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static DateTime _startOfWeek(DateTime dt) {
    final wd = dt.weekday; // Mon=1
    return DateTime(dt.year, dt.month, dt.day).subtract(Duration(days: wd - 1));
  }

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Get family member ID
      final familyUid = SharedPrefsHelper.getString("familyUid") ??
          SharedPrefsHelper.getString("userId");
      if (familyUid == null) {
        throw Exception(tr('Family member ID not found', 'تعذّر العثور على معرف عضو العائلة'));
      }

      _familyMemberId = familyUid;

      // Load activities
      await _refreshActivities();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refreshActivities() async {
    if (_familyMemberId == null) return;

    try {
      final activities = await _activityService
          .getActivitiesByFamilyMember(_familyMemberId!);
      setState(() {
        _allActivities = activities;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _activitiesForDay(DateTime day) {
    final ds = _fmt(day);
    final list = _allActivities.where((a) {
      final scheduledDate = a['scheduled_date'] as String?;
      if (scheduledDate == null) return false;
      return scheduledDate == ds;
    }).toList();
    list.sort((a, b) {
      final timeA = (a['scheduled_time'] ?? '').toString();
      final timeB = (b['scheduled_time'] ?? '').toString();
      return timeA.compareTo(timeB);
    });
    return list;
  }

  Future<bool> _confirmDelete() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('Confirm Delete', 'تأكيد الحذف')),
        content: Text(tr('Are you sure you want to delete this activity?', 'هل أنت متأكد أنك تريد حذف هذا النشاط؟')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('Cancel', 'إلغاء'))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('Delete', 'حذف'), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    return res == true;
  }

  Future<void> _deleteActivity(Map<String, dynamic> activity) async {
    if (!await _confirmDelete()) return;

    try {
      final activityId = activity['id'] as String;
      await _activityService.deleteActivity(activityId);
      await _refreshActivities();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Activity deleted successfully', 'تم حذف النشاط بنجاح'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Error deleting activity', 'خطأ في حذف النشاط') + ': $e')),
        );
      }
    }
  }

  Future<void> _openEdit(Map<String, dynamic> activity) async {
    // Get linked patients for this family member
    List<Map<String, dynamic>> patients = [];
    if (_familyMemberId != null) {
      try {
        patients = await _patientFamilyService
            .getPatientsByFamily(_familyMemberId!);
        // Family member مرتبط بمريض واحد فقط؛ نستخدم أول مريض فقط
        // حتى لو رجعت ليست أكبر من واحد بسبب داتا قديمة.
        if (patients.isNotEmpty) {
          patients = [patients.first];
        }
      } catch (e) {
        debugPrint('Error loading patients: $e');
      }
    }

    final updated = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => EditActivitiesView(
          activity: activity,
          familyMemberId: _familyMemberId,
          patients: patients,
        ),
      ),
    );
    if (updated != null) {
      await _refreshActivities();
    }
  }

  Future<void> _addNew() async {
    // Get linked patients for this family member
    List<Map<String, dynamic>> patients = [];
    if (_familyMemberId != null) {
      try {
        patients = await _patientFamilyService
            .getPatientsByFamily(_familyMemberId!);
        // نضمن أن الفاميلى يختار مريض واحد فقط
        if (patients.isNotEmpty) {
          patients = [patients.first];
        }
      } catch (e) {
        debugPrint('Error loading patients: $e');
      }
    }

    if (patients.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('No patients linked. Please link a patient first.', 'لا يوجد مرضى مرتبطين. يرجى ربط مريض أولاً.')),
          ),
        );
      }
      return;
    }

    final newActivity = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => EditActivitiesView(
          familyMemberId: _familyMemberId,
          patients: patients,
        ),
      ),
    );
    if (newActivity != null) {
      await _refreshActivities();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isSmall = width < 360;

    if (_loading) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: isSmall ? 32 : 40,
              height: isSmall ? 32 : 40,
              child: const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 16 : 24,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Error: $_error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: isSmall ? double.infinity : 160,
                    child: ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final todayList = _activitiesForDay(DateTime.now());
    final todayDone = todayList.where((e) => e['is_done'] == true).length;
    final todayTotal = todayList.length;
    final todayProgress = todayTotal == 0 ? 0.0 : todayDone / todayTotal;

    final selectedList = _activitiesForDay(_selectedDay);
    final selectedDone = selectedList.where((e) => e['is_done'] == true).length;
    final selectedTotal = selectedList.length;
    final selectedProgress =
        selectedTotal == 0 ? 0.0 : selectedDone / selectedTotal;

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hPadding = constraints.maxWidth < 360 ? 12.0 : 16.0;
            final titleSize = constraints.maxWidth < 360 ? 20.0 : 24.0;
            final subtitleSize = constraints.maxWidth < 360 ? 12.0 : 14.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(hPadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Memory Activities', 'أنشطة الذاكرة'),
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                                color: kTeal900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr('Keep your mind active and engaged', 'حافظ على نشاط عقلك وانشغاله'),
                              style: TextStyle(
                                fontSize: subtitleSize,
                                color: kGray600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // زر إضافة: +
                      GestureDetector(
                        onTap: _addNew,
                        child: Container(
                          width: constraints.maxWidth < 360 ? 40 : 48,
                          height: constraints.maxWidth < 360 ? 40 : 48,
                          decoration: const BoxDecoration(
                            gradient: kTealGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPadding),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      indicator: const BoxDecoration(
                        gradient: kTealGradient,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: kGray600,
                      tabs: [
                        Tab(text: _isAr ? 'اليوم' : 'Today'),
                        Tab(text: _isAr ? 'الجدول' : 'Schedule'),
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
                        padding: EdgeInsets.symmetric(horizontal: hPadding),
                        child: Column(
                          children: [
                            _ProgressCard(
                              done: todayDone,
                              total: todayTotal,
                              progress: todayProgress,
                            ),
                            const SizedBox(height: 16),
                            Expanded(child: _buildFamilyList(todayList)),
                          ],
                        ),
                      ),

                      // Schedule
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPadding),
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
                                        (d) => _fmt(d) == _fmt(_selectedDay),
                                      );
                                      _weekStart = _weekStart
                                          .subtract(const Duration(days: 7));
                                      _selectedDay = _weekStart.add(
                                        Duration(days: idx < 0 ? 0 : idx),
                                      );
                                    });
                                  },
                                ),
                                Flexible(
                                  child: Text(
                                    "${DateFormat('MMM d').format(_weekDays.first)} - ${DateFormat('MMM d').format(_weekDays.last)}",
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: kTeal900,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios),
                                  onPressed: () {
                                    setState(() {
                                      final idx = _weekDays.indexWhere(
                                        (d) => _fmt(d) == _fmt(_selectedDay),
                                      );
                                      _weekStart = _weekStart
                                          .add(const Duration(days: 7));
                                      _selectedDay = _weekStart.add(
                                        Duration(days: idx < 0 ? 0 : idx),
                                      );
                                    });
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
                                  final isSelected =
                                      _fmt(day) == _fmt(_selectedDay);
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedDay = day),
                                    child: Container(
                                      width: 80,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? kTeal500
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE5E7EB),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.02),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            DateFormat('EEE').format(day),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            DateFormat('d').format(day),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('MMM').format(day),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isSelected
                                                  ? Colors.white
                                                  : kGray600,
                                            ),
                                          ),
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
                              progress: selectedProgress,
                            ),
                            const SizedBox(height: 12),
                            Expanded(child: _buildFamilyList(selectedList)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFamilyList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
        return Center(
          child: Text(tr('No activities found.', 'لم يتم العثور على أنشطة.'), style: const TextStyle(color: kGray600)));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final activity = list[i];
        final completed = activity['is_done'] == true;
        final color = i.isEven ? kTeal500 : kCyan500;
        final dateStr = activity['scheduled_date'] as String? ?? '';
        final timeStr = activity['scheduled_time'] as String? ?? '';
        // Convert 24-hour time to 12-hour format
        final timeFormatted = _formatTimeTo12Hour(timeStr);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              // الكارت
              GestureDetector(
                onTap: () => _openEdit(activity), // Edit
                child: _ActivityCard(
                  title: activity['name'] ?? '',
                  description: activity['description'] ?? '',
                  icon: Icons.psychology,
                  date: dateStr,
                  time: timeFormatted,
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
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 18),
                            const SizedBox(width: 8),
                            Text(tr('Edit', 'تعديل')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(tr('Delete', 'حذف')),
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

  String _formatTimeTo12Hour(String time24) {
    try {
      final parts = time24.split(':');
      if (parts.length != 2) return time24;
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour12:${minute.padLeft(2, '0')} $period';
    } catch (e) {
      return time24;
    }
  }
}

// Shared UI
class _ProgressCard extends StatelessWidget {
  final int done;
  final int total;
  final double progress;

  const _ProgressCard(
      {required this.done, required this.total, required this.progress});

  bool _isAr(BuildContext context) =>
      (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ar';

  String tr(BuildContext context, String en, String ar) =>
      _isAr(context) ? ar : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: kTealGradient, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr(context, 'Today\'s Progress', 'تقدم اليوم'),
                style: const TextStyle(color: Color(0xFFCFFAFE), fontSize: 14)),
            const SizedBox(height: 4),
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
        Text(tr(context, '$done/$total Activities', '$done/$total أنشطة'),
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
        Text(tr(context, 'Great job! Keep going! 💪', 'عمل رائع! استمر! 💪'),
            style: const TextStyle(color: Color(0xFFCFFAFE), fontSize: 14)),
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

// ============== Edit Activities ==============
class EditActivitiesView extends StatefulWidget {
  final Map<String, dynamic>? activity;
  final String? familyMemberId;
  final List<Map<String, dynamic>> patients;

  const EditActivitiesView({
    super.key,
    this.activity,
    this.familyMemberId,
    required this.patients,
  });

  @override
  State<EditActivitiesView> createState() => _EditActivitiesViewState();
}

class _EditActivitiesViewState extends State<EditActivitiesView> {
  final ActivityService _activityService = ActivityService();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  String _reminderType = 'alarm';
  DateTime? _selectedDate;
  String? _selectedPatientId;
  bool _saving = false;

  bool get _isAr =>
      (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ar';

  String tr(String en, String ar) => _isAr ? ar : en;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.activity?['name'] ?? '');
    _descCtrl =
        TextEditingController(text: widget.activity?['description'] ?? '');
    _reminderType = widget.activity?['reminder_type'] ?? 'alarm';
    final scheduledDate = widget.activity?['scheduled_date'] as String?;
    if (scheduledDate != null) {
      try {
        _selectedDate = DateFormat('yyyy-MM-dd').parse(scheduledDate);
      } catch (e) {
        _selectedDate = DateTime.now();
      }
    } else {
      _selectedDate = DateTime.now();
    }

    final scheduledTime = widget.activity?['scheduled_time'] as String?;
    if (scheduledTime != null) {
      try {
        final parts = scheduledTime.split(':');
        if (parts.length == 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          _selectedTime = TimeOfDay(hour: hour, minute: minute);
        }
      } catch (e) {
        // Keep default
      }
    }

    // Set patient ID if editing
    if (widget.activity != null) {
      _selectedPatientId = widget.activity!['patient_id'] as String?;
    } else if (widget.patients.isNotEmpty) {
      // Default to first patient if adding new
      _selectedPatientId = widget.patients.first['patients']?['id'] as String? ??
          widget.patients.first['patient_id'] as String?;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
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

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Please enter activity name', 'يرجى إدخال اسم النشاط'))));
      return;
    }

    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Please select a patient', 'يرجى اختيار مريض'))));
      return;
    }

    if (widget.familyMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Family member ID not found', 'تعذّر العثور على معرف عضو العائلة'))));
      return;
    }

    setState(() => _saving = true);

    try {
      final formattedTime = _selectedTime.format(context);

      if (widget.activity != null) {
        // Update existing activity
        await _activityService.updateActivity(
          activityId: widget.activity!['id'] as String,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          scheduledDate: _selectedDate,
          scheduledTime: formattedTime,
          reminderType: _reminderType,
        );
      } else {
        // Create new activity
        await _activityService.addActivity(
          patientId: _selectedPatientId!,
          familyMemberId: widget.familyMemberId!,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          scheduledDate: _selectedDate!,
          scheduledTime: formattedTime,
          reminderType: _reminderType,
        );
      }

      if (mounted) {
        Navigator.pop(context, {'success': true});
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Error saving activity', 'خطأ في حفظ النشاط') + ': $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
            widget.activity == null ? tr('Add Activity', 'إضافة نشاط') : tr('Edit Activity', 'تعديل النشاط'),
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
            // Patient selection (only for new activities)
            if (widget.activity == null && widget.patients.isNotEmpty) ...[
              Text(tr('Select Patient', 'اختر مريض'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPatientId,
                decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: tr('Patient', 'مريض')),
                items: widget.patients.map((p) {
                  final patient = p['patients'] as Map<String, dynamic>?;
                  final patientId = patient?['id'] as String? ??
                      p['patient_id'] as String?;
                  final patientName = patient?['name'] as String? ?? tr('Unknown', 'غير معروف');
                  return DropdownMenuItem(
                    value: patientId,
                    child: Text(patientName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPatientId = value);
                },
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                  labelText: tr('Activity Name', 'اسم النشاط'), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                  labelText: tr('Description', 'الوصف'), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(tr('Time: ${_selectedTime.format(context)}', 'الوقت: ${_selectedTime.format(context)}')),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
            ),
            ListTile(
              title: Text(_selectedDate != null
                  ? tr('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}', 'التاريخ: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}')
                  : tr('Select Date', 'اختر التاريخ')),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            Text(tr('Reminder type', 'نوع التذكير'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(children: [
              _ReminderChip(
                  label: tr('Alarm', 'منبه'),
                  icon: Icons.alarm,
                  selected: _reminderType == 'alarm',
                  onTap: () => setState(() => _reminderType = 'alarm')),
              const SizedBox(width: 12),
              _ReminderChip(
                  label: tr('Vibrate', 'اهتزاز'),
                  icon: Icons.notifications_active,
                  selected: _reminderType == 'vibrate',
                  onTap: () => setState(() => _reminderType = 'vibrate')),
            ]),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal500,
                  minimumSize: const Size(double.infinity, 48)),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save', style: TextStyle(color: Colors.white)),
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

