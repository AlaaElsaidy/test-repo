import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DoctorAdviceScreen extends StatefulWidget {
  const DoctorAdviceScreen({super.key});

  @override
  State<DoctorAdviceScreen> createState() => _DoctorAdviceScreenState();
}

class _DoctorAdviceScreenState extends State<DoctorAdviceScreen> {
  String selectedCategory = 'All';

  // Search state
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // Static data (English) – Alzheimer caregiver-focused
  final List<Map<String, dynamic>> _articles = [
    // Handling Situations
    {
      'title': 'How to Handle Difficult Situations',
      'category': 'Handling Situations',
      'readTime': '6m',
      'icon': Icons.tips_and_updates,
      'color': AppTheme.teal600,
      'isFeatured': true,
      'intro':
          'When behaviors escalate, staying calm and using clear steps helps keep everyone safe.',
      'points': [
        'Pause and breathe; keep your voice low and body language relaxed.',
        'Check triggers: pain, hunger, thirst, bathroom needs, noise, temperature, or fatigue.',
        'Validate feelings (“I can see this is upsetting”) rather than correcting facts.',
        'Redirect gently to a calming activity: a short walk, music, a photo album, or a simple task.',
        'Offer simple choices (A or B) and remove stressors from the environment.',
        'Ensure safety first; if escalation continues, step back, give space, and re-approach later.',
        'After the event, note what worked and adjust routine to prevent recurrences.',
      ],
    },
    {
      'title': 'Understanding Memory Loss Stages',
      'category': 'Handling Situations',
      'readTime': '5m',
      'icon': Icons.psychology,
      'color': AppTheme.teal500,
      'isFeatured': false,
      'intro':
          'Alzheimer’s typically progresses from early to late stages, each with different needs for support.',
      'points': [
        'Early: mild forgetfulness, word-finding issues; use calendars, labels, and simple routines.',
        'Middle: confusion about time/place, repetitive questions; keep consistent schedules and reduce choices.',
        'Late: severe memory impairment and high dependence; focus on comfort and sensory cues.',
        'Avoid arguing or quizzing; validate feelings and redirect with empathy.',
        'Keep an emergency info sheet and medication list accessible.',
      ],
    },
    {
      'title': 'Managing Sundown Syndrome',
      'category': 'Handling Situations',
      'readTime': '6m',
      'icon': Icons.nights_stay,
      'color': Colors.purple,
      'isFeatured': false,
      'intro':
          'Sundowning can increase confusion and agitation in late afternoon/evening.',
      'points': [
        'Keep a predictable routine; increase natural morning light.',
        'Avoid late naps; limit caffeine/sugar after early afternoon.',
        'Create a calm evening environment: low noise, warm lighting.',
        'Offer soothing activities: soft music, hand massage, folding towels.',
        'Provide a light evening snack and ensure hydration.',
        'Ensure safety (door locks/alarms); consult a doctor if symptoms suddenly worsen.',
      ],
    },
    {
      'title': 'Handling Aggression & Agitation',
      'category': 'Handling Situations',
      'readTime': '6m',
      'icon': Icons.warning_amber_rounded,
      'color': Colors.redAccent,
      'isFeatured': false,
      'intro':
          'Aggression often signals discomfort, fear, or frustration rather than intent to harm.',
      'points': [
        'Identify triggers (pain, noise, rush, unfamiliar places).',
        'Validate feelings and keep a safe distance; avoid physical restraint.',
        'Use short, calm sentences; offer one-step instructions.',
        'Redirect to a simple, meaningful activity; reduce demands.',
        'Seek medical review if behaviors change suddenly (pain, infection, medication side effects).',
      ],
    },
    {
      'title': 'Dealing with Wandering',
      'category': 'Handling Situations',
      'readTime': '5m',
      'icon': Icons.directions_walk,
      'color': Colors.orange,
      'isFeatured': false,
      'intro':
          'Wandering can be triggered by restlessness, past routines, or unmet needs.',
      'points': [
        'Schedule daily exercise and outdoor time to reduce restlessness.',
        'Use door alarms, chimes, or motion sensors; keep keys out of sight.',
        'Provide ID bracelet and a recent photo; inform neighbors.',
        'Redirect with purposeful tasks: sorting, folding, watering plants.',
        'Check unmet needs: bathroom, thirst, hunger, pain.',
      ],
    },
    {
      'title': 'Creating a Safe Home Environment',
      'category': 'Handling Situations',
      'readTime': '6m',
      'icon': Icons.security,
      'color': Colors.indigo,
      'isFeatured': false,
      'intro':
          'Small home adjustments reduce risks and help maintain independence longer.',
      'points': [
        'Remove tripping hazards; secure rugs and tidy cords.',
        'Install grab bars, non-slip mats, and good lighting (especially hallways/bathroom).',
        'Label doors/rooms; keep meds/chemicals locked and out of sight.',
        'Keep daily essentials visible and within easy reach.',
        'Use simple, consistent layouts and reduce clutter to lower confusion.',
      ],
    },

    // Caregiver Tips
    {
      'title': 'Self-Care Tips for Caregivers',
      'category': 'Caregiver Tips',
      'readTime': '7m',
      'icon': Icons.favorite,
      'color': Colors.pink,
      'isFeatured': true,
      'intro':
          'You cannot pour from an empty cup. Protect your energy to provide steady care.',
      'points': [
        'Plan short daily breaks; prioritize consistent sleep and rest.',
        'Ask for help; assign simple, specific tasks to family/friends.',
        'Eat balanced meals and stay hydrated.',
        'Move your body: short walks, stretching, or breathing exercises.',
        'Watch for burnout signs: irritability, poor sleep, isolation—seek support early.',
      ],
    },
    {
      'title': 'Communication Strategies',
      'category': 'Caregiver Tips',
      'readTime': '4m',
      'icon': Icons.chat_bubble,
      'color': AppTheme.teal500,
      'isFeatured': false,
      'intro':
          'Clear, calm, simple communication reduces stress for both of you.',
      'points': [
        'Get attention first (eye contact, name, gentle touch).',
        'Use short sentences and one-step instructions; allow extra time to respond.',
        'Ask yes/no or two-choice questions instead of open-ended ones.',
        'Avoid correcting or arguing; validate feelings and reassure.',
        'Use visual cues, gestures, and written reminders.',
      ],
    },
    {
      'title': 'Nutrition & Hydration Basics',
      'category': 'Caregiver Tips',
      'readTime': '4m',
      'icon': Icons.restaurant,
      'color': Colors.green,
      'isFeatured': false,
      'intro':
          'Regular, nutrient-dense meals and hydration support mood, energy, and cognition.',
      'points': [
        'Offer small, frequent meals if appetite is low.',
        'Use color-contrasting plates; choose easy-to-chew, high-protein options.',
        'Keep a water schedule and hydrating snacks (soups, fruits, yogurt).',
        'Monitor weight and note changes to discuss with a clinician.',
      ],
    },
    {
      'title': 'Sleep and Routine Planning',
      'category': 'Caregiver Tips',
      'readTime': '4m',
      'icon': Icons.bedtime,
      'color': Colors.blue,
      'isFeatured': false,
      'intro':
          'Consistent routines and a calming wind-down can improve sleep quality.',
      'points': [
        'Keep regular wake/bed times; get morning sunlight.',
        'Limit daytime naps and late caffeine.',
        'Create a wind-down routine: warm drink, soft music, dim lights.',
        'Ensure a comfortable room temperature and a night light for safety.',
      ],
    },
    {
      'title': 'Bathing & Personal Care',
      'category': 'Caregiver Tips',
      'readTime': '5m',
      'icon': Icons.clean_hands,
      'color': Colors.brown,
      'isFeatured': false,
      'intro':
          'Preparation, dignity, and safety make personal care more comfortable.',
      'points': [
        'Warm the room; prepare towels and supplies in advance.',
        'Explain each step; allow choices (morning or evening, bath or shower).',
        'Use non-slip mats and a shower seat; check water temperature.',
        'Keep sessions short; play calming music if helpful.',
      ],
    },

    // Nutrition & Health
    {
      'title': 'Nutrition & Hydration for Alzheimer’s Care',
      'category': 'Nutrition & Health',
      'readTime': '5m',
      'icon': Icons.restaurant,
      'color': Colors.green,
      'isFeatured': true,
      'intro':
          'Balanced meals and consistent fluids support energy, mood, and cognition.',
      'points': [
        'Offer small, frequent meals if appetite is low; add calorie-dense snacks (nut butters, yogurt).',
        'Use contrasting plate colors and reduce table clutter to help focus.',
        'Encourage fluids throughout the day (water, soups, smoothies); keep a visible bottle within reach.',
        'Support safe swallowing: upright posture, slow pace, small bites; consult a speech therapist if coughing during meals.',
        'Monitor weight and note sudden changes; discuss with a clinician promptly.',
      ],
    },

    // Safety & Security
    {
      'title': 'Home Safety Checklist for Dementia',
      'category': 'Safety & Security',
      'readTime': '6m',
      'icon': Icons.health_and_safety,
      'color': Colors.deepOrange,
      'isFeatured': true,
      'intro': 'A safer home lowers fall risk and prevents emergencies.',
      'points': [
        'Remove tripping hazards; secure rugs, tape cords, and tidy walkways.',
        'Install grab bars and non-slip mats; add night lights to halls and the bathroom.',
        'Lock medications and cleaning products; label doors and consider stove safety devices.',
        'Use door chimes/alarms to reduce wandering risk; keep keys and car fobs out of sight.',
        'Prepare an emergency plan: contacts list, medical info, and a small go-bag.',
      ],
    },

    // Activities & Engagement
    {
      'title': 'Simple Activities that Calm and Connect',
      'category': 'Activities & Engagement',
      'readTime': '5m',
      'icon': Icons.emoji_people,
      'color': Colors.amber,
      'isFeatured': true,
      'intro':
          'Short, meaningful activities reduce agitation and build connection.',
      'points': [
        'Use familiar tasks: folding towels, sorting buttons, watering plants.',
        'Engage senses: hand massage with lotion, soft music, scented herbs.',
        'Use photos or memory boxes to spark positive conversation.',
        'Keep steps simple, one at a time; stop before fatigue.',
        'Schedule activities when energy is highest (often morning).',
      ],
    },

    // Legal & Financial
    {
      'title': 'Legal and Financial Planning Basics',
      'category': 'Legal & Financial',
      'readTime': '6m',
      'icon': Icons.account_balance,
      'color': Colors.blueGrey,
      'isFeatured': true,
      'intro':
          'Early planning protects the person’s wishes and reduces stress later.',
      'points': [
        'Complete durable powers of attorney (healthcare and finances) and advance directives.',
        'Review wills/beneficiaries; store documents in an accessible, shared location.',
        'Create a simple budget and track care-related expenses and receipts.',
        'Explore benefits/coverage options (insurance, government programs, respite).',
        'Consult an elder-law professional for state-specific guidance.',
      ],
    },

    // Support Groups (new, general non-location-specific)
    {
      'title': 'Caregiver Support Groups: Getting Started',
      'category': 'Support Groups',
      'readTime': '5m',
      'icon': Icons.groups,
      'color': Colors.cyan,
      'isFeatured': true,
      'intro':
          'Support groups offer shared experience, practical tips, and emotional relief for caregivers.',
      'points': [
        'Clarify what you need: information, emotional support, or practical tips.',
        'Start with expectations: listening is okay—sharing is optional until you feel ready.',
        'Bring 1–2 questions or challenges you want input on.',
        'Respect confidentiality; what’s shared in group stays in group.',
        'Note helpful ideas to try at home and review next time.',
      ],
    },
    {
      'title': 'Making the Most of Your Support Group',
      'category': 'Support Groups',
      'readTime': '4m',
      'icon': Icons.forum,
      'color': Colors.lightBlue,
      'isFeatured': false,
      'intro':
          'A few simple habits help you benefit more from each session.',
      'points': [
        'Arrive a bit early to settle and connect with members.',
        'Share briefly and focus on one concrete issue at a time.',
        'Ask for specific examples or scripts you can use at home.',
        'Set a small action goal after each meeting and track what worked.',
        'Offer empathy and avoid judgment—everyone’s journey is different.',
      ],
    },
    {
      'title': 'Setting Up a Family Support Circle',
      'category': 'Support Groups',
      'readTime': '5m',
      'icon': Icons.family_restroom,
      'color': Colors.teal,
      'isFeatured': false,
      'intro':
          'Create a small circle of relatives/friends to share care tasks and support.',
      'points': [
        'List recurring needs (meals, rides, visits, medication pickups).',
        'Assign simple roles based on availability and strengths.',
        'Use a shared calendar and a group chat for coordination.',
        'Hold brief check-ins to adjust tasks and prevent burnout.',
        'Celebrate small wins and express appreciation regularly.',
      ],
    },
  ];

  // Categories (includes extra chips; Support Groups included and now has data)
  List<String> get _categories => const [
        'All',
        'Handling Situations',
        'Support Groups',
        'Caregiver Tips',
        'Nutrition & Health',
        'Safety & Security',
        'Activities & Engagement',
        'Legal & Financial',
      ];

  // Apply category + search filters together
  List<Map<String, dynamic>> get filteredArticles {
    final byCat = selectedCategory == 'All'
        ? _articles
        : _articles
            .where((a) => (a['category'] as String) == selectedCategory)
            .toList();

    if (_query.isEmpty) return byCat;
    final q = _query.toLowerCase();
    return byCat.where((a) {
      final title = (a['title'] as String).toLowerCase();
      final intro = (a['intro'] as String).toLowerCase();
      final pointsText =
          ((a['points'] as List<dynamic>).cast<String>()).join(' ').toLowerCase();
      return title.contains(q) || intro.contains(q) || pointsText.contains(q);
    }).toList();
  }

  // Featured item aligned with current filters (null if no results)
  Map<String, dynamic>? get featuredArticle {
    final list = filteredArticles;
    if (list.isEmpty) return null;
    final idx = list.indexWhere((a) => (a['isFeatured'] ?? false) == true);
    return idx != -1 ? list[idx] : list.first;
  }

  // Bottom sheet for article details
  void _showArticleDetails(
    BuildContext context, {
    required String title,
    required String category,
    required String readTime,
    required IconData icon,
    required Color color,
    required String intro,
    required List<String> points,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.teal900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppTheme.gray500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  readTime,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.gray500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    intro,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppTheme.gray600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...points.map(
                    (p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '•  ',
                            style:
                                TextStyle(fontSize: 18, color: AppTheme.teal600),
                          ),
                          Expanded(
                            child: Text(
                              p,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: AppTheme.gray600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.teal600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Close'),
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

  String _shorten(String text, {int max = 110}) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}...';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feat = featuredArticle;
    final results = filteredArticles;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resources & Advice',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.teal900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Support for caregivers and families',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.gray600,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.tealGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.article,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.gray100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppTheme.gray500),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v.trim()),
                      decoration: const InputDecoration(
                        hintText: 'Search advice topics...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.gray500),
                      onPressed: () {
                        setState(() {
                          _query = '';
                          _searchCtrl.clear();
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Categories
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.teal900,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final label = _categories[index];
                  return _CategoryChip(
                    label: label,
                    isSelected: selectedCategory == label,
                    onTap: () => setState(() => selectedCategory = label),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Featured (hidden if no results)
            if (feat != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.teal500, AppTheme.cyan500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Featured',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      feat['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _shorten(feat['intro'] as String, max: 110),
                      style: const TextStyle(
                        color: Color(0xFFCFFAFE),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showArticleDetails(
                            context,
                            title: feat['title'] as String,
                            category: feat['category'] as String,
                            readTime: feat['readTime'] as String,
                            icon: feat['icon'] as IconData,
                            color: feat['color'] as Color,
                            intro: feat['intro'] as String,
                            points: (feat['points'] as List<dynamic>).cast<String>(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.teal600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Read More'),
                      ),
                    ),
                  ],
                ),
              ),

            if (feat == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'No articles found',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.teal900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _query.isEmpty
                          ? 'No articles in "$selectedCategory" yet.'
                          : 'No results for "$_query" in "$selectedCategory".',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.gray600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Popular Articles
            const Text(
              'Popular Articles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.teal900,
              ),
            ),
            const SizedBox(height: 12),

            if (results.isEmpty)
              Text(
                _query.isEmpty
                    ? '— No articles in "$selectedCategory" —'
                    : '— No results for "$_query" —',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.gray600,
                ),
              )
            else
              ...results.map((a) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AdviceCard(
                    title: a['title'] as String,
                    category: a['category'] as String,
                    readTime: a['readTime'] as String,
                    icon: a['icon'] as IconData,
                    color: a['color'] as Color,
                    onTap: () => _showArticleDetails(
                      context,
                      title: a['title'] as String,
                      category: a['category'] as String,
                      readTime: a['readTime'] as String,
                      icon: a['icon'] as IconData,
                      color: a['color'] as Color,
                      intro: a['intro'] as String,
                      points: (a['points'] as List<dynamic>).cast<String>(),
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.teal500 : AppTheme.gray100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.gray600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final String title;
  final String category;
  final String readTime;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdviceCard({
    required this.title,
    required this.category,
    required this.readTime,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.teal900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.gray500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          readTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.gray500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.gray500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}