// ignore_for_file: deprecated_member_use

import 'package:carride/app/data/corporate_models.dart';
import 'package:carride/app/modules/controllers/corporate_controllers/route_management_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RouteManagementView extends GetView<RouteManagementController> {
  const RouteManagementView({super.key});

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
        title: const Text(
          "Shared Routes",
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateRouteSheet(context),
        backgroundColor: ccPrimary,
        icon: const Icon(Icons.add_road_outlined, color: Colors.white),
        label: const Text(
          'New Route',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      body: GetBuilder<RouteManagementController>(
        builder: (c) => c.isLoading && c.routes.isEmpty
            ? const Center(child: CircularProgressIndicator(color: ccPrimary))
            : RefreshIndicator(
                onRefresh: c.fetchRoutes,
                color: ccPrimary,
                child: c.routes.isEmpty
                    ? _emptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: c.routes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _routeCard(context, c, c.routes[i]),
                      ),
              ),
      ),
    );
  }

  Widget _routeCard(BuildContext context, RouteManagementController c, RouteModel route) {
    return InkWell(
      borderRadius: BorderRadius.circular(CCRadius.card),
      onTap: () => _showSchedulesSheet(context, c, route),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ccSurface,
          borderRadius: BorderRadius.circular(CCRadius.card),
          boxShadow: CCShadow.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ccIceBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    route.code,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: ccPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(route.name, style: CCText.titleMd),
                ),
                if (!route.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ccErrorLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Inactive',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: ccError,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.trip_origin, size: 12, color: ccSecondaryText),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(route.originName,
                      style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 12, color: ccSecondaryText),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(route.destinationName,
                      style: CCText.bodyMd.copyWith(color: ccSecondaryText),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 12, color: ccSecondaryText),
                const SizedBox(width: 4),
                Text('${route.scheduleCount} schedule(s)',
                    style: CCText.labelSm.copyWith(color: ccSecondaryText)),
                const SizedBox(width: 12),
                const Icon(Icons.pin_drop_outlined, size: 12, color: ccSecondaryText),
                const SizedBox(width: 4),
                Text('${route.stopCount} stop(s)',
                    style: CCText.labelSm.copyWith(color: ccSecondaryText)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(color: ccIceBlue, shape: BoxShape.circle),
              child: const Icon(Icons.add_road_outlined, color: ccPrimary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('No shared routes yet', style: CCText.headlineMd),
            const SizedBox(height: 8),
            Text(
              'Tap + New Route to create one',
              style: CCText.bodyMd.copyWith(color: ccSecondaryText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  void _showCreateRouteSheet(BuildContext context) {
    controller.codeCtrl.clear();
    controller.nameCtrl.clear();
    controller.originCtrl.clear();
    controller.destinationCtrl.clear();
    controller.timeCtrl.clear();
    controller.fareCtrl.clear();
    controller.seatCtrl.clear();
    controller.scheduleVehicleId.value = '';
    controller.scheduleDriverId.value = '';
    controller.scheduleDays.clear();
    controller.setupScheduleNow = false;
    // Needed for the vehicle/driver dropdowns below if the admin opts into
    // setting up a schedule now instead of as a separate later step.
    controller.fetchPoolVehicles();
    controller.fetchEmployees();

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: ccSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(CCRadius.sheet)),
      ),
      Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: GetBuilder<RouteManagementController>(
          builder: (c) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                const SizedBox(height: 16),
                const Text('New Shared Route',
                    style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        color: ccNavyText)),
                const SizedBox(height: 16),
                _sheetField('Route Code', c.codeCtrl, 'e.g. WSE01'),
                const SizedBox(height: 12),
                _sheetField('Route Name', c.nameCtrl, 'e.g. Wuse - CBD'),
                const SizedBox(height: 12),
                _sheetField('Origin', c.originCtrl, 'e.g. Wuse Zone 1'),
                const SizedBox(height: 12),
                _sheetField('Destination', c.destinationCtrl, 'e.g. CBD Garki'),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    c.setupScheduleNow = !c.setupScheduleNow;
                    c.update();
                  },
                  child: Row(
                    children: [
                      Icon(
                        c.setupScheduleNow ? Icons.check_box : Icons.check_box_outline_blank,
                        color: c.setupScheduleNow ? ccPrimary : ccSecondaryText,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Set up first schedule now (driver, vehicle, seats, fare)',
                            style: TextStyle(fontSize: 13, fontFamily: 'Inter', color: ccNavyText)),
                      ),
                    ],
                  ),
                ),
                if (c.setupScheduleNow) ...[
                  const SizedBox(height: 12),
                  _sheetField('Departure Time (24h)', c.timeCtrl, 'e.g. 08:00'),
                  const SizedBox(height: 12),
                  _daysPicker(c),
                  const SizedBox(height: 12),
                  _sheetField('Fare (₦)', c.fareCtrl, 'e.g. 1500', keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  _sheetField('Seat Capacity', c.seatCtrl, 'e.g. 4', keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  _vehicleDropdown(c),
                  const SizedBox(height: 12),
                  _driverDropdown(c),
                ],
                const SizedBox(height: 20),
                c.isSaving
                    ? const SizedBox(
                        height: 52,
                        child: Center(child: CircularProgressIndicator(color: ccPrimary)),
                      )
                    : _primaryButton('Create Route', c.createRoute),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSchedulesSheet(BuildContext context, RouteManagementController c, RouteModel route) {
    c.fetchSchedules(route.id);
    c.fetchPoolVehicles();
    c.fetchEmployees();

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: ccSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(CCRadius.sheet)),
      ),
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.85),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: GetBuilder<RouteManagementController>(
          builder: (ctrl) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text('${route.code} · Schedules',
                        style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: ccNavyText)),
                  ),
                  TextButton(
                    onPressed: () => _showAddScheduleSheet(context, ctrl, route.id),
                    child: const Text('+ Add',
                        style: TextStyle(color: ccPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ctrl.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator(color: ccPrimary)),
                      )
                    : ctrl.schedules.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('No schedules yet',
                                style: CCText.bodyMd.copyWith(color: ccSecondaryText)),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: ctrl.schedules.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => _scheduleTile(ctrl.schedules[i]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scheduleTile(RouteScheduleModel s) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ccBackground,
          borderRadius: BorderRadius.circular(CCRadius.input),
          border: Border.all(color: ccInputBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: ccIceBlue, shape: BoxShape.circle),
              child: const Icon(Icons.access_time, color: ccPrimary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${s.departureTime} · ${s.daysLabel}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: ccNavyText)),
                  const SizedBox(height: 2),
                  Text('${s.driverName} · ${s.vehicleTitle} · ${s.seatCapacity} seats',
                      style: CCText.labelSm.copyWith(color: ccSecondaryText)),
                ],
              ),
            ),
            Text('₦${s.fare.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w700, color: ccPrimary)),
          ],
        ),
      );

  void _showAddScheduleSheet(BuildContext context, RouteManagementController c, String routeId) {
    c.timeCtrl.clear();
    c.fareCtrl.clear();
    c.seatCtrl.clear();
    c.scheduleVehicleId.value = '';
    c.scheduleDriverId.value = '';
    c.scheduleDays.clear();

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: ccSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(CCRadius.sheet)),
      ),
      Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: GetBuilder<RouteManagementController>(
          builder: (c2) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                const SizedBox(height: 16),
                const Text('Add Schedule',
                    style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        color: ccNavyText)),
                const SizedBox(height: 16),
                _sheetField('Departure Time (24h)', c2.timeCtrl, 'e.g. 08:00'),
                const SizedBox(height: 12),
                _daysPicker(c2),
                const SizedBox(height: 12),
                _sheetField('Fare (₦)', c2.fareCtrl, 'e.g. 1500',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _sheetField('Seat Capacity', c2.seatCtrl, 'e.g. 4',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _vehicleDropdown(c2),
                const SizedBox(height: 12),
                _driverDropdown(c2),
                const SizedBox(height: 20),
                c2.isSaving
                    ? const SizedBox(
                        height: 52,
                        child: Center(child: CircularProgressIndicator(color: ccPrimary)),
                      )
                    : _primaryButton('Add Schedule', () => c2.createSchedule(routeId)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _daysPicker(RouteManagementController c) {
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Obx(() => Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(7, (day) {
            final selected = c.scheduleDays.contains(day);
            return GestureDetector(
              onTap: () => c.toggleScheduleDay(day),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? ccPrimary : Colors.transparent,
                  border: Border.all(color: selected ? ccPrimary : ccInputBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(names[day],
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : ccNavyText,
                    )),
              ),
            );
          }),
        ));
  }

  Widget _vehicleDropdown(RouteManagementController c) => Obx(() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: ccSurface,
          border: Border.all(color: ccInputBorder),
          borderRadius: BorderRadius.circular(CCRadius.input),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            dropdownColor: ccSurface,
            value: c.scheduleVehicleId.value.isEmpty ? null : c.scheduleVehicleId.value,
            hint: const Text('Select pool vehicle',
                style: TextStyle(color: ccSecondaryText, fontFamily: 'Inter')),
            items: c.poolVehicles
                .map((v) => DropdownMenuItem<String>(
                      value: '${v['id']}',
                      child: Text('${v['model_title']} · ${v['license_plate']}',
                          style: const TextStyle(color: ccNavyText, fontFamily: 'Inter')),
                    ))
                .toList(),
            onChanged: (v) => c.scheduleVehicleId.value = v ?? '',
          ),
        ),
      ));

  Widget _driverDropdown(RouteManagementController c) => Obx(() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: ccSurface,
          border: Border.all(color: ccInputBorder),
          borderRadius: BorderRadius.circular(CCRadius.input),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            dropdownColor: ccSurface,
            value: c.scheduleDriverId.value.isEmpty ? null : c.scheduleDriverId.value,
            hint: const Text('Select driver',
                style: TextStyle(color: ccSecondaryText, fontFamily: 'Inter')),
            items: c.employees
                .map((e) => DropdownMenuItem<String>(
                      value: e.userId,
                      child: Text(e.name,
                          style: const TextStyle(color: ccNavyText, fontFamily: 'Inter')),
                    ))
                .toList(),
            onChanged: (v) => c.scheduleDriverId.value = v ?? '',
          ),
        ),
      ));

  Widget _sheetHandle() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: ccInputBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _sheetField(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                color: ccNavyText)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(color: ccNavyText, fontFamily: 'Inter'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: ccSecondaryText, fontFamily: 'Inter'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: ccSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CCRadius.input),
              borderSide: const BorderSide(color: ccInputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CCRadius.input),
              borderSide: const BorderSide(color: ccInputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CCRadius.input),
              borderSide: const BorderSide(color: ccPrimary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton(String label, VoidCallback onPressed) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: ccPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CCRadius.btn)),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
        ),
      );
}
