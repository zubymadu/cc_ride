// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/controllers/account_controllers/profile_controllers/vehicle_controllers/vehicles_list_controller.dart';
import 'package:carride/app/modules/controllers/post_controllers/vehicles_screen_controller.dart';
import 'package:carride/app/modules/models/color_type_model_list_api_model.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AddVehicleScreenController extends GetxController {

  @override
  void onInit() {
    fetchData();
    debugPrint("------------ arguments ------------ ${Get.arguments}");
    if (Get.arguments != null) {
      if (Get.arguments["isedit"] != null) {
        carModelId = "${Get.arguments["modelId"]}";
        selectedtypeId = "${Get.arguments["typeId"]}";
        selectedColorId = "${Get.arguments["colorId"]}";
        selectedtype = "${Get.arguments["type"]}";
        selectedColor = "${Get.arguments["color"]}";
        modelListController.text = "${Get.arguments["model"]}";
        yearcontroller.text = "${Get.arguments["year"]}";
        licencecontroller.text = "${Get.arguments["licensePlate"]}";
        isEdit = Get.arguments["isedit"];
      }
    }
    update();
    super.onInit();
  }

  VehiclesScreenController vehiclesScreenController = Get.put(VehiclesScreenController());
  VehiclesListController vehiclesListController = Get.put(VehiclesListController());

  final formKey = GlobalKey<FormState>();

  void fetchData() async {
    isLoading = true;
    update();
    await colorTypeModelListApi();
    update();
  }

  TextEditingController modelListController = TextEditingController();
  TextEditingController yearcontroller = TextEditingController();
  TextEditingController licencecontroller = TextEditingController();

  final RxString _carModelId = "".obs;
  String get carModelId => _carModelId.value;
  set carModelId(String value) => _carModelId.value = value;

  final RxString _selectedColor = "".obs;
  String get selectedColor => _selectedColor.value;
  set selectedColor(String value) => _selectedColor.value = value;

  final RxString _selectedtype = "".obs;
  String get selectedtype => _selectedtype.value;
  set selectedtype(String value) => _selectedtype.value = value;

  final RxnString _selectedtypeId = RxnString();
  String? get selectedtypeId => _selectedtypeId.value;
  set selectedtypeId(String? value) => _selectedtypeId.value = value;

  final RxnString _selectedColorId = RxnString();
  String? get selectedColorId => _selectedColorId.value;
  set selectedColorId(String? value) => _selectedColorId.value = value;

  ColorTypeModelListApiModel? colorTypeModelListApiModel;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  final RxBool _isButtonLoading = false.obs;
  bool get isButtonLoading => _isButtonLoading.value;
  set isButtonLoading(bool value) => _isButtonLoading.value = value;

  final RxBool _isEdit = false.obs;
  bool get isEdit => _isEdit.value;
  set isEdit(bool value) => _isEdit.value = value;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
  };

  Future colorTypeModelListApi() async {
    isLoading = true;
    update();
    Map body = {"uid": "${getData.read("userLogin")["id"]}"};

    try {
      String url = Confing.baseurl + Confing.colorTypeModellist;

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(name: "============= Color Type Model List url ==============", url);
      log(name: "============= Color Type Model List body =============", "$body");
      log(name: "=========== Color Type Model List response ===========", response.body);

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          colorTypeModelListApiModel = colorTypeModelListApiModelFromJson(response.body);
          if (colorTypeModelListApiModel!.result == "true") {
            isLoading = false;
            update();
          } else {
            showToastMessage("${colorTypeModelListApiModel!.responseMsg}");
          }
          return data;
        } else {
          showToastMessage("${data["ResponseMsg"]}");
          return data;
        }
      } else {
        showToastMessage("Somthing went wrong!.....");
      }
    } catch (e) {
      log(name: "=========== Color Type Model List error ===========", "$e");
    }
  }

  Future<Map<String, dynamic>?> addVehicleApi({
    required String modelId,
    required String typeId,
    required String colorId,
    required String year,
    required String licensePlate,
    required String status,
    required String photo,
  }) async {
    try {
      var uri = Uri.parse(Confing.baseurl + Confing.addvehicle);
      var request = http.MultipartRequest('POST', uri);

      request.fields.addAll({
        "uid": "${getData.read("userLogin")["id"]}",
        "model_id": modelId,
        "type_id": typeId,
        "color_id": colorId,
        "year": year,
        "license_plate": licensePlate,
        "status": status,
      });

      debugPrint("===== Request Fields =====");
      request.fields.forEach((key, value) => debugPrint("$key: $value"));

      // Add photo
      request.files.add(await http.MultipartFile.fromPath('photo', photo));
      debugPrint("===== Photo added: $photo");

      // Send request
      http.StreamedResponse response = await request.send();

      final responseString = await response.stream.bytesToString();
      debugPrint("======== Response url: ${Confing.baseurl + Confing.addvehicle}");
      debugPrint("===== Response Status: ${response.statusCode}");
      debugPrint("======= Response Body: $responseString");

      if (response.statusCode == 200) {
        var responseData = jsonDecode(responseString);
        if (responseData["Result"] == "true") {
          if (Get.arguments != null) {
            if (Get.arguments["vehicle"] == true) {
              vehiclesListController.vehicleListApi().then((value) {
                Get.back();
                showToastMessage(responseData["ResponseMsg"]);
                isButtonLoading = false;
                update();
              });
            }
          } else {
            vehiclesScreenController.dataGetApi().then((value) {
              showToastMessage(responseData["ResponseMsg"]);
              Get.back();
              isButtonLoading = false;
              update();
            });
          }
        } else {
          showToastMessage("${responseData["ResponseMsg"]}");
        }
        return responseData;
      } else {
        showToastMessage("Failed: ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      debugPrint("===== Error: $e =====");
      showToastMessage("Error: $e");
      return null;
    } finally {
      isButtonLoading = false;
      update();
    }
  }

  Future<Map<String, dynamic>?> editVehicleApi({
    required String modelId,
    required String typeId,
    required String colorId,
    required String year,
    required String licensePlate,
    required String status,
    // required String recordId,
    required String photo,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(Confing.baseurl + Confing.editvehicle),
      );

      request.fields.addAll({
        'uid': "${getData.read("userLogin")["id"]}",
        'model_id': modelId,
        'type_id': typeId,
        'color_id': colorId,
        'year': year,
        'license_plate': licensePlate,
        'status': status,
        'record_id': "${Get.arguments["id"]}",
      });

      debugPrint("========== Request Fields =============== ${request.fields}");

      if (photo.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('photo', photo));
      }

      http.StreamedResponse response = await request.send();

      final responseString = await response.stream.bytesToString();
      debugPrint("========== Response =============== $responseString");

      if (response.statusCode == 200) {
        var responseData = jsonDecode(responseString);
        if (responseData["Result"] == "true") {
          if (Get.arguments != null) {
            if (Get.arguments["vehicle"] == true) {
              vehiclesListController.vehicleListApi().then((value) {
                Get.back();
                showToastMessage(responseData["ResponseMsg"]);
                isButtonLoading = false;
                update();
              });
            }
          } else {
            vehiclesScreenController.dataGetApi().then((value) {
              showToastMessage(responseData["ResponseMsg"]);
              Get.back();
              isButtonLoading = false;
              update();
            });
          }
        } else {
          showToastMessage(responseData["ResponseMsg"]);
          update();
        }
        return responseData;
      } else {
        showToastMessage("Error: ${response.reasonPhrase} (${response.statusCode})");
        debugPrint('Request failed with status: ${response.statusCode} - ${response.reasonPhrase}');
        return null;
      }
    } catch (e) {
      showToastMessage("An error occurred: $e");
      debugPrint("Exception caught: $e");
      return null;
    } finally {
      isButtonLoading = false;
      update();
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

        // Get file size
        final file = File(picked.path);
        final bytes = await file.length();
        final kb = bytes / 1024;
        final mb = kb / 1024;

        base64Url.value = base64Encode(await picked.readAsBytes());

        debugPrint("✔ Image Path: ${picked.path}");
        debugPrint("✔ Image Size: ${kb.toStringAsFixed(2)} KB (${mb.toStringAsFixed(2)} MB)");
        debugPrint("✔ Base64 Length: ${base64Url.value.length}");
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

  vehicleDetailsData({
    required String title,
    required Widget child,
  }){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: ccNavyText,
          ),
        ),
        SizedBox(height: 5),
        child,
      ],
    );
  }
}
