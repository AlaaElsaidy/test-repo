import 'dart:async';

import 'package:alzcare/config/screen_sizer/size_extension.dart';
import 'package:alzcare/config/shared/widgets/loading.dart';
import 'package:alzcare/core/shared-prefrences/shared-prefrences-helper.dart';
import 'package:alzcare/core/supabase/supabase-service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/router/routes.dart';
import '../../../../../config/shared/widgets/custom-button.dart';
import '../../../../../config/shared/widgets/error-dialoge.dart';
import '../../../../../config/utilis/app_colors.dart';
import '../../../signup/bloc/sign_up_cubit.dart';
import '../../data/doctor-repo.dart';
import '../../data/doctorModel.dart';
import '../cubit/doctor_cubit.dart';
import '../widgets/doctor-card.dart';

class DoctorSelectionScreen extends StatefulWidget {
  const DoctorSelectionScreen({super.key});

  @override
  State<DoctorSelectionScreen> createState() => _DoctorSelectionScreenState();
}

class _DoctorSelectionScreenState extends State<DoctorSelectionScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;

  List<Doctor> _doctors = [];

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
          return d.name.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return BlocProvider(
      create: (context) =>
          DoctorCubit(DoctorRepo(DoctorService(), FamilyMemberService()))
            ..getDoctors(),
      child: Scaffold(
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
              child: BlocListener<DoctorCubit, DoctorState>(
                listener: (context, state) {
                  if (state is UpdateFamilySuccess) {
                    Navigator.pushNamed(context, AppRoutes.paymentDetails);
                  }
                  if (state is DoctorFailure) {
                    showErrorDialog(
                        context: context,
                        error: state.errorMessage,
                        title: "Doctor Failed!");
                  }
                  if (state is UpdateFamilyFailure) {
                    showErrorDialog(
                        context: context,
                        error: state.errorMessage,
                        title: "Updating Failed");
                  }
                },
                child: BlocBuilder<DoctorCubit, DoctorState>(
                  builder: (context, state) {
                    if (state is DoctorSuccess) {
                      _doctors = state.doctors
                          .map(
                            (e) => Doctor.fromJson(e),
                          )
                          .toList();
                      return Stack(
                        children: [
                          Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                        horizontal: context.w(18))
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
                                        "Results: ${_filtered.isEmpty ? _doctors.length : _filtered.length}",
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
                                  padding: EdgeInsets.symmetric(
                                      horizontal: context.w(18)),
                                  child: _doctors.isEmpty
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
                                          physics:
                                              const BouncingScrollPhysics(),
                                          padding: EdgeInsets.only(
                                              bottom: context.h(16)),
                                          itemCount: _filtered.isEmpty
                                              ? _doctors.length
                                              : _filtered.length,
                                          separatorBuilder: (_, __) =>
                                              SizedBox(height: context.h(12)),
                                          itemBuilder: (context, i) {
                                            final d = _filtered.isEmpty
                                                ? _doctors[i]
                                                : _filtered[i];
                                            final selected =
                                                d.id == _selectedId;
                                            return DoctorCardSimple(
                                              doctor: d,
                                              selected: selected,
                                              onTap: () => setState(
                                                  () => _selectedId = d.id),
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
                                    onClick: () async {
                                      final selected = _doctors.firstWhere(
                                        (d) => d.id == _selectedId,
                                        orElse: () => const Doctor.empty(),
                                      );
                                      if (selected.id.isEmpty) {
                                        showErrorDialog(
                                            context: context,
                                            error: "please select a doctor.",
                                            title: "Selection Failed!");
                                        return;
                                      }
                                      await BlocProvider.of<DoctorCubit>(
                                              context)
                                          .updateFamily(
                                              familyId:
                                                  SharedPrefsHelper.getString(
                                                      "familyUid")!,
                                              data: {"doctor_id": _selectedId});
                                    },
                                    text: state is AddFamilyLoading
                                        ? "Loading..."
                                        : "Confirm Selection",
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (state is AddFamilyLoading)
                            Positioned.fill(
                              child: AbsorbPointer(
                                absorbing: true,
                                child: Container(
                                  color: Colors.black.withOpacity(0.1),
                                  child: const Center(child: LoadingPage()),
                                ),
                              ),
                            )
                        ],
                      );
                    }
                    return const LoadingPage();
                  },
                ),
              ),
            ),
          ],
        ),
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
                hintText: "Search by name ",
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
                    icon: const Icon(Icons.close_rounded,
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
