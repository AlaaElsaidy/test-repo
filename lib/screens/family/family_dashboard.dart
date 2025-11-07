import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../theme/app_theme.dart';

class FamilyDashboard extends StatelessWidget {
  const FamilyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة فيديوهات: نفس الفيديو مكرر 3 مرات
    final videoTips = const [
      VideoTip(
        title: 'نصائح للتعامل مع الزهايمر (1)',
        youtubeId: 'rfYW0Ih7J5Q',
      ),
      VideoTip(
        title: 'نصائح للتعامل مع الزهايمر (2)',
        youtubeId: 'rfYW0Ih7J5Q',
      ),
      VideoTip(
        title: 'نصائح للتعامل مع الزهايمر (3)',
        youtubeId: 'rfYW0Ih7J5Q',
      ),
    ];

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

            // Video Tips section
            VideoTipsSection(
              videos: videoTips,
              onOpen: (tip) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoTipPlayerScreen(tip: tip),
                  ),
                );
              },
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