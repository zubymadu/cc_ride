import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/account_controllers/profile_controllers/profile_screen_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class PersonalDetailsController extends GetxController {
  ProfileScreenController profileScreenController = Get.put(ProfileScreenController());

  @override
  void onInit() {
    debugPrint("---------- User Data ---------- ${getData.read("userLogin")}");
    phoneController = TextEditingController(text: getData.read("userLogin")["mobile"]);
    emailController = TextEditingController(text: getData.read("userLogin")["email"]);
    nameController = TextEditingController(text: getData.read("userLogin")["name"]);
    dobController = TextEditingController(text: getData.read("userLogin")["dob"].toString().split(" ").first);
    bioController = TextEditingController(text: getData.read("userLogin")["bio"]);
    // passwordController = TextEditingController(text: getData.read("userLogin")["password"]);
    ccode = "${getData.read("userLogin")["ccode"]}";
    if (getData.read("userLogin")["is_driver"] != null) {
      isDriver = getData.read("userLogin")["is_driver"] == "0" || getData.read("userLogin")["is_driver"] == null ? false : true;
    }
    update();
    debugPrint("---------- phoneController ---------- ${phoneController.text}");
    debugPrint("---------- emailController ---------- ${emailController.text}");
    debugPrint("----------- nameController ---------- ${nameController.text}");
    debugPrint("----------- dobController ----------- ${dobController.text}");
    debugPrint("----------- bioController ----------- ${bioController.text}");
    debugPrint("--------------- ccode --------------- $ccode");
    debugPrint("------------- isDriver -------------- $isDriver");
    debugPrint("------------ is_driver -------------- ${getData.read("userLogin")["is_driver"]}");
    super.onInit();
  }

  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  final RxString _ccode = "".obs;
  String get ccode => _ccode.value;
  set ccode(String value) => _ccode.value = value;

  final RxBool _showPassword = true.obs;
  bool get showPassword => _showPassword.value;
  set showPassword(bool value) => _showPassword.value = value;

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  final RxBool _isDriver = false.obs;
  bool get isDriver => _isDriver.value;
  set isDriver(bool value) => _isDriver.value = value;

  Future<String?> selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(dobController.text),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ccPrimary,
              onPrimary: ccSurface,
              onSurface: ccNavyText,
            ),
            datePickerTheme: DatePickerThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: ccPrimary)),
            dialogTheme: DialogThemeData(backgroundColor: ccSurface),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      return "${picked.year}-${picked.month}-${picked.day}";
    }
    return null;
  }

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

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json"
  };

  Future updateProfile({
    required String name,
    required String email,
    required String phone,
    required String dob,
    required String bio,
    required String password,
    required bool isDriver,
  }) async {
    isLoading = true;
    update();
    Map body = {
      "uid": "${getData.read("userLogin")["id"]}",
      "name": name,
      "password": password,
      "email": email,
      "bio" : bio,
      "dob" : dob,
      "is_driver" : isDriver ? "1" : "0",
    };

    String url = Confing.baseurl + Confing.profileEdit;

    log(name: "============== Update Profile url =============", url);
    log(name: "============== Update Profile body ============", "$body");

    try {
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(name: "============= Update Profile respon ===========", response.body);
      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          save("userLogin", data["UserLogin"]);
          showToastMessage("${data["ResponseMsg"]}");
          profileScreenController.userProfileApi().then((value) {
            isLoading = false;
            update();
          });
          return data;
        } else {
          showToastMessage("${data["ResponseMsg"]}");
          isLoading = false;
          update();
          return data;
        }
      } else {
        showToastMessage("Something went wrong. Please try again.");
        isLoading = false;
        update();
      }
    } catch (e) {
      isLoading = false;
      update();
      log(name: "============= Update Profile Error ===========", "$e");
    }
  }

  Future updateProfileImage({required String img}) async {
    isLoading = true;
    update();
    Map body = {
      "uid": "${getData.read("userLogin")["id"]}",
      "img": img,
    };

    String url = Confing.baseurl + Confing.proImage;

    log(name: "============== Update Profile Image url =============", url);
    log(name: "============== Update Profile Image body ============", "$body");

    try {
      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(name: "============= Update Profile Image respon ===========", response.body);
      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          save("userLogin", data["UserLogin"]);
          showToastMessage("${data["ResponseMsg"]}");
          profileScreenController.userProfileApi().then((value) {
            isLoading = false;
            update();
          });
          return data;
        } else {
          showToastMessage("${data["ResponseMsg"]}");
          isLoading = false;
          update();
          return data;
        }
      } else {
        showToastMessage("Something went wrong. Please try again.");
        isLoading = false;
        update();
      }
    } catch (e) {
      isLoading = false;
      update();
      log(name: "============= Update Profile Image Error ===========", "$e");
    }
  }

  final ImagePicker picker = ImagePicker();

  final Rx<XFile?> _selectImage = Rx<XFile?>(null);
  XFile? get selectImage => _selectImage.value;
  set selectImage(XFile? value) => _selectImage.value = value;

  RxString base64Url = ''.obs;

  Future<void> pickImage(ImageSource source) async {
    try {
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        selectImage = picked;
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
    List selectImageTypeText = ["Gallery".tr, "Camera".tr];
    List selectImageTypeIcon = ["assets/image/svg/gallery.svg", "assets/image/svg/camera.svg"];
    return Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: ccSurface,
          borderRadius: BorderRadius.circular(20)
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: Get.width / 6,
              height: 5,
              decoration: BoxDecoration(
                color: ccSecondaryText.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            SizedBox(height: 15),
            Text(
              "Choose image",
              style: TextStyle(
                color: ccNavyText,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for(int i = 0; i < selectImageTypeText.length; i++)...[
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        i == 0 ? pickImage(ImageSource.gallery) : pickImage(ImageSource.camera);
                        Get.back();
                      },
                      child: Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: ccBackground,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SvgPicture.asset(
                              selectImageTypeIcon[i],
                              color: ccNavyText,
                            ),
                            SizedBox(height: 10),
                            Text(
                              selectImageTypeText[i],
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                color: ccNavyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if(i != selectImageTypeText.length - 1)...[
                    SizedBox(width: 10),
                  ],
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// {
//     "UserLogin": {
//         "id": "36",
//         "name": "Jay",
//         "mobile": "2222222222",
//         "password": "123",
//         "rdate": "2025-05-29 15:54:25",
//         "status": "1",
//         "ccode": "+91",
//         "wallet": "0",
//         "email": "Hay@gmail.com",
//         "profile_pic": "images/profile/68e9f2667e854.png",
//         "age": "22",
//         "dob": "2003-05-01",
//         "code": "589623",
//         "refercode": null,
//         "bio": "hi there ",
//         "is_driver": "0"
//     },
//     "ResponseCode": "200",
//     "Result": "true",
//     "ResponseMsg": "Profile Image Upload Successfully!!"
// }
