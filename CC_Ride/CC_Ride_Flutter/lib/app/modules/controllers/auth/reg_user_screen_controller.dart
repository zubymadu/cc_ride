import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:carride/app/data/auth_firebase.dart';
import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/main.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class RegUserScreenController extends GetxController {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final RxString _ccode = "".obs;
  String get ccode => _ccode.value;
  set ccode(String value) => _ccode.value = value;

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  final formKey = GlobalKey<FormState>();

  final RxBool _showPassword = true.obs;
  bool get showPassword => _showPassword.value;
  set showPassword(bool value) => _showPassword.value = value;

  final RxInt _step = 0.obs;
  int get step => _step.value;
  set step(int value) => _step.value = value;
 
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      showToastMessage("Please enter your email".tr);
      return 'Please enter your email'.tr;
    }

    // Regular expression for email validation
    String pattern = r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
    RegExp regex = RegExp(pattern);

    if (!regex.hasMatch(value)) {
      showToastMessage("Enter a valid email address".tr);
      return 'Enter a valid email address'.tr;
    }
    return null; // valid
  }

  DateTime? bdatePicker;

  updatebdate(DateTime date) {
    bdatePicker = date;
    update();
  }

  FirebaseAuthService authService = Get.put(FirebaseAuthService());

  Future<Map<String, dynamic>> registerApi({
    required String name,
    required String email,
    required String mobile,
    required String ccode,
    required String password,
    required String refercode,
    required String age,
    required String dob,
    required String bio,
    required List<String> videoPaths,
    required String isMobileVerify,
  }) async {
    try {
      String url = Confing.baseurl + Confing.regUser;
      var request = http.MultipartRequest('POST', Uri.parse(url));

      request.fields.addAll({
        "name": name,
        "email": email,
        "mobile": mobile,
        "ccode": ccode,
        "password": password,
        "refercode": refercode,
        "age": age,
        "dob": dob,
        "bio": bio,
        "is_mobile_verify" : isMobileVerify,
      });

      // Add videos
      for (var videoPath in videoPaths) {
        final videoFile = File(videoPath);
        if (await videoFile.exists()) {
          debugPrint('Adding file: $videoPath');
          request.files.add(await http.MultipartFile.fromPath('photo', videoPath));
        } else {
          debugPrint('Video file does not exist: $videoPath');
        }
      }

      http.StreamedResponse response = await request.send()
          .timeout(const Duration(seconds: 30));
      final responseString = await response.stream.bytesToString()
          .timeout(const Duration(seconds: 30));

      log(name: "============== reg user api url ===============", url);
      log(name: "============== reg user api body ==============", "${request.fields}");
      log(name: "============ reg user api response ============", responseString);

      if (response.statusCode == 200) {
        var responseData = jsonDecode(responseString);

        if (responseData["UserLogin"] == null) {
          showToastMessage(responseData["ResponseMsg"] ?? "Registration failed. Please try again.");
          return {"success": false, "message": responseData["ResponseMsg"] ?? "Registration failed.", "data": null};
        }

        // Save user data locally
        save("userLogin", responseData["UserLogin"]);
        save("isUserLogin", true);
        // Without this, every authenticated endpoint (almost everything
        // past registration) would 401 until the user explicitly logged
        // out and back in — legacyRegUser returns a token exactly like
        // legacyLogin does, it just wasn't being persisted here.
        save("token", responseData["token"] ?? "");
        initPlatformState(key: Confing.oneSignalKey, loginId: "${responseData["UserLogin"]["id"]}");

        showToastMessage("${responseData["ResponseMsg"]}");
        authService.firebaseStoreData(
          uid: "${responseData["UserLogin"]["id"]}",
          name: "${responseData["UserLogin"]["name"]}",
          email: "${responseData["UserLogin"]["email"]}",
          number: "${responseData["UserLogin"]["mobile"]}",
          proPicPath: "${responseData["UserLogin"]["profile_pic"]}",
        );

        Get.offAllNamed(Routes.BOTTOM_BAR_SCREEN);

        return {
          "success": true,
          "message": responseData["ResponseMsg"] ?? "Registration successful",
          "data": responseData,
        };
      } else {
        debugPrint('Failed with status: ${response.statusCode}, ${response.reasonPhrase}');
        showToastMessage("Registration failed. Please try again.");
        return {
          "success": false,
          "message": "Server error: ${response.reasonPhrase ?? "Unknown error"}",
          "data": null,
        };
      }
    } catch (e) {
      debugPrint('Error sending the request: $e');
      return {
        "success": false,
        "message": "Exception occurred: $e",
        "data": null,
      };
    }
  }

  // ------------------------------ image picke ----------------------------
  final RxList _selectImageTypeText = ["Gallery", "Camera"].obs;
  List get selectImageTypeText => _selectImageTypeText;
  set selectImageTypeText(List value) => _selectImageTypeText.value = value;

  final RxList<IconData> _selectImageTypeIcon = <IconData>[Icons.photo, Icons.camera].obs;
  List<IconData> get selectImageTypeIcon => _selectImageTypeIcon;
  set selectImageTypeIcon(List<IconData> value) => _selectImageTypeIcon.value = value;

  final ImagePicker picker = ImagePicker();

  final Rx<XFile?> _selectImage = Rx<XFile?>(null);
  XFile? get selectImage => _selectImage.value;
  set selectImage(XFile? value) => _selectImage.value = value;

  RxString base64Url = "".obs;

  Future<void> pickImage(ImageSource source) async {
    try {
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        selectImage = picked;
        // final bytes = await picked.readAsBytes();
        base64Url.value = base64Encode(await picked.readAsBytes());
        debugPrint("✔ Image Path: ${picked.path}");
        debugPrint("✔ Base64: ${base64Url.value}");
      } else {
        debugPrint("❌ No image selected");
      }
    } catch (e) {
      debugPrint("❌ Error picking image: ${e.toString()}");
    }
  }

  selectImageBottomsheet() {
    return Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: ccSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(CCRadius.sheet)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < selectImageTypeText.length; i++) ...[
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      i == 0
                          ? pickImage(ImageSource.gallery)
                          : pickImage(ImageSource.camera);
                      Get.back();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: ccPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        selectImageTypeIcon[i],
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    selectImageTypeText[i],
                    style: const TextStyle(
                      color: ccNavyText,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (i != selectImageTypeText.length - 1) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  height: 50,
                  width: 1,
                  color: ccInputBorder,
                ),
              ],
            ]
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
