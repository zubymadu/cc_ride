import 'package:carride/app/modules/controllers/search_controllers/search_results_screen_controller.dart';
import 'package:carride/app/modules/view/search/search_results/post_trip_bottomsheet.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class SearchRequest extends GetView<SearchResultsScreenController> {
  const SearchRequest({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SearchResultsScreenController>();
    return GetBuilder<SearchResultsScreenController>(
      builder: (_) {
        if (c.findTripController.requestIsLoading) {
          return const Center(
              child: CircularProgressIndicator(color: ccPrimary));
        }
        if (c.findTripController.findRequestsmodel!.result == 'false') {
          return _emptyState();
        }
        return ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(10),
          itemCount: c.findTripController.findRequestsmodel!.data!
              .requestData!.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final reqs = c.findTripController.findRequestsmodel!
                .data!.requestData!;
            return c.findRequestDetailsData(
              onTap: () {
                Get.toNamed(
                  Routes.POST_REQ_PREIVIEW_SCREEN,
                  arguments: {
                    'requestId': '${reqs[index].requestId}',
                    'fromAddress': '${reqs[index].fromAddress}',
                    'fromLat': '${reqs[index].fromLat}',
                    'fromLong': '${reqs[index].fromLong}',
                    'toAddress': '${reqs[index].toAddress}',
                    'toLat': '${reqs[index].toLat}',
                    'toLong': '${reqs[index].toLong}',
                    'requestDescription':
                        '${reqs[index].requestDescription}',
                    'departureDate': '${reqs[index].departureDate}',
                    'seatRequire': '${reqs[index].seatRequire}',
                    'userProfile': '${reqs[index].userProfile}',
                    'userTitle': '${reqs[index].userTitle}',
                    'userId': '${reqs[index].userId}',
                    'isInvited': '${c.findTripController.findAllmodel!.data!.requestData![index].isInvited}',
                    'avgRating': '${c.findTripController.findAllmodel!.data!.requestData![index].avgRating}',
                    'ridesTaken': '${c.findTripController.findAllmodel!.data!.requestData![index].ridesTaken}',
                    'findTrip': true,
                  },
                );
              },
              date: DateFormat('EEEE, MMMM dd').format(
                  DateTime.parse(reqs[index]
                      .departureDate
                      .toString()
                      .split(' ')
                      .first)),
              address: [
                reqs[index].fromAddress!.split(',').first,
                reqs[index].toAddress!.split(',').first,
              ],
              profilePic: '${reqs[index].userProfile}',
              totalSeat: '${reqs[index].seatRequire}',
              profileName: '${reqs[index].userTitle}',
              totalRate: '${reqs[index].avgRating}',
              ridesTaken: '${reqs[index].ridesTaken}',
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 10),
        );
      },
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: ccIceBlue, shape: BoxShape.circle),
              child: const Icon(Icons.person_search_outlined,
                  color: ccPrimary, size: 36),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 280,
              child: Text(
                'Nothing to see here… yet!'.tr,
                style: CCText.bodyLg.copyWith(color: ccSecondaryText),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: postTripBottomsheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ccPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(CCRadius.btn)),
                ),
                child: const Text('Post a trip',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      );
}
