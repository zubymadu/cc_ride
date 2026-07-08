import 'dart:convert';
import 'dart:developer';

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/modules/models/vehicle_list_api_model.dart';
import 'package:carride/theme/theme_colores.dart';
import 'package:carride/widgets/custom_widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class VehiclesListController extends GetxController {
  ThemeColores themeColores = Get.put(ThemeColores());

  @override
  void onInit() {
    vehicleListApi();
    super.onInit();
  }

  VehicleListApiModel? vehicleListApiModel;

  final RxBool _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  Map<String, String> userHeader = {
    "Content-type": "application/json",
    "Accept": "application/json",
  };

  Future vehicleListApi() async {
    isLoading = true;
    update();
    Map body = {"uid": "${getData.read("userLogin")["id"]}"};

    try {
      String url = Confing.baseurl + Confing.vehicleList;

      var response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: userHeader,
      );

      log(name: "============= Vehicle List Api url ==============", url);
      log(name: "============= Vehicle List Api body =============", "$body");
      log(name: "=========== Vehicle List Api response ===========", response.body);

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["Result"] == "true") {
          vehicleListApiModel = vehicleListApiModelFromJson(response.body);
          update();
          if (vehicleListApiModel!.result == "true") {
            isLoading = false;
            update();
            return data;
          } else {
            showToastMessage("${vehicleListApiModel!.responseMsg}");
            return data;
          }
        } else {
          showToastMessage("${data["ResponseMsg"]}");
          return data;
        }
      } else {
        showToastMessage("Somthing went wrong!.....");
      }
    } catch (e) {
      log("============= Vehicle List Api Error =============  $e");
    }
  }
}
