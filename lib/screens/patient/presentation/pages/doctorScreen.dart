import 'dart:async';
import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:flutter/material.dart';

import '../../../../../config/router/routes.dart';
import '../../../../config/shared/widgets/custom-button.dart';
import '../../../../config/utilis/app_colors.dart';

class DoctorSelectionScreen extends StatefulWidget {
  const DoctorSelectionScreen({super.key});

  @override
  State<DoctorSelectionScreen> createState() => _DoctorSelectionScreenState();
}

class _DoctorSelectionScreenState extends State<DoctorSelectionScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;

  final List<Doctor> _doctors = const [
    Doctor(
      id: '1',
      name: 'Dr. Sarah Johnson',
      specialty: 'Neurologist',
      rating: 4.8,
      hospital: 'Springfield General',
      years: 12,
      isOnline: true,
    ),
    Doctor(
      id: '2',
      name: 'Dr. Ahmed Khaled',
      specialty: 'Neurologist',
      rating: 4.6,
      hospital: 'City Care',
      years: 9,
      isOnline: false,
    ),
    Doctor(
      id: '3',
      name: 'Dr. Lina Mostafa',
      specialty: 'Neurologist',
      rating: 4.9,
      hospital: 'Green Valley',
      years: 15,
      isOnline: true,
    ),
    Doctor(
      id: '4',
      name: 'Dr. Omar Hassan',
      specialty: 'Neurologist',
      rating: 4.5,
      hospital: 'North Clinic',
      years: 7,
      isOnline: true,
    ),
  ];

  late List<Doctor> _filtered;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _filtered = List.of(_doctors);
    _searchController.addListener(_onSearchChanged);
    _searchFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _applySearch);
  }

  void _applySearch() {
    final q = _searchController.text.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.of(_doctors);
      } else {
        _filtered = _doctors.where((d) {
          return d.name.toLowerCase().contains(q) ||
              d.hospital.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -width * 0.25,
            left: -width * 0.15,
            child: _decorCircle(size: width * 0.7),
          ),
          Positioned(
            bottom: -width * 0.30,
            right: -width * 0.20,
            child: _decorCircle(size: width * 0.9),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.w(18))
                      .copyWith(top: context.h(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Select Doctor",
                        style: TextStyle(
                          color: const Color(0xFF0E3E3B),
                          fontSize: context.sp(26),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: context.h(6)),
                      Text(
                        "Choose one doctor from the list",
                        style: TextStyle(
                          color: const Color(0xFF7EA9A3),
                          fontWeight: FontWeight.w600,
                          fontSize: context.sp(14),
                        ),
                      ),
                      SizedBox(height: context.h(14)),
                      _searchBar(context),
                      SizedBox(height: context.h(10)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Results: ${_filtered.length}",
                          style: TextStyle(
                            color: const Color(0xFF7EA9A3),
                            fontWeight: FontWeight.w700,
                            fontSize: context.sp(12.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.h(8)),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.w(18)),
                    child: _filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No doctors found',
                              style: TextStyle(
                                color: const Color(0xFF7EA9A3),
                                fontWeight: FontWeight.w600,
                                fontSize: context.sp(14),
                              ),
                            ),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.only(bottom: context.h(16)),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: context.h(12)),
                            itemBuilder: (context, i) {
                              final d = _filtered[i];
                              final selected = d.id == _selectedId;
                              return DoctorCardSimple(
                                doctor: d,
                                selected: selected,
                                onTap: () => setState(() => _selectedId = d.id),
                              );
                            },
                          ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.w(18),
                    0,
                    context.w(18),
                    context.h(16),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      onClick: () {
                        final selected = _doctors.firstWhere(
                          (d) => d.id == _selectedId,
                          orElse: () => const Doctor.empty(),
                        );
                        if (selected.id.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a doctor'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        Navigator.pushNamed(context, AppRoutes.paymentDetails);
                      },
                      text: "Confirm Selection",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    final focused = _searchFocus.hasFocus;
    final hasText = _searchController.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(
          horizontal: context.w(12), vertical: context.h(2)),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FEFD),
        borderRadius: BorderRadius.circular(context.w(16)),
        border: Border.all(
          color: focused
              ? AppColors.primaryColor.withOpacity(.6)
              : const Color(0xFFE6F1EF),
          width: focused ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(focused ? 0.06 : 0.03),
            blurRadius: focused ? 14 : 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.w(10)),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_rounded,
                size: context.sp(18), color: AppColors.tealDark),
          ),
          SizedBox(width: context.w(10)),
          Expanded(
            child: TextField(
              focusNode: _searchFocus,
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: "Search by name or hospital",
                border: InputBorder.none,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: hasText
                ? IconButton(
                    key: const ValueKey('clear'),
                    onPressed: () {
                      _searchController.clear();
                      _applySearch();
                      FocusScope.of(context).requestFocus(_searchFocus);
                    },
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.primaryColor, size: 20),
                    splashRadius: 18,
                  )
                : const SizedBox(key: ValueKey('empty'), width: 0, height: 0),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.20),
            const Color(0xFF06B6D4).withOpacity(0.20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.10),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }
}

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final String hospital;
  final int years;
  final bool isOnline;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.hospital,
    required this.years,
    required this.isOnline,
  });

  const Doctor.empty()
      : id = '',
        name = '',
        specialty = '',
        rating = 0,
        hospital = '',
        years = 0,
        isOnline = false;
}

class DoctorCardSimple extends StatelessWidget {
  const DoctorCardSimple({
    super.key,
    required this.doctor,
    required this.selected,
    required this.onTap,
  });

  final Doctor doctor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const onlineColor = Color(0xFF22C55E);

    return InkWell(
      borderRadius: BorderRadius.circular(context.w(18)),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: context.w(14),
          vertical: context.h(14),
        ),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primaryColor.withOpacity(.05) : Colors.white,
          borderRadius: BorderRadius.circular(context.w(18)),
          border: Border.all(
            color: selected
                ? AppColors.primaryColor
                : AppColors.borderColor.withOpacity(.5),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + حالة متصل
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: context.w(56),
                  height: context.w(56),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(.20),
                        const Color(0xFF06B6D4).withOpacity(.20),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: context.w(48),
                      height: context.w(48),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primaryColor,
                        size: context.w(26),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: doctor.isOnline
                            ? onlineColor
                            : const Color(0xFF9ABFBA),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          doctor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF163E39),
                            fontSize: context.sp(16),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(width: context.w(6)),
                      Icon(Icons.verified_rounded,
                          size: 18, color: AppColors.primaryColor),
                    ],
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    "${doctor.specialty} • ${doctor.hospital}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF7EA9A3),
                      fontWeight: FontWeight.w700,
                      fontSize: context.sp(12.5),
                    ),
                  ),
                  SizedBox(height: context.h(6)),
                  Row(
                    children: [
                      _ratingRow(doctor.rating, context),
                      SizedBox(width: context.w(10)),
                      _metaChip(
                          "${doctor.years} yrs", Icons.badge_outlined, context),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: context.w(8)),

            _selectionBadge(selected, context),
          ],
        ),
      ),
    );
  }

  Widget _ratingRow(double rating, BuildContext context) {
    final full = rating.floor();
    final hasHalf = (rating - full) >= 0.5;
    return Row(
      children: [
        ...List.generate(
          5,
          (i) {
            if (i < full) {
              return Icon(Icons.star, size: 16, color: Colors.amber[600]);
            } else if (i == full && hasHalf) {
              return Icon(Icons.star_half, size: 16, color: Colors.amber[600]);
            } else {
              return Icon(Icons.star_border,
                  size: 16, color: Colors.amber[600]);
            }
          },
        ),
        SizedBox(width: context.w(6)),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            color: const Color(0xFF2E5753),
            fontWeight: FontWeight.w700,
            fontSize: context.sp(12),
          ),
        ),
      ],
    );
  }

  Widget _metaChip(String label, IconData icon, BuildContext context) {
    const c = AppColors.primaryColor;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(8),
        vertical: context.h(4),
      ),
      decoration: BoxDecoration(
        color: c.withOpacity(.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          SizedBox(width: context.w(4)),
          Text(
            label,
            style: TextStyle(
              fontSize: context.sp(11.5),
              fontWeight: FontWeight.w800,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectionBadge(bool selected, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(6),
      ),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryColor.withOpacity(.12)
            : const Color(0xFFF3FAF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.primaryColor.withOpacity(.4)
              : AppColors.primaryColor.withOpacity(.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: selected ? AppColors.primaryColor : const Color(0xFF9ABFBA),
          ),
          SizedBox(width: context.w(6)),
          Text(
            selected ? "Selected" : "Select",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: context.sp(12.5),
              color:
                  selected ? AppColors.primaryColor : const Color(0xFF2E5753),
            ),
          ),
        ],
      ),
    );
  }
}
