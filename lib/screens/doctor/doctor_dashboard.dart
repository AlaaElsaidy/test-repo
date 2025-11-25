import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../core/shared-prefrences/shared-prefrences-helper.dart';
import '../../core/supabase/supabase-config.dart';
import '../../core/supabase/supabase-service.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final _client = SupabaseConfig.client;
  final FamilyMemberService _familyService = FamilyMemberService();
  
  String? _doctorName;
  int _activePatientsCount = 0;
  int _appointmentsCount = 0;
  List<Map<String, dynamic>> _todayAppointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);
    try {
      final doctorId = SharedPrefsHelper.getString("userId") ?? 
                      SharedPrefsHelper.getString("doctorUid");
      if (doctorId == null) {
        setState(() => _loading = false);
        return;
      }

      await Future.wait([
        _loadDoctorInfo(doctorId),
        _loadActivePatientsCount(doctorId),
        _loadAppointmentsCount(doctorId),
        _loadTodayAppointments(doctorId),
      ]);
    } catch (e) {
      debugPrint('Failed to load dashboard data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadDoctorInfo(String doctorId) async {
    try {
      final user = await _client
          .from('users')
          .select('name')
          .eq('id', doctorId)
          .maybeSingle();
      
      if (user != null) {
        setState(() {
          _doctorName = user['name'] as String? ?? 'Doctor';
        });
      }
    } catch (e) {
      debugPrint('Failed to load doctor info: $e');
    }
  }

  Future<void> _loadActivePatientsCount(String doctorId) async {
    try {
      // Get all family members linked to this doctor
      final families = await _familyService.getFamiliesByDoctor(doctorId);
      
      // Count unique patients from all families
      final Set<String> patientIds = {};
      for (final family in families) {
        final familyId = family['id'] as String?;
        if (familyId != null) {
          final relations = await _client
              .from('patient_family_relations')
              .select('patient_id')
              .eq('family_member_id', familyId);
          
          for (final relation in relations as List) {
            final patientId = relation['patient_id'] as String?;
            if (patientId != null) {
              patientIds.add(patientId);
            }
          }
        }
      }
      
      setState(() {
        _activePatientsCount = patientIds.length;
      });
    } catch (e) {
      debugPrint('Failed to load active patients count: $e');
    }
  }

  Future<void> _loadAppointmentsCount(String doctorId) async {
    try {
      // Count doctor advices as appointments (or use appointments table if exists)
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final appointments = await _client
          .from('doctor_advices')
          .select('id')
          .eq('doctor_id', doctorId)
          .gte('created_at', startOfDay.toIso8601String());
      
      setState(() {
        _appointmentsCount = (appointments as List).length;
      });
    } catch (e) {
      debugPrint('Failed to load appointments count: $e');
    }
  }

  Future<void> _loadTodayAppointments(String doctorId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final appointments = await _client
          .from('doctor_advices')
          .select('''
            id,
            created_at,
            family_member_id,
            family_members (
              id,
              name
            ),
            patients (
              id,
              name
            )
          ''')
          .eq('doctor_id', doctorId)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .order('created_at', ascending: true)
          .limit(5);
      
      setState(() {
        _todayAppointments = (appointments as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('Failed to load today appointments: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppTheme.tealGradient,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.medical_services,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    color: Color(0xFFCFFAFE),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _doctorName ?? 'Doctor',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.notifications_outlined),
                            color: Colors.white,
                            iconSize: 28,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Stats
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            icon: Icons.people,
                            label: 'Active Patients',
                            value: '$_activePatientsCount',
                            color: AppTheme.teal500,
                            backgroundColor: AppTheme.teal50,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            icon: Icons.calendar_today,
                            label: 'Appointments',
                            value: '$_appointmentsCount',
                            color: AppTheme.cyan500,
                            backgroundColor: AppTheme.cyan50,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Today's Appointments
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Today\'s Appointments',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.teal900,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('View All'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_todayAppointments.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'No appointments today',
                                    style: TextStyle(
                                      color: AppTheme.gray500,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ..._todayAppointments.map((appointment) {
                                final family = appointment['family_members'] as Map<String, dynamic>?;
                                final patient = appointment['patients'] as Map<String, dynamic>?;
                                final createdAt = appointment['created_at'] as String?;
                                
                                String patientName = 'Unknown';
                                if (patient != null && patient['name'] != null) {
                                  patientName = patient['name'] as String;
                                } else if (family != null && family['name'] != null) {
                                  patientName = '${family['name'] as String}\'s Patient';
                                }
                                
                                String time = 'Unknown';
                                if (createdAt != null) {
                                  try {
                                    final dateTime = DateTime.parse(createdAt);
                                    final hour = dateTime.hour;
                                    final minute = dateTime.minute;
                                    final period = hour >= 12 ? 'PM' : 'AM';
                                    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                                    time = '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
                                  } catch (e) {
                                    time = 'Unknown';
                                  }
                                }
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _AppointmentItem(
                                    patientName: patientName,
                                    time: time,
                                    type: 'Consultation',
                                    status: 'Upcoming',
                                    statusColor: AppTheme.teal500,
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}

class _AppointmentItem extends StatelessWidget {
  final String patientName;
  final String time;
  final String type;
  final String status;
  final Color statusColor;

  const _AppointmentItem({
    required this.patientName,
    required this.time,
    required this.type,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.teal900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.gray600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

