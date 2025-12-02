import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../screens/family/family_chat_screen.dart';
import '../../screens/patient/chat_with_doctor_screen.dart';
import '../../theme/app_theme.dart';

class DoctorChatScreen extends StatefulWidget {
  const DoctorChatScreen({super.key});

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  String _currentDoctorId = '';
  String _currentDoctorName = 'Doctor';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentDoctor();
  }

  Future<void> _loadCurrentDoctor() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('doctors')
            .select('id, name')
            .eq('id', user.id)
            .single();

        setState(() {
          _currentDoctorId = response['id'];
          _currentDoctorName = response['name'] ?? 'Doctor';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading doctor: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.lightGradient,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.teal500),
            ),
          ),
        ),
      );
    }

    if (_currentDoctorId.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.lightGradient,
          ),
          child: const Center(
            child: Text(
              'Error loading doctor info',
              style: TextStyle(color: AppTheme.gray500),
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AppTheme.tealGradient,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.chat,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Messages',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search),
                    color: Colors.white,
                  ),
                ],
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: const TabBar(
                labelColor: AppTheme.teal600,
                unselectedLabelColor: AppTheme.gray500,
                indicatorColor: AppTheme.teal500,
                tabs: [
                  Tab(text: 'Patients'),
                  Tab(text: 'Families'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _buildPatientList(context),
                  _buildFamilyList(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientList(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client
          .from('patients')
          .stream(primaryKey: ['id'])
          .eq('doctor_id', _currentDoctorId)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.teal500),
            ),
          );
        }

        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return const Center(
            child: Text(
              'No patients assigned',
              style: TextStyle(color: AppTheme.gray500),
            ),
          );
        }

        final patients = snapshot.data as List;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: patients.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final patient = patients[index];
            final name = patient['name'] ?? 'Patient';
            final patientId = patient['id'];

            return _PatientChatItem(
              name: name,
              patientId: patientId,
              subtitle: 'Patient',
              isOnline: true,
              color: AppTheme.teal500,
              doctorId: _currentDoctorId,
              doctorName: _currentDoctorName,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatWithDoctorScreen(
                      currentSender: 'doctor',
                      chatTitle: name,
                      isOnline: true,
                      recipientId: patientId,
                      currentUserId: _currentDoctorId,
                      currentUserName: _currentDoctorName,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFamilyList(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client
          .from('family_members')
          .stream(primaryKey: ['id'])
          .eq('doctor_id', _currentDoctorId)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.teal500),
            ),
          );
        }

        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return const Center(
            child: Text(
              'No family members assigned',
              style: TextStyle(color: AppTheme.gray500),
            ),
          );
        }

        final families = snapshot.data as List;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: families.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final family = families[index];
            final name = family['name'] ?? 'Family Member';
            final familyId = family['id'];

            return _FamilyChatItem(
              name: name,
              familyId: familyId,
              subtitle: 'Family Member',
              isOnline: false,
              color: AppTheme.cyan500,
              doctorId: _currentDoctorId,
              doctorName: _currentDoctorName,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FamilyChatScreen(
                      currentSender: 'doctor',
                      chatTitle: name,
                      isOnline: false,
                      recipientId: familyId,
                      currentUserId: _currentDoctorId,
                      currentUserName: _currentDoctorName,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PatientChatItem extends StatelessWidget {
  final String name;
  final String patientId;
  final String subtitle;
  final bool isOnline;
  final Color color;
  final String doctorId;
  final String doctorName;
  final VoidCallback onTap;

  const _PatientChatItem({
    required this.name,
    required this.patientId,
    required this.subtitle,
    required this.isOnline,
    required this.color,
    required this.doctorId,
    required this.doctorName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String _generateChatId(String userId1, String userId2) {
      final ids = [userId1, userId2];
      ids.sort();
      return '${ids[0]}_${ids[1]}';
    }

    final chatId = _generateChatId(doctorId, patientId);

    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
        return await Supabase.instance.client
            .from('messages')
            .select()
            .eq('chat_id', chatId)
            .order('created_at', ascending: false)
            .limit(1);
      }),
      builder: (context, snapshot) {
        String lastMessage = 'No messages yet';
        String timeStr = '';

        if (snapshot.hasData && (snapshot.data as List).isNotEmpty) {
          final lastMsg = (snapshot.data as List).first;
          lastMessage = lastMsg['message_text'] ?? 'No messages';
          
          try {
            final createdAt = DateTime.parse(lastMsg['created_at']);
            timeStr = DateFormat('h:mm a').format(createdAt);
          } catch (e) {
            timeStr = '';
          }
        }

        return Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: color.withOpacity(0.2),
                        child: Icon(Icons.person, color: color, size: 28),
                      ),
                      if (isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.teal900,
                                ),
                              ),
                            ),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.gray500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.gray500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lastMessage,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.gray600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FamilyChatItem extends StatelessWidget {
  final String name;
  final String familyId;
  final String subtitle;
  final bool isOnline;
  final Color color;
  final String doctorId;
  final String doctorName;
  final VoidCallback onTap;

  const _FamilyChatItem({
    required this.name,
    required this.familyId,
    required this.subtitle,
    required this.isOnline,
    required this.color,
    required this.doctorId,
    required this.doctorName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String _generateChatId(String userId1, String userId2) {
      final ids = [userId1, userId2];
      ids.sort();
      return '${ids[0]}_${ids[1]}';
    }

    final chatId = _generateChatId(doctorId, familyId);

    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
        return await Supabase.instance.client
            .from('messages')
            .select()
            .eq('chat_id', chatId)
            .order('created_at', ascending: false)
            .limit(1);
      }),
      builder: (context, snapshot) {
        String lastMessage = 'No messages yet';
        String timeStr = '';

        if (snapshot.hasData && (snapshot.data as List).isNotEmpty) {
          final lastMsg = (snapshot.data as List).first;
          lastMessage = lastMsg['message_text'] ?? 'No messages';
          
          try {
            final createdAt = DateTime.parse(lastMsg['created_at']);
            timeStr = DateFormat('h:mm a').format(createdAt);
          } catch (e) {
            timeStr = '';
          }
        }

        return Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: color.withOpacity(0.2),
                        child: Icon(Icons.family_restroom, color: color, size: 28),
                      ),
                      if (isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.teal900,
                                ),
                              ),
                            ),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.gray500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.gray500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lastMessage,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.gray600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}