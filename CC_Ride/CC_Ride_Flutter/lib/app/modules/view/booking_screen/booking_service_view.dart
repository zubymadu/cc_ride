import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/booking_controllers/booking_service_controller.dart';

class BookingServiceView extends GetView<BookingServiceController> {
  const BookingServiceView({super.key});

  @override
  Widget build(BuildContext context) {
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
          "Before You Book",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ccNavyText,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: ccInputBorder),
        ),
      ),
      bottomNavigationBar: Container(
        color: ccSurface,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: CCButton(
          label: "I Understand, Continue",
          onPressed: () => Get.toNamed(Routes.BOOK_DETAILS),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ccIceBlue,
                borderRadius: BorderRadius.circular(CCRadius.card),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: ccPrimary,
                      borderRadius: BorderRadius.circular(CCRadius.btn),
                    ),
                    child: const Icon(Icons.info_outline_rounded,
                        color: ccSurface, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Ride Guidelines",
                            style: CCText.titleMd),
                        const SizedBox(height: 4),
                        Text(
                          "Please review these guidelines before confirming your booking.",
                          style: CCText.bodyMd.copyWith(
                              color: ccSecondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Guidelines list
            GetBuilder<BookingServiceController>(
              builder: (c) => ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: c.text.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ccSurface,
                      borderRadius: BorderRadius.circular(CCRadius.card),
                      boxShadow: CCShadow.card,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: ccIceBlue,
                            borderRadius:
                                BorderRadius.circular(CCRadius.btn),
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(CCRadius.btn),
                            child: Image.asset(
                              "${c.image[index]}",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${c.text[index]}".tr,
                                style: CCText.titleMd,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${c.det[index]}".tr,
                                style: CCText.bodyMd
                                    .copyWith(color: ccSecondaryText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
