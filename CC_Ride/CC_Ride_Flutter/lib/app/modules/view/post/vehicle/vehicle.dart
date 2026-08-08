// ignore_for_file: deprecated_member_use

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/modules/controllers/post_controllers/vehicles_screen_controller.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class Vehicle extends GetView<VehiclesScreenController> {
  const Vehicle({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VehiclesScreenController>();
    return controller.dataGetApiModel!.vehicleData!.isEmpty
        ? InkWell(
            onTap: () {
              Get.toNamed(Routes.ADD_VEHICLE_SCREEN);
            },
            borderRadius: BorderRadius.circular(CCRadius.card),
            child: Container(
              width: Get.width,
              height: 130,
              decoration: BoxDecoration(
                border: Border.all(color: ccInputBorder),
                borderRadius: BorderRadius.circular(CCRadius.card),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 30, color: ccSecondaryText),
                  const SizedBox(height: 10),
                  Text(
                    'Add Vehicle'.tr,
                    style: const TextStyle(
                      color: ccSecondaryText,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Obx(
            () => Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Car Information',
                  style: TextStyle(
                    color: ccNavyText,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        Get.toNamed(Routes.ADD_VEHICLE_SCREEN);
                      },
                      borderRadius: BorderRadius.circular(CCRadius.card),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: ccInputBorder),
                          borderRadius: BorderRadius.circular(CCRadius.card),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 24,
                          color: ccSecondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (controller
                                .dataGetApiModel!.vehicleData!.isNotEmpty)
                              for (int i = 0;
                                  i <
                                      controller
                                          .dataGetApiModel!.vehicleData!.length;
                                  i++) ...[
                                Obx(
                                  () => GestureDetector(
                                    onTap: () {
                                      controller.postTripController.vehicleId =
                                          '${controller.dataGetApiModel!.vehicleData![i].id}';
                                      controller.selectedIndex = i;
                                      controller.update();
                                    },
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        border: controller.selectedIndex == i
                                            ? Border.all(
                                                color: ccPrimary, width: 2.5)
                                            : Border.all(color: ccInputBorder),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                              '${Confing.imageurl}${controller.dataGetApiModel!.vehicleData![i].photo}'),
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                            CCRadius.card),
                                      ),
                                    ),
                                  ),
                                ),
                                if (i !=
                                    controller.dataGetApiModel!.vehicleData!
                                            .length -
                                        1) ...[
                                  const SizedBox(width: 5)
                                ],
                              ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(CCRadius.card)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(CCRadius.card),
                      child: FadeInImage.assetNetwork(
                        placeholder: 'assets/image/ezgif.com-crop.gif',
                        image:
                            '${Confing.imageurl}${controller.dataGetApiModel!.vehicleData![controller.selectedIndex].photo}',
                        fit: BoxFit.cover,
                        imageErrorBuilder: (context, error, stackTrace) =>
                            Image.asset('assets/image/ezgif.com-crop.gif',
                                fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    controller
                        .dataGetApiModel!
                        .vehicleData![controller.selectedIndex]
                        .typeTitle!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      color: ccSecondaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    controller
                        .dataGetApiModel!
                        .vehicleData![controller.selectedIndex]
                        .modelTitle!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: ccNavyText,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      for (int i = 0; i < 2; i++) ...[
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                i == 0
                                    ? 'assets/image/svg/car.svg'
                                    : 'assets/image/svg/card.svg',
                                color: ccSecondaryText,
                                height: 18,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  i == 0
                                      ? '${controller.dataGetApiModel!.vehicleData![controller.selectedIndex].year} ${controller.dataGetApiModel!.vehicleData![controller.selectedIndex].colorTitle}'
                                      : '${controller.dataGetApiModel!.vehicleData![controller.selectedIndex].licensePlate}',
                                  style: const TextStyle(
                                    color: ccNavyText,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i == 0)
                          Container(
                            height: 25,
                            width: 1,
                            color: ccInputBorder,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}
