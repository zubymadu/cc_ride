// ignore_for_file: deprecated_member_use

import 'package:carride/utils/cc_ds.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/trip_request_controllers/post_req_preiview_screen_controller.dart';

class PostReqPreiviewScreenView
    extends GetView<PostReqPreiviewScreenController> {
  const PostReqPreiviewScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments ?? {};
    final c = Get.find<PostReqPreiviewScreenController>();
    return Scaffold(
      backgroundColor: ccBackground,
      appBar: AppBar(
        backgroundColor: ccSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ccNavyText),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Trip Request',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ccNavyText,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: ccInputBorder),
        ),
        actions: [
          if (getData.read('userLogin') != null &&
              '${getData.read('userLogin')['id']}' ==
                  '${args['userId']}')
            Container(
              height: 40,
              width: 40,
              margin: const EdgeInsets.only(right: 10),
              decoration: const BoxDecoration(
                color: ccIceBlue,
                shape: BoxShape.circle,
              ),
              child: PopupMenuButton<String>(
                icon: SvgPicture.asset(
                  'assets/image/svg/More.svg',
                  color: ccNavyText,
                ),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'Edit') {
                    Get.toNamed(Routes.POST_REQUEST_SCREEN,
                        arguments: args);
                  } else if (value == 'Delete') {
                    c.showDeleteConfirmDialog();
                  }
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(CCRadius.card)),
                color: ccSurface,
                shadowColor: Colors.transparent,
                itemBuilder: (context) => [
                  for (int i = 0; i < c.menu.length; i++)
                    PopupMenuItem(
                      value: c.menu[i],
                      child: Text(
                        '${c.menu[i]}',
                        style: TextStyle(
                          color: i == 1 ? ccError : ccNavyText,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (getData.read('userLogin') != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: args['findTrip'] != null
                  ? args['isInvited'] == '1'
                      ? const SizedBox()
                      : SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              if (getData.read('userLogin')[
                                          'is_mobile_verify'] ==
                                      '1' &&
                                  getData.read('userLogin')[
                                          'is_email_verify'] ==
                                      '1') {
                                Get.toNamed(
                                  Routes.MULTIPOLYLINE_MAP_SCREEN,
                                  arguments: {
                                    'request_id':
                                        '${args['requestId']}',
                                    'origin_address':
                                        '${args['fromAddress']}',
                                    'origin_lat': '${args['fromLat']}',
                                    'origin_long':
                                        '${args['fromLong']}',
                                    'desti_address':
                                        '${args['toAddress']}',
                                    'desti_lat': '${args['toLat']}',
                                    'desti_long': '${args['toLong']}',
                                    'start_date': args['departureDate'],
                                    'total_seat':
                                        '${args['seatRequire']}',
                                  },
                                );
                              } else {
                                Get.toNamed(Routes.PROFILE_SCREEN);
                                showToastMessage(
                                    'Mobile and email verification is not completed.');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ccPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      CCRadius.btn)),
                            ),
                            child: Text(
                              'Invite ${args['userTitle']} to join a trip',
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.white),
                            ),
                          ),
                        )
                  : c.findTripController.tripIsLoading
                      ? const SizedBox()
                      : SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              if (!c.findTripController.tripIsLoading) {
                                if ('${c.findTripController.findTripsmodel!.result}' ==
                                    'false') {
                                  Get.back();
                                } else {
                                  c.tripListBottmsheet();
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  '${c.findTripController.findTripsmodel!.result}' ==
                                          'false'
                                      ? ccSecondaryText
                                      : ccPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      CCRadius.btn)),
                            ),
                            child: Text(
                              '${c.findTripController.findTripsmodel!.result}' ==
                                      'false'
                                  ? 'No matches yet'.tr
                                  : '${'View'.tr} ${c.findTripController.findTripsmodel!.data!.tripData!.length} ${'matches'.tr}',
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.white),
                            ),
                          ),
                        ),
            ),
        ],
      ),
      body: GetBuilder<PostReqPreiviewScreenController>(
        init: PostReqPreiviewScreenController(),
        initState: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.arguments['findTrip'] == null) {
              c.findTripController.tripIsLoading = true;
              c.update();
              c.findTripController.findtripApi(
                originLat: '${Get.arguments['fromLat']}',
                originLong: '${Get.arguments['fromLong']}',
                destinationLat: '${Get.arguments['toLat']}',
                destinationLong: '${Get.arguments['toLong']}',
                tripDate: Get.arguments['departureDate']
                    .toString()
                    .split(' ')
                    .first,
                status: 'Trip',
              ).then((value) {
                c.findTripController.tripIsLoading = false;
                c.update();
              });
            }
            if (Get.arguments['tripInfo'] != null) {
              c.tripInfo.addAll(Get.arguments['tripInfo']);
              final startDateTime =
                  DateTime.parse('${Get.arguments['departureDate']}');
              final distanceKm = c.calculateDistance(
                lat1: double.parse('${Get.arguments['fromLat']}'),
                lon1: double.parse('${Get.arguments['fromLong']}'),
                lat2: double.parse('${Get.arguments['toLat']}'),
                lon2: double.parse('${Get.arguments['toLong']}'),
              );
              final totalMinutes = (distanceKm / 15 * 60).toInt();
              final endDateTime =
                  startDateTime.add(Duration(minutes: totalMinutes));
              c.tripEndTime.value =
                  DateFormat('EEEE, d MMMM, yyy').format(endDateTime);
            }
          });
        },
        builder: (_) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: Get.width,
                  decoration: BoxDecoration(
                    color: ccSurface,
                    borderRadius:
                        BorderRadius.circular(CCRadius.card),
                    boxShadow: CCShadow.card,
                  ),
                  child: Column(
                    children: [
                      c.findRequestDetailsData(
                        onTap: () {},
                        date: DateFormat('EEEE, d MMMM, yyy').format(
                            DateTime.parse(
                                '${args['departureDate']}')),
                        address: [
                          args['fromAddress'].split(',').first,
                          args['toAddress'].split(',').first,
                        ],
                        profilePic: '${args['userProfile']}',
                        totalSeat: args['seatRequire'],
                        profileName: '${args['userTitle']}',
                        totalRate: '${args['avgRating']}',
                        ridesTaken: '${args['ridesTaken']}',
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/image/svg/chat-dots.svg',
                              color: ccSecondaryText,
                              height: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${args['requestDescription']}',
                                style: const TextStyle(
                                  color: ccSecondaryText,
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (c.tripInfo.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Trip Invitations',
                    style: TextStyle(
                      color: ccNavyText,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    itemCount: c.tripInfo.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return c.findTripDetailsData(
                        onTap: () {
                          Get.toNamed(
                            Routes.TRIP_PREVIEW_SCREEN,
                            arguments: {
                              'tripId':
                                  '${c.tripInfo[index].tripId}',
                              'findtrip': true,
                              'requestId':
                                  '${args['requestId']}',
                            },
                          );
                        },
                        date: [
                          DateFormat('EEEE, d MMMM, yyy').format(
                              DateTime.parse(
                                  '${args['departureDate']}')),
                          '',
                        ],
                        addresstype: [
                          'Pickup point',
                          'Destination'
                        ],
                        address: [
                          c.tripInfo[index].origin!
                              .split(', ')
                              .first,
                          c.tripInfo[index].destination!
                              .split(', ')
                              .first,
                        ],
                        profilePic:
                            c.tripInfo[index].profilePic!,
                        seatPrice:
                            c.tripInfo[index].seatPrice!,
                        totalSeat:
                            c.tripInfo[index].totalSeat!,
                        profileName:
                            c.tripInfo[index].userName!,
                        tripIsReturn: '0',
                        totalRate:
                            '${c.tripInfo[index].avgRating!}',
                        totalDriven: c.tripInfo[index].kmShared!
                            .toStringAsFixed(2),
                      );
                    },
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
