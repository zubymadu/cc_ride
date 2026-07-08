import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/post_controllers/trip_preview_screen_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MeetYourCarpoolCrew extends GetView<TripPreviewScreenController> {
  const MeetYourCarpoolCrew({super.key});

  @override
  Widget build(BuildContext context) {
    final users =
        controller.tripDetailsApiModel!.tripData!.bookedUsers ?? [];
    return Container(
      width: Get.width,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: ccSurface,
        borderRadius: BorderRadius.circular(CCRadius.card),
        boxShadow: CCShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: const Text(
                    'Meet your fellow passengers',
                    style: TextStyle(
                      color: ccNavyText,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: ccSuccessLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${users.length}',
                    style: const TextStyle(
                      color: ccSuccess,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (int i = 0; i < users.length; i++) ...[
                  InkWell(
                    onTap: () {
                      if ('${controller.tripDetailsApiModel!.tripData!.userId}' ==
                          '${getData.read('userLogin')['id']}') {
                        if ('${users[i].bookStatus}' != 'Completed') {
                          controller.seatingPlanScreenController
                              .bookedUsersBottomSheet(ind: i)
                              .then((_) => controller.update());
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(CCRadius.card),
                    child: SizedBox(
                      width: 80,
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: ccIceBlue,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: FadeInImage.assetNetwork(
                              placeholder:
                                  'assets/image/ezgif.com-crop.gif',
                              image:
                                  '${Confing.imageurl}${users[i].profilePic}',
                              fit: BoxFit.cover,
                              imageErrorBuilder:
                                  (context, error, stackTrace) =>
                                      Image.asset(
                                          'assets/image/ezgif.com-crop.gif',
                                          fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${users[i].userName}',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ccNavyText,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${users[i].bookStatus}',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: const TextStyle(
                              color: ccSecondaryText,
                              fontFamily: 'Inter',
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (i != users.length - 1)
                    const SizedBox(width: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
