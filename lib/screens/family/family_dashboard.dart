import 'package:alzcare/core/models/doctor_advice_model.dart';
import 'package:alzcare/core/shared-prefrences/shared-prefrences-helper.dart';
import 'package:alzcare/core/supabase/doctor-advice-service.dart';
import 'package:alzcare/core/supabase/patient-family-service.dart';
import 'package:alzcare/core/supabase/supabase-config.dart';
import 'package:alzcare/core/supabase/supabase-service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../theme/app_theme.dart';
import 'family_notifications_screen.dart';

class FamilyDashboard extends StatelessWidget {
  const FamilyDashboard({super.key});

  Future<Map<String, dynamic>?> _loadUserInfo() async {
    try {
      final userId = SharedPrefsHelper.getString("userId") ??
          SharedPrefsHelper.getString("familyUid");
      if (userId == null) return null;
      final service = UserService();
      final user = await service.getUser(userId);
      // حاول تجيب صورة من جدول family_members
      final client = SupabaseConfig.client;
      final familyRow = await client
          .from('family_members')
          .select('image_url')
          .eq('id', userId)
          .maybeSingle();

      if (familyRow != null && familyRow['image_url'] != null) {
        return {
          ...?user,
          'image_url': familyRow['image_url'],
        };
      }

      return user;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _loadFamilyMemberInfo() async {
    try {
      final familyUid = SharedPrefsHelper.getString("familyUid") ?? 
                        SharedPrefsHelper.getString("userId");
      if (familyUid == null) return null;
      final client = SupabaseConfig.client;
      
      // Get family member with doctor_id
      final familyResponse = await client
          .from('family_members')
          .select('doctor_id')
          .eq('id', familyUid)
          .maybeSingle();
      
      if (familyResponse == null || familyResponse['doctor_id'] == null) {
        return null;
      }
      
      final doctorId = familyResponse['doctor_id'] as String;
      
      // Get doctor info from users table (doctor_id refers to users.id)
      final doctorResponse = await client
          .from('users')
          .select('id, name, phone, email')
          .eq('id', doctorId)
          .maybeSingle();
      
      if (doctorResponse == null) return null;
      
      return {
        'doctor_id': doctorId,
        'doctor': doctorResponse,
      };
    } catch (e) {
      debugPrint('Error loading family member info: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _loadLinkedPatients() async {
    try {
      final familyUid = SharedPrefsHelper.getString("familyUid");
      if (familyUid == null) {
        // Try userId if familyUid not found
        final userId = SharedPrefsHelper.getString("userId");
        if (userId == null) return [];
        final service = PatientFamilyService();
        return await service.getPatientsByFamily(userId);
      }
      final service = PatientFamilyService();
      return await service.getPatientsByFamily(familyUid);
    } catch (e) {
      return [];
    }
  }

  Future<List<DoctorAdviceModel>> _loadDoctorAdvice() async {
    final familyId =
        SharedPrefsHelper.getString("familyUid") ?? SharedPrefsHelper.getString("userId");
    if (familyId == null) return [];
    try {
      return await DoctorAdviceService().getAdviceForFamily(familyId);
    } catch (_) {
      return [];
    }
  }

  Future<void> _openAdviceVideo(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid video link')),
      );
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open video')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Home)
            FutureBuilder<Map<String, dynamic>?>(
              future: _loadUserInfo(),
              builder: (context, userSnapshot) {
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadLinkedPatients(),
                  builder: (context, patientsSnapshot) {
                    final userName =
                        userSnapshot.data?['name'] as String? ?? 'User';
                    final avatarUrl =
                        userSnapshot.data?['image_url'] as String?;
                    final patients = patientsSnapshot.data ?? [];
                    final firstPatient = patients.isNotEmpty 
                        ? patients.first['patients'] as Map<String, dynamic>?
                        : null;
                    final patientName = firstPatient?['name'] as String?;
                    
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppTheme.tealGradient,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                backgroundImage: avatarUrl != null &&
                                        avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: (avatarUrl == null ||
                                        avatarUrl.isEmpty)
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 32,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, $userName',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      patientName != null
                                          ? 'Caring for $patientName'
                                          : 'No patients linked yet',
                                      style: const TextStyle(
                                        color: Color(0xFFCFFAFE),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const FamilyNotificationsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.notifications_outlined),
                                color: Colors.white,
                                iconSize: 28,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Everything is going well today',
                                style: TextStyle(
                                  color: Color(0xFFCFFAFE),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Linked Patients section
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.teal500,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Linked Patients',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.teal900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _loadLinkedPatients(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Text(
                            'Error loading patients',
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        final patients = snapshot.data ?? [];

                        if (patients.isEmpty) {
                          return const Text(
                            'No patients linked yet',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.gray500,
                            ),
                          );
                        }

                        // Business rule: a family member is linked to
                        // exactly one active patient. Even if the API
                        // returns multiple rows (قديماً)، نظهر أول مريض فقط.
                        final firstRelation = patients.first;
                        final patient = firstRelation['patients']
                            as Map<String, dynamic>?;
                        if (patient == null) {
                          return const SizedBox.shrink();
                        }

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.teal100,
                            child: patient['photo_url'] != null
                                ? ClipOval(
                                    child: Image.network(
                                      patient['photo_url'],
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: AppTheme.teal600,
                                  ),
                          ),
                          title: Text(
                            patient['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // نعرض اسم المريض فقط بدون العمر والجندر
                          subtitle: const SizedBox.shrink(),
                          trailing: firstRelation['relation_type'] != null
                              ? Chip(
                                  label: Text(
                                    firstRelation['relation_type'],
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: AppTheme.teal50,
                                )
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _DoctorAdviceCard(loadAdvice: _loadDoctorAdvice, onOpenVideo: _openAdviceVideo),
            const SizedBox(height: 16),

            // Video Tips section - Show videos from doctor advice
            FutureBuilder<List<DoctorAdviceModel>>(
              future: _loadDoctorAdvice(),
              builder: (context, snapshot) {
                final advices = snapshot.data ?? [];
                final videoTips = <VideoTip>[];
                
                // Extract video URLs from doctor advice
                for (var advice in advices) {
                  if (advice.videoUrl != null && advice.videoUrl!.isNotEmpty) {
                    // Try to extract YouTube ID from URL if it's a YouTube link
                    String? youtubeId;
                    final uri = Uri.tryParse(advice.videoUrl!);
                    if (uri != null) {
                      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
                        youtubeId = uri.queryParameters['v'] ?? 
                                   uri.pathSegments.last;
                      }
                    }
                    
                    if (youtubeId != null && youtubeId.isNotEmpty) {
                      videoTips.add(VideoTip(
                        title: advice.title ?? 'Doctor Advice Video',
                        youtubeId: youtubeId,
                      ));
                    }
                  }
                }
                
                // If no videos from advice, show empty state or remove section
                if (videoTips.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return VideoTipsSection(
                  videos: videoTips,
                  onOpen: (tip) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoTipPlayerScreen(tip: tip),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Emergency Contact
            FutureBuilder<Map<String, dynamic>?>(
              future: _loadFamilyMemberInfo(),
              builder: (context, snapshot) {
                String doctorName = 'Doctor';
                String? doctorPhone;
                
                if (snapshot.hasData && snapshot.data != null) {
                  final doctor = snapshot.data!['doctor'] as Map<String, dynamic>?;
                  if (doctor != null) {
                    doctorName = doctor['name'] as String? ?? 'Doctor';
                    doctorPhone = doctor['phone'] as String?;
                  }
                }
                
                return Card(
                  color: Colors.red[50],
                  child: InkWell(
                    onTap: doctorPhone != null
                        ? () async {
                            final uri = Uri.parse('tel:$doctorPhone');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not make phone call')),
                              );
                            }
                          }
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.emergency,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Emergency Contact',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doctorPhone != null
                                      ? 'Tap to call $doctorName'
                                      : 'No doctor assigned',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.phone,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Video Tips widgets/models ----------

class VideoTip {
  final String title;
  final String youtubeId;
  const VideoTip({required this.title, required this.youtubeId});

  String get thumbUrl => 'https://img.youtube.com/vi/$youtubeId/0.jpg';
}

class VideoTipsSection extends StatelessWidget {
  final List<VideoTip> videos;
  final void Function(VideoTip tip) onOpen;

  const VideoTipsSection({
    super.key,
    required this.videos,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 8, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            const Text(
              'Video Tips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.teal900,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 12),
                itemCount: videos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final tip = videos[i];
                  return _VideoTipCard(tip: tip, onTap: () => onOpen(tip));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorAdviceCard extends StatelessWidget {
  final Future<List<DoctorAdviceModel>> Function() loadAdvice;
  final Future<void> Function(BuildContext context, String url) onOpenVideo;

  const _DoctorAdviceCard({
    required this.loadAdvice,
    required this.onOpenVideo,
  });

  void _showAllTipsDialog(BuildContext context, DoctorAdviceModel advice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Tips'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: advice.tips.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.teal600,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppTheme.teal900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.cyan500,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Doctor Advice',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.teal900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => loadAdvice(),
                  tooltip: 'Refresh advice',
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<DoctorAdviceModel>>(
              future: loadAdvice(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return const Text(
                    'Could not load advice right now.',
                    style: TextStyle(color: Colors.red),
                  );
                }

                final advices = snapshot.data ?? [];
                if (advices.isEmpty) {
                  return const Text(
                    'No advice shared yet. Your doctor can send tips and videos here.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.gray500,
                    ),
                  );
                }

                return Column(
                  children: advices.take(5).map((advice) {
                    final firstTip = advice.tips.isNotEmpty ? advice.tips.first : null;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Video Card (if video exists)
                          if (advice.videoUrl != null &&
                              advice.videoUrl!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _InlineVideoPlayer(
                              videoUrl: advice.videoUrl!,
                              thumbnailUrl: advice.thumbnailUrl,
                            ),
                          ],

                          // Tip Card (if tip exists)
                          if (firstTip != null) ...[
                            const SizedBox(height: 12),
                            Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                              color: AppTheme.teal50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppTheme.teal600,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.lightbulb,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Tip',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.teal600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            firstTip,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: AppTheme.teal900,
                                              height: 1.4,
                                            ),
                                          ),
                                          if (advice.tips.length > 1) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              '${advice.tips.length - 1} more tip${advice.tips.length > 2 ? 's' : ''}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.teal600,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // View All Tips Button (if more than one tip)
                          if (advice.tips.length > 1) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _showAllTipsDialog(context, advice);
                                },
                                icon: const Icon(Icons.tips_and_updates),
                                label: Text('View all ${advice.tips.length} tips'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.teal600,
                                  side: const BorderSide(color: AppTheme.teal200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Inline video player that displays video directly in the page
class _InlineVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const _InlineVideoPlayer({
    required this.videoUrl,
    this.thumbnailUrl,
  });

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller!.initialize();
      _controller!.addListener(_videoListener);
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
          _isPlaying = _controller!.value.isPlaying;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _videoListener() {
    if (_controller != null && mounted) {
      setState(() {
        _isPlaying = _controller!.value.isPlaying;
      });
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: _isInitialized && _controller != null
              ? _controller!.value.aspectRatio
              : 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video player or thumbnail
              if (_isLoading)
                Container(
                  color: Colors.black87,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else if (_hasError)
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.white, size: 48),
                        const SizedBox(height: 8),
                        const Text(
                          'Failed to load video',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _hasError = false;
                              _isLoading = true;
                            });
                            _initializeVideo();
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_isInitialized && _controller != null)
                VideoPlayer(_controller!)
              else
                Container(
                  color: Colors.black87,
                  child: widget.thumbnailUrl != null
                      ? Image.network(
                          widget.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),

              // Play/Pause overlay
              if (_isInitialized && _controller != null)
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    color: _isPlaying ? Colors.transparent : Colors.black38,
                    child: _isPlaying
                        ? const SizedBox.shrink()
                        : Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                size: 40,
                                color: AppTheme.teal600,
                              ),
                            ),
                          ),
                  ),
                ),

              // Video controls at bottom
              if (_isInitialized && _controller != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VideoProgressIndicator(
                          _controller!,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: AppTheme.teal600,
                            bufferedColor: Colors.white54,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: _togglePlayPause,
                              ),
                              Expanded(
                                child: Text(
                                  _formatDuration(_controller!.value.position) +
                                      ' / ' +
                                      _formatDuration(_controller!.value.duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              size: 40,
              color: AppTheme.teal600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tap to play video',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class _AdviceVideoPlayer extends StatefulWidget {
  final String url;
  final Future<void> Function(String url)? onOpenExternally;
  const _AdviceVideoPlayer({required this.url, this.onOpenExternally});

  @override
  State<_AdviceVideoPlayer> createState() => _AdviceVideoPlayerState();
}

class _AdviceVideoPlayerState extends State<_AdviceVideoPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _initFuture;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initFuture = _controller!.initialize().catchError((_) {
      setState(() => _isError = true);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppTheme.gray100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: TextButton.icon(
            onPressed: widget.onOpenExternally == null
                ? null
                : () => widget.onOpenExternally!(widget.url),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open video'),
          ),
        ),
      );
    }

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppTheme.gray100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        return Column(
          children: [
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller!),
                    if (!_controller!.value.isPlaying)
                      GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          color: Colors.black38,
                          child: const Icon(
                            Icons.play_arrow,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _togglePlay,
                  icon: Icon(
                    _controller!.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: AppTheme.cyan500,
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onOpenExternally == null
                      ? null
                      : () => widget.onOpenExternally!(widget.url),
                  icon: const Icon(Icons.fullscreen),
                  label: const Text('Open full screen'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _VideoTipCard extends StatelessWidget {
  final VideoTip tip;
  final VoidCallback onTap;
  const _VideoTipCard({required this.tip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: AppTheme.teal50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.gray200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  Image.network(
                    tip.thumbUrl,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      color: AppTheme.gray100,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported,
                          color: AppTheme.gray500),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.play_arrow,
                            color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // title
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Text(
                  tip.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.teal900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoTipPlayerScreen extends StatefulWidget {
  final VideoTip tip;
  const VideoTipPlayerScreen({super.key, required this.tip});

  @override
  State<VideoTipPlayerScreen> createState() => _VideoTipPlayerScreenState();
}

class _VideoTipPlayerScreenState extends State<VideoTipPlayerScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.tip.youtubeId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        enableCaption: true,
        // playsInline: false, // اختياري
      ),
    );
  }

  @override
  void dispose() {
    _controller.close(); // إغلاق الكنترولر مع iframe
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tip.title),
        backgroundColor: AppTheme.teal600,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(controller: _controller),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.tip.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.teal900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}