import 'package:accordion/accordion.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/help_controller/help_screen_controller.dart';

class HelpScreenView extends GetView<HelpScreenController> {
  const HelpScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HelpScreenController>();
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
                child: Accordion(
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
              ),
      ),
    );
  }
}
