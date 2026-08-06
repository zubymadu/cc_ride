import 'package:accordion/accordion.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/help_controller/help_screen_controller.dart';
import '../../../routes/app_pages.dart';

class HelpScreenView extends GetView<HelpScreenController> {
  const HelpScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HelpScreenController>();
    // faqListApi() otherwise only ever fires once, at app boot, from inside
    // BottomBarScreenController.onInit() — competing with several other
    // cold-start network calls (mode prompt, location, etc). If that single
    // fire-and-forget attempt fails for any transient reason there's no
    // retry, so Help stays empty for the rest of the session. Refetch
    // whenever this screen is actually opened instead of trusting that one
    // early call succeeded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.faqListApi();
    });
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
          "Help & FAQ",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ccNavyText,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: ccInputBorder),
        ),
      ),
      body: Obx(
        () => c.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ccPrimary))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Didn't find an answer above? Raise a ticket instead of
                    // leaving the rider stuck with a static FAQ list.
                    GestureDetector(
                      onTap: () => Get.toNamed(Routes.SUPPORT_TICKETS),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ccPrimary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(CCRadius.card),
                          border: Border.all(color: ccPrimary.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.support_agent_rounded, color: ccPrimary),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Still need help?",
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: ccNavyText)),
                                  Text("Raise a support ticket and our team will respond",
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: ccSecondaryText)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: ccSecondaryText),
                          ],
                        ),
                      ),
                    ),
                    Accordion(
                  disableScrolling: true,
                  flipRightIconIfOpen: true,
                  rightIcon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: ccSecondaryText,
                    size: 22,
                  ),
                  contentBorderColor: ccInputBorder,
                  contentBorderWidth: 1,
                  headerBorderColor: ccInputBorder,
                  headerBorderWidth: 1,
                  headerBorderColorOpened: ccPrimary,
                  headerBackgroundColor: ccSurface,
                  contentBackgroundColor: ccBackground,
                  headerPadding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                  children: [
                    for (var i = 0;
                        i <
                            (c.faqListApiModel?.faqData?.length ?? 0);
                        i++)
                      AccordionSection(
                        header: Text(
                          "${c.faqListApiModel!.faqData![i].question}",
                          style: CCText.titleMd,
                        ),
                        content: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            "${c.faqListApiModel!.faqData![i].answer}",
                            style: CCText.bodyLg
                                .copyWith(color: ccSecondaryText),
                          ),
                        ),
                      ),
                  ],
                ),
                  ],
                ),
              ),
      ),
    );
  }
}
