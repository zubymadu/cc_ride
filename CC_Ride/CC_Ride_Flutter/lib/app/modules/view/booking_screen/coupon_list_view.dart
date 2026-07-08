// ignore_for_file: deprecated_member_use

import 'package:carride/app/data/confing.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../controllers/booking_controllers/coupon_list_controller.dart';

class CouponListView extends GetView<CouponListController> {
  const CouponListView({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CouponListController>();
    return Scaffold(
      backgroundColor: ccSurface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: ccSurface,
          elevation: 0,
          title: Text(
            'Coupon'.tr,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: ccNavyText,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
            onPressed: () => Get.back(),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(color: ccInputBorder, height: 1),
          ),
        ),
      ),
      body: Obx(() => controller.isLoading
          ? const Center(child: CircularProgressIndicator(color: ccPrimary))
          : controller.couponListApiModel!.couponlist!.isNotEmpty
              ? ListView.separated(
                  itemCount: controller.couponListApiModel!.couponlist!.length,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final coupon =
                        controller.couponListApiModel!.couponlist![index];
                    return Container(
                      decoration: BoxDecoration(
                        color: ccSurface,
                        border: Border.all(color: ccInputBorder),
                        borderRadius: BorderRadius.circular(CCRadius.card),
                        boxShadow: CCShadow.card,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${coupon.couponTitle}',
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 18,
                              color: ccNavyText,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${coupon.couponSubtitle}',
                            style: const TextStyle(
                              color: ccSecondaryText,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 10),
                                    controller.couponText(
                                        title: 'Coupon Code'.tr,
                                        subtitle: '${coupon.couponCode}'),
                                    const SizedBox(height: 3),
                                    controller.couponText(
                                        title: 'Coupon Amount'.tr,
                                        subtitle:
                                            '$currency${coupon.couponVal}'),
                                    const SizedBox(height: 3),
                                    controller.couponText(
                                        title: 'Minimum Amount'.tr,
                                        subtitle: '$currency${coupon.minAmt}',
                                        subTextColor: ccNavyText),
                                    const SizedBox(height: 3),
                                    controller.couponText(
                                      title: 'Ex Date'.tr,
                                      subtitle: coupon.expireDate
                                          .toString()
                                          .split(' ')
                                          .first,
                                      subTextColor: ccNavyText,
                                    ),
                                    const SizedBox(height: 10),
                                    InkWell(
                                      onTap: () {
                                        if (controller.cartTotalAmount >=
                                            double.parse('${coupon.minAmt}')) {
                                          if (controller.bookPricingController
                                                  .couponCode ==
                                              '${coupon.couponCode}') {
                                            controller.bookPricingController
                                                    .totalAmount =
                                                controller.bookPricingController
                                                        .totalAmount +
                                                    controller
                                                        .bookPricingController
                                                        .couponAmount;
                                            controller.bookPricingController
                                                .couponCode = '';
                                            controller.bookPricingController
                                                .couponAmount = 0;
                                          } else {
                                            controller.isCouponCheckLoading[
                                                index] = true;
                                            controller
                                                .couponCheckApi(
                                                    cid: int.parse(
                                                        '${coupon.id}'))
                                                .then((value) {
                                              if (value['Result'] == 'true') {
                                                if (controller
                                                    .bookPricingController
                                                    .couponCode
                                                    .isNotEmpty) {
                                                  controller
                                                          .bookPricingController
                                                          .totalAmount =
                                                      controller
                                                              .bookPricingController
                                                              .totalAmount +
                                                          controller
                                                              .bookPricingController
                                                              .couponAmount;
                                                  controller
                                                          .bookPricingController
                                                          .couponCode =
                                                      '${coupon.couponCode}';
                                                  controller
                                                          .bookPricingController
                                                          .couponAmount =
                                                      double.parse(
                                                          '${coupon.couponVal}');
                                                  controller
                                                          .bookPricingController
                                                          .totalAmount =
                                                      controller
                                                              .bookPricingController
                                                              .totalAmount -
                                                          controller
                                                              .bookPricingController
                                                              .couponAmount;
                                                } else {
                                                  controller
                                                          .bookPricingController
                                                          .couponCode =
                                                      '${coupon.couponCode}';
                                                  controller
                                                          .bookPricingController
                                                          .couponAmount =
                                                      double.parse(
                                                          '${coupon.couponVal}');
                                                  controller
                                                          .bookPricingController
                                                          .totalAmount =
                                                      controller
                                                              .bookPricingController
                                                              .totalAmount -
                                                          controller
                                                              .bookPricingController
                                                              .couponAmount;
                                                }
                                                Get.back();
                                                controller.isCouponCheckLoading[
                                                    index] = false;
                                              }
                                            });
                                          }
                                        } else {
                                          showToastMessage(
                                              'Coupon amount is too large compared to total amount'
                                                  .tr);
                                        }
                                      },
                                      child: Obx(() {
                                        final isEligible =
                                            controller.cartTotalAmount >=
                                                double.parse(
                                                    coupon.minAmt.toString());
                                        final isApplied = controller
                                                .bookPricingController
                                                .couponCode ==
                                            '${coupon.couponCode}';
                                        return Container(
                                          height: 35,
                                          width: 150,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            border: Border.all(
                                                color: isEligible
                                                    ? ccPrimary
                                                    : ccSecondaryText),
                                            color: isApplied
                                                ? ccPrimary
                                                : ccSurface,
                                          ),
                                          child:
                                              controller.isCouponCheckLoading[
                                                      index]
                                                  ? LoadingAnimationWidget
                                                      .staggeredDotsWave(
                                                          color: ccPrimary,
                                                          size: 25)
                                                  : Text(
                                                      isApplied
                                                          ? 'Remove'.tr
                                                          : 'Apply coupons'.tr,
                                                      style: TextStyle(
                                                        color: isEligible
                                                            ? isApplied
                                                                ? Colors.white
                                                                : ccPrimary
                                                            : ccSecondaryText,
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 150,
                                width: Get.width / 3,
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(CCRadius.card),
                                  child: FadeInImage.assetNetwork(
                                    height: 150,
                                    width: Get.width / 3,
                                    placeholder:
                                        'assets/image/ezgif.com-crop.gif',
                                    placeholderFit: BoxFit.cover,
                                    placeholderCacheWidth: 100,
                                    placeholderCacheHeight: 150,
                                    image:
                                        '${Confing.imageurl}${coupon.couponImg}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: 10),
                )
              : Center(
                  child: SizedBox(
                    width: Get.width / 1.5,
                    child: Text(
                      'The Coupon is unavailable in your Service.'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: ccNavyText,
                      ),
                    ),
                  ),
                )),
    );
  }
}
