// ignore_for_file: deprecated_member_use

import 'package:carride/app/modules/view/account_screen/profile_screen/profile_screen/lifetime_highlights.dart';
import 'package:carride/app/modules/view/account_screen/profile_screen/profile_screen/user_details.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/account_controllers/profile_controllers/profile_screen_controller.dart';

class ProfileScreenView extends GetView<ProfileScreenController> {
  const ProfileScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProfileScreenController>();

    return Scaffold(
      backgroundColor: ccBackground,
      appBar: AppBar(
        backgroundColor: ccSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => c.isLoading
            ? const SizedBox.shrink()
            : Text(
                "${c.userProfileApiModel?.userInfo?.name ?? ''}'s Profile",
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ccNavyText,
                ),
              )),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: ccInputBorder),
        ),
      ),
      body: Obx(
        () => c.isLoading
            ? const Center(child: CircularProgressIndicator(color: ccPrimary))
            : c.userProfileApiModel?.stats == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: ccSecondaryText, size: 40),
                        const SizedBox(height: 12),
                        const Text(
                          "Unable to load profile",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: ccSecondaryText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => c.userProfileApi(),
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── User card ─────────────────────────────────────
                    const UserDetails(),
                    const SizedBox(height: 20),

                    // ── Lifetime stats ────────────────────────────────
                    const LifetimeHighlights(),
                    const SizedBox(height: 20),

                    // ── Upcoming trips ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _SectionHeader(
                        title: "Upcoming Trips",
                        showAction: (c.userProfileApiModel?.upcomingTrips?.length ?? 0) > 3,
                        onAction: c.upcomingTripBottomsheet,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (c.userProfileApiModel?.upcomingTrips?.isNotEmpty == true) ...[
                      SizedBox(
                        height: 170,
                        child: PageView.builder(
                          itemCount: (c.userProfileApiModel!.upcomingTrips!.length < 3
                              ? c.userProfileApiModel!.upcomingTrips!.length
                              : 3),
                          clipBehavior: Clip.none,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (val) {
                            c.currentIndex = val;
                            c.update();
                          },
                          itemBuilder: (ctx, i) => i < 3
                              ? c.upcomingTripData(
                                  upcomingTrip:
                                      c.userProfileApiModel!.upcomingTrips![i])
                              : const SizedBox(),
                        ),
                      ),
                      if ((c.userProfileApiModel?.upcomingTrips?.length ?? 0) > 1) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            (c.userProfileApiModel!.upcomingTrips!.length < 3
                                ? c.userProfileApiModel!.upcomingTrips!.length
                                : 3),
                            (i) => Obx(
                              () => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: c.currentIndex == i ? 16 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: c.currentIndex == i
                                      ? ccPrimary
                                      : ccInputBorder,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ccSurface,
                            borderRadius: BorderRadius.circular(CCRadius.card),
                            boxShadow: CCShadow.card,
                          ),
                          child: Text(
                            "No upcoming trips yet",
                            style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                          ),
                        ),
                      ),

                    // ── Bio ────────────────────────────────────────────
                    if (c.userProfileApiModel?.userInfo?.bio?.isNotEmpty == true) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const _SectionHeader(title: "About", showAction: false),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ccSurface,
                            borderRadius: BorderRadius.circular(CCRadius.card),
                            boxShadow: CCShadow.card,
                          ),
                          child: Text(
                            c.userProfileApiModel!.userInfo!.bio!,
                            style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                          ),
                        ),
                      ),
                    ],

                    // ── Reviews ────────────────────────────────────────
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _SectionHeader(
                        title: "Reviews",
                        showAction:
                            (c.userProfileApiModel?.reviews?.length ?? 0) > 3,
                        onAction: c.viewAllReviewBottomsheet,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (c.userProfileApiModel?.reviews?.isNotEmpty == true)
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount:
                            c.userProfileApiModel!.reviews!.length < 3
                                ? c.userProfileApiModel!.reviews!.length
                                : 3,
                        itemBuilder: (ctx, i) => i < 3
                            ? c.reviewData(
                                review: c.userProfileApiModel!.reviews![i])
                            : const SizedBox(),
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ccSurface,
                            borderRadius: BorderRadius.circular(CCRadius.card),
                            boxShadow: CCShadow.card,
                          ),
                          child: Text(
                            "No reviews yet",
                            style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.showAction,
    this.onAction,
  });
  final String title;
  final bool showAction;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: CCText.titleMd),
        if (showAction && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text("View all",
                style: CCText.labelSm.copyWith(color: ccPrimary)),
          ),
      ],
    );
  }
}
