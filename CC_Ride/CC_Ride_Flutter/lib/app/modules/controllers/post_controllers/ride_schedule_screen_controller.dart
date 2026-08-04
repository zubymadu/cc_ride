// ignore_for_file: deprecated_member_use

import 'package:carride/app/modules/controllers/post_controllers/post_trip_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class RideScheduleScreenController extends GetxController with GetTickerProviderStateMixin {
  late TabController tabController = TabController(length: 2, vsync: this);

  final TextEditingController leavingDateController = TextEditingController();
  final TextEditingController returndateController = TextEditingController();

  PostTripController postTripController = Get.put(PostTripController());

  final RxList<DateTime> _selectedDates = <DateTime>[].obs;
  List<DateTime> get selectedDates => _selectedDates;
  set selectedDates(List<DateTime> value) => _selectedDates.assignAll(value);

  final RxBool _showTextField = false.obs;
  bool get showTextField => _showTextField.value;
  set showTextField(bool value) => _showTextField.value = value;

  final RxInt _tripType = 0.obs;
  int get tripType => _tripType.value;
  set tripType(int value) => _tripType.value = value;

  @override
  void onInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      tabController = TabController(
        length: 2,
        vsync: this,
        initialIndex: postTripController.rideSchedule == "one_time" ? 0 : 1,
      );
      update();
    });
    super.onInit();
  }

  TimeOfDay? parseTimeOfDay(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    final cleaned = timeStr.trim();
    if (!cleaned.contains(":")) return null;
    final parts = cleaned.split(":");
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(
        parts[1].substring(0, parts[1].length.clamp(0, 2)).trim());
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  void onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    selectedDates = args.value;
    final dateFormat = DateFormat('yyyy-MM-dd');
    postTripController.startDate =
        selectedDates.map((date) => dateFormat.format(date)).join(',');
    postTripController.returnDate =
        selectedDates.map((date) => dateFormat.format(date)).join(',');
    update();
    debugPrint("========== selectedDates ==========  $selectedDates");
    debugPrint("============ startDate ============  ${postTripController.startDate}");
    debugPrint("=========== returnDate ============  ${postTripController.returnDate}");
  }

  final RxList _tabText = ["One-time trip".tr, "Recurring trip".tr].obs;
  List get tabText => _tabText;
  set tabText(List value) => _tabText.value = value;

  Future selectDate(
      {required BuildContext context, required DateTime initialDate}) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2200),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ccPrimary,
              onPrimary: ccSurface,
              onSurface: ccNavyText,
            ),
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CCRadius.card)),
            ),
            textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: ccPrimary)),
            dialogTheme: const DialogThemeData(backgroundColor: ccSurface),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Zero-padding matters here, not just cosmetics — the backend builds
      // `${trip_start_date}T${trip_start_time}:00` and hands it to
      // `new Date(...)`. An unpadded date like "2027-1-5" isn't valid
      // ISO-8601 and silently becomes Invalid Date server-side, which fails
      // the whole post-trip call — for any date in the 1st-9th of a month.
      final mm = picked.month.toString().padLeft(2, '0');
      final dd = picked.day.toString().padLeft(2, '0');
      return "${picked.year}-$mm-$dd";
    }
    return null;
  }

  final formKey = GlobalKey<FormState>();

  final Rxn<TimeOfDay> _selectedTime = Rxn<TimeOfDay>();
  TimeOfDay? get selectedTime => _selectedTime.value;
  set selectedTime(TimeOfDay? value) => _selectedTime.value = value;

  final Rxn<TimeOfDay> _selectedTime1 = Rxn<TimeOfDay>();
  TimeOfDay? get selectedTime1 => _selectedTime1.value;
  set selectedTime1(TimeOfDay? value) => _selectedTime1.value = value;

  final Rxn<DateTime> _originTime = Rxn<DateTime>();
  DateTime? get originTime => _originTime.value;
  set originTime(DateTime? value) => _originTime.value = value;

  final Rxn<DateTime> _originTime1 = Rxn<DateTime>();
  DateTime? get originTime1 => _originTime1.value;
  set originTime1(DateTime? value) => _originTime1.value = value;

  Future<TimeOfDay?> selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ccPrimary,
              onPrimary: ccSurface,
              onSurface: ccNavyText,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: ccSurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CCRadius.card)),
              hourMinuteColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? ccIceBlue
                    : const Color(0xFFF0F0F0),
              ),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hourMinuteTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? ccPrimary
                    : ccNavyText,
              ),
              dayPeriodBorderSide: const BorderSide(color: ccInputBorder),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              dialHandColor: ccPrimary,
              dialBackgroundColor: ccIceBlue,
              entryModeIconColor: ccPrimary,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != selectedTime) {
      debugPrint("--------- picked ------- $picked");
      return picked;
    }
    return null;
  }

  Widget selectTimeField({
    required VoidCallback onTap,
    required String time,
    double? width,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CCRadius.input),
      child: Container(
        height: 48,
        width: width ?? 100,
        decoration: BoxDecoration(
          border: Border.all(color: ccInputBorder),
          color: ccSurface,
          borderRadius: BorderRadius.circular(CCRadius.input),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        child: Text(
          time,
          style: const TextStyle(
            fontSize: 15,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            color: ccNavyText,
          ),
        ),
      ),
    );
  }
}
