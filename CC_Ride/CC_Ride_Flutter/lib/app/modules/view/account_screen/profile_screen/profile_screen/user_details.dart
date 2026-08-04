import 'package:carride/app/data/confing.dart';
import 'package:carride/app/modules/controllers/account_controllers/profile_controllers/profile_screen_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserDetails extends GetView<ProfileScreenController> {
  const UserDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final info = controller.userProfileApiModel?.userInfo;
    if (info == null) return const SizedBox.shrink();

    final hasPic = info.profilePic != null && info.profilePic!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF001B3D), ccPrimary],
        ),
        borderRadius: BorderRadius.circular(CCRadius.card),
        boxShadow: CCShadow.card,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(CCRadius.btn),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 2),
                  color: Colors.white.withOpacity(0.1),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasPic
                    ? FadeInImage.assetNetwork(
                        placeholder: "assets/image/ezgif.com-crop.gif",
                        image:
                            "${Confing.imageurl}${info.profilePic}",
                        fit: BoxFit.cover,
                        imageErrorBuilder: (_, __, ___) => Image.asset(
                          "assets/image/ezgif.com-crop.gif",
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          info.name != null && info.name!.isNotEmpty
                              ? info.name![0].toUpperCase()
                              : "?",
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${info.name}",
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (info.isMobileVerify == "1" ||
                        info.isEmailVerify == "1") ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded,
                                color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              "Verified",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      "${info.joined}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${info.dob}",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Rating row
          if (controller.userProfileApiModel?.stats != null) ...[
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.15),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(
                    label: "Rating",
                    value: "${controller.userProfileApiModel?.stats?.avgRating?.toStringAsFixed(1) ?? '0.0'}",
                    icon: Icons.star_rounded),
                _Stat(
                    label: "Trips",
                    value: "${controller.userProfileApiModel?.stats?.ridesTaken ?? 0}",
                    icon: Icons.directions_car_rounded),
                _Stat(
                    label: "Reviews",
                    value:
                        "${controller.userProfileApiModel?.reviews?.length ?? 0}",
                    icon: Icons.rate_review_rounded),
              ],
            ),
          ],

          // Edit button
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Get.toNamed(Routes.PERSONAL_DETAILS),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(CCRadius.btn),
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    "Edit Profile",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
