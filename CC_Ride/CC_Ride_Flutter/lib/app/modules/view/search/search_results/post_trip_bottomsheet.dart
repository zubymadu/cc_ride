// ignore_for_file: deprecated_member_use

import 'package:carousel_slider/carousel_slider.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/post_controllers/post_screen_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

postTripBottomsheet() {
  final List<String> title = ["I'm driving".tr, 'I need a ride'.tr];

  final PostScreenController postScreenController =
      Get.put(PostScreenController());

  return Get.bottomSheet(
    backgroundColor: ccSurface,
    isScrollControlled: true,
    enableDrag: false,
    isDismissible: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CCRadius.sheet)),
    ),
    GetBuilder<PostScreenController>(
      init: PostScreenController(),
      initState: (_) {
        postScreenController.currentIndex = 0;
        postScreenController.update();
      },
      builder: (c) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(maxHeight: Get.height / 1.2),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Heading Somewhere?'.tr,
                      textAlign: TextAlign.center,
                      style: CCText.headlineMd,
                    ),
                  ),
                  InkWell(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: ccIceBlue,
                      ),
                      child: const Icon(Icons.close,
                          color: ccNavyText, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: double.infinity,
                    viewportFraction: 1.0,
                    enlargeCenterPage: false,
                    scrollDirection: Axis.horizontal,
                    autoPlay: true,
                    clipBehavior: Clip.none,
                    onPageChanged: (index, reason) {
                      c.currentIndex = index;
                      c.update();
                    },
                  ),
                  items: c.sliderImga
                      .map(
                        (item) => Center(
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(CCRadius.card),
                            child: Image.asset('$item'),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ccIceBlue,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (int i = 0;
                        i < c.sliderImga.length;
                        i++) ...[
                      Obx(
                        () => AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            shape: BoxShape.rectangle,
                            color: c.currentIndex == i
                                ? ccPrimary
                                : ccSecondaryText.withOpacity(0.3),
                          ),
                          curve: Curves.easeIn,
                          height: 8,
                          width: 8,
                        ),
                      ),
                      if (i != c.sliderImga.length - 1)
                        const SizedBox(width: 5),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${c.sliderTitle[c.currentIndex]}',
                style: CCText.titleMd,
              ),
              const SizedBox(height: 8),
              Text(
                '${c.sliderText[c.currentIndex]}',
                textAlign: TextAlign.center,
                style: CCText.bodyMd.copyWith(color: ccSecondaryText),
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < title.length; i++) ...[
                InkWell(
                  onTap: () {
                    Get.back();
                    if (getData.read('userLogin') != null) {
                      if (getData.read('userLogin')[
                                  'is_mobile_verify'] ==
                              '1' &&
                          getData.read('userLogin')[
                                  'is_email_verify'] ==
                              '1') {
                        if (i == 0) {
                          Get.toNamed(
                              Routes.MULTIPOLYLINE_MAP_SCREEN);
                        } else {
                          Get.toNamed(Routes.POST_REQUEST_SCREEN);
                        }
                      } else {
                        Get.toNamed(Routes.PROFILE_SCREEN);
                        showToastMessage(
                            'Mobile and email verification is not completed.');
                      }
                    } else {
                      Get.toNamed(Routes.LOGIN_SCREEN);
                    }
                  },
                  child: Container(
                    width: Get.width,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(CCRadius.btn),
                      color: i == 0
                          ? ccPrimary
                          : const Color(0xFF4A46E6),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            title[i],
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              Icons.arrow_forward_ios,
                              size: 15,
                              color: ccNavyText),
                        ),
                      ],
                    ),
                  ),
                ),
                if (i == 0) const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    ),
  );
}
