import 'package:alzcare/core/shared-prefrences/shared-prefrences-helper.dart';
import 'package:alzcare/core/supabase/activities-service.dart';
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

class MemoryActivitiesScreen extends StatefulWidget {
  const MemoryActivitiesScreen({super.key});

  @override
  State<MemoryActivitiesScreen> createState() => _MemoryActivitiesScreenState();
}

class _MemoryActivitiesScreenState extends State<MemoryActivitiesScreen> {
  final ActivitiesService _activitiesService = ActivitiesService();

  List<Map<String, dynamic>> activities = [];
  bool _loading = false;

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
      final patientUid = SharedPrefsHelper.getString('patientUid');
      if (patientUid == null) {
        setState(() => _loading = false);
        return;
      }

      // Load activities for the week
      final weekEnd = _weekStart.add(const Duration(days: 6));
      final loadedActivities = await _activitiesService.getActivitiesForPatient(
        patientUid,
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

  @override
  Widget build(BuildContext context) {
    if (_loading && activities.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final todayList = _activitiesForDay(DateTime.now());
    final todayDone = todayList.where((e) => e['done'] == true).length;
    final todayTotal = todayList.length;
    final todayProgress = todayTotal == 0 ? 0.0 : todayDone / todayTotal;

    final selectedList = _activitiesForDay(_selectedDay);
    final selectedDone = selectedList.where((e) => e['done'] == true).length;
    final selectedTotal = selectedList.length;
    final selectedProgress =
        selectedTotal == 0 ? 0.0 : selectedDone / selectedTotal;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (أيقونة للزينة فقط)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Memory Activities',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: kTeal900)),
                  SizedBox(height: 4),
                  Text('Keep your mind active and engaged',
                      style: TextStyle(fontSize: 14, color: kGray600)),
                ]),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: kTealGradient, shape: BoxShape.circle),
                    child:
                        Icon(Icons.auto_awesome, color: Colors.white, size: 24),
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
                      Expanded(child: _buildPatientList(todayList)),
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
                      Expanded(child: _buildPatientList(selectedList)),
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

  Widget _buildPatientList(List<Map<String, dynamic>> list) {
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
          child: GestureDetector(
            // المريض: Toggle Done فقط
            onTap: () async {
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