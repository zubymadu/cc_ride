import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/account_controllers/language_screen_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageScreenView extends GetView<LanguageScreenController> {
  const LanguageScreenView({super.key});

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
        title: Text(
          'Language'.tr,
          style: const TextStyle(
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Suggested".tr,
              style: CCText.titleMd,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: controller.locale.length,
                physics: const BouncingScrollPhysics(),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(CCRadius.card),
                    onTap: () => controller
                        .updateLanguage(controller.locale[index]['locale']),
                    child: Obx(() {
                      final selected =
                          "${getData.read("lan2")}_${getData.read("lan1")}" ==
                              "${controller.locale[index]['locale']}";
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected ? ccIceBlue : ccSurface,
                          borderRadius: BorderRadius.circular(CCRadius.card),
                          border: Border.all(
                            color: selected ? ccPrimary : ccInputBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              controller.locale[index]["name"],
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color:
                                    selected ? ccPrimary : ccNavyText,
                              ),
                            ),
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: Radio(
                                value: true,
                                groupValue: selected,
                                hoverColor: Colors.transparent,
                                activeColor: ccPrimary,
                                onChanged: (value) => controller
                                    .updateLanguage(
                                        controller.locale[index]['locale']),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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
