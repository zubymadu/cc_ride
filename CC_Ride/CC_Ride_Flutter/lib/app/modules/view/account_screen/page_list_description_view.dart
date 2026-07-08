import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import 'package:get/get.dart';

import '../../controllers/account_controllers/page_list_description_controller.dart';

class PageListDescriptionView extends GetView<PageListDescriptionController> {
  const PageListDescriptionView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ccBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: ccSurface,
          elevation: 0,
          centerTitle: true,
          title: Text(
            Get.arguments["title"],
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HtmlWidget(
              onLoadingBuilder: (context, element, loadingProgress) {
                return SizedBox(
                  height: Get.height / 1.2,
                  width: Get.width,
                  child: const Center(
                      child: CircularProgressIndicator(color: ccPrimary)),
                );
              },
              Get.arguments["description"],
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                color: ccNavyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
