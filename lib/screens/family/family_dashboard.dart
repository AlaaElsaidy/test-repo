import 'package:alzcare/core/shared-prefrences/shared-prefrences-helper.dart';
import 'package:alzcare/core/supabase/doctor-advice-service.dart';
import 'package:alzcare/core/supabase/patient-family-service.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../theme/app_theme.dart';

class FamilyDashboard extends StatefulWidget {
  const FamilyDashboard({super.key});

  @override
  State<FamilyDashboard> createState() => _FamilyDashboardState();
}

class _FamilyDashboardState extends State<FamilyDashboard> {
  final DoctorAdviceService _adviceService = DoctorAdviceService();
  List<Map<String, dynamic>> _doctorAdvice = [];
  bool _loadingAdvice = false;

  @override
  void initState() {
    super.initState();
    _loadDoctorAdvice();
  }

  Future<void> _loadDoctorAdvice() async {
    setState(() => _loadingAdvice = true);
    try {
      final familyUid = SharedPrefsHelper.getString("familyUid") ??
          SharedPrefsHelper.getString("userId");
      if (familyUid == null) {
        setState(() => _loadingAdvice = false);
        return;
      }

      final advice = await _adviceService.getAdviceForFamilyMember(familyUid);
      setState(() {
        _doctorAdvice = advice;
        _loadingAdvice = false;
      });
    } catch (e) {
      setState(() => _loadingAdvice = false);
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

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Home)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.tealGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, Emily',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Caring for Margaret Smith',
                              style: TextStyle(
                                color: Color(0xFFCFFAFE),
                                fontSize: 16,
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
            ),
            const SizedBox(height: 16),

            // Caregiver Tips (text tip)
            Card(
              color: AppTheme.teal50,
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
                            Icons.lightbulb,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Tip of the Day',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.teal900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Maintain a consistent daily routine to help your loved one feel more secure and comfortable.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.teal900,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Read More Tips'),
                    ),
                  ],
                ),
              ),
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
                              child: CircularProgressIndicator());
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

                        return Column(
                          children: patients.map((patientData) {
                            final patient = patientData['patients']
                                as Map<String, dynamic>?;
                            if (patient == null) return const SizedBox();

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
                                    : Icon(Icons.person,
                                        color: AppTheme.teal600),
                              ),
                              title: Text(
                                patient['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Age: ${patient['age'] ?? 'N/A'} | ${patient['gender'] ?? ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: patientData['relation_type'] != null
                                  ? Chip(
                                      label: Text(
                                        patientData['relation_type'],
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: AppTheme.teal50,
                                    )
                                  : null,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Video Tips section
            _DoctorAdviceSection(
              advice: _doctorAdvice,
              loading: _loadingAdvice,
              onRefresh: _loadDoctorAdvice,
            ),
            const SizedBox(height: 16),

            // Emergency Contact
            Card(
              color: Colors.red[50],
              child: InkWell(
                onTap: () {},
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency Contact',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tap to call Dr. Johnson',
                              style: TextStyle(
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
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Doctor Advice Section ----------

class _DoctorAdviceSection extends StatelessWidget {
  final List<Map<String, dynamic>> advice;
  final bool loading;
  final VoidCallback onRefresh;

  const _DoctorAdviceSection({
    required this.advice,
    required this.loading,
    required this.onRefresh,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Doctor Advice',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.teal900,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (advice.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No advice from doctor yet',
                    style: TextStyle(color: AppTheme.gray600),
                  ),
                ),
              )
            else
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 12),
                  itemCount: advice.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final a = advice[i];
                    final adviceData = a['doctor_advice'] as Map<String, dynamic>?;
                    if (adviceData == null) return const SizedBox.shrink();

                    final tips = (adviceData['tips'] as List<dynamic>?)?.cast<String>() ?? [];
                    final videoUrl = adviceData['video_url'] as String?;
                    final title = adviceData['title'] as String? ?? 'Doctor Advice';
                    final doctorInfo = adviceData['users'] as Map<String, dynamic>?;
                    final doctorName = doctorInfo?['name'] as String? ?? 'Doctor';

                    return _DoctorAdviceCard(
                      title: title,
                      doctorName: doctorName,
                      tips: tips,
                      videoUrl: videoUrl,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _DoctorAdviceDetailScreen(
                              advice: adviceData,
                              doctorName: doctorName,
                            ),
                          ),
                        );
                      },
                    );
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
  final String title;
  final String doctorName;
  final List<String> tips;
  final String? videoUrl;
  final VoidCallback onTap;

  const _DoctorAdviceCard({
    required this.title,
    required this.doctorName,
    required this.tips,
    this.videoUrl,
    required this.onTap,
  });

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
            // thumbnail or icon
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 100,
                width: double.infinity,
                color: AppTheme.teal100,
                child: videoUrl != null
                    ? Stack(
                        children: [
                          const Center(
                            child: Icon(Icons.videocam,
                                size: 48, color: AppTheme.teal600),
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
                      )
                    : const Center(
                        child: Icon(Icons.tips_and_updates,
                            size: 48, color: AppTheme.teal600),
                      ),
              ),
            ),
            // title
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.teal900,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By $doctorName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.gray600,
                        fontSize: 12,
                      ),
                    ),
                    if (tips.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${tips.length} tip(s)',
                        style: const TextStyle(
                          color: AppTheme.gray500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorAdviceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> advice;
  final String doctorName;

  const _DoctorAdviceDetailScreen({
    required this.advice,
    required this.doctorName,
  });

  @override
  Widget build(BuildContext context) {
    final tips = (advice['tips'] as List<dynamic>?)?.cast<String>() ?? [];
    final videoUrl = advice['video_url'] as String?;
    final title = advice['title'] as String? ?? 'Doctor Advice';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.teal600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By $doctorName',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.gray600,
              ),
            ),
            const SizedBox(height: 16),
            if (videoUrl != null) ...[
              _VideoPlayerWidget(url: videoUrl),
              const SizedBox(height: 16),
            ],
            if (tips.isNotEmpty) ...[
              const Text(
                'Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.teal900,
                ),
              ),
              const SizedBox(height: 12),
              ...tips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  ',
                          style: TextStyle(
                              fontSize: 18, color: AppTheme.teal600)),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppTheme.gray600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String url;

  const _VideoPlayerWidget({required this.url});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
        }
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) {
      return Container(
        height: 200,
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller!),
          IconButton(
            iconSize: 64,
            color: Colors.white,
            onPressed: () {
              setState(() {
                if (_controller!.value.isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                }
              });
            },
            icon: Icon(
              _controller!.value.isPlaying
                  ? Icons.pause_circle
                  : Icons.play_circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Video Tips widgets/models (kept for backward compatibility) ----------

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