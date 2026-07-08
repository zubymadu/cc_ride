import 'package:carride/app/modules/controllers/account_controllers/account_screen_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

logOutAndDeleteAccountBottomsheet({
  required String title,
  required String subtitle,
  required String buttonText,
  required VoidCallback onTap,
}) {
  AccountScreenController accountScreenController = Get.put(
    AccountScreenController(),
  );
  return Get.bottomSheet(
    Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 20, fontFamily: 'Inter', fontWeight: FontWeight.w700, color: ccNavyText),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: ccInputBorder),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: ccSecondaryText,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ccNavyText,
                    side: const BorderSide(color: ccInputBorder),
                    shape: const StadiumBorder(),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text("Cancel".tr),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(
                  () => accountScreenController.deleteAccountLoder
                      ? const SizedBox(
                          height: 52,
                          child: Center(child: CircularProgressIndicator(color: ccPrimary)),
                        )
                      : ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ccPrimary,
                            foregroundColor: ccSurface,
                            shape: const StadiumBorder(),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: Text(buttonText),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(CCRadius.sheet)),
    ),
    backgroundColor: ccBackground,
  );
}
