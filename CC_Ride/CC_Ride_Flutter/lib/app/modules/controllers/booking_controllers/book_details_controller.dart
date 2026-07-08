import 'package:carride/app/modules/controllers/post_controllers/trip_preview_screen_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookDetailsController extends GetxController {
  TripPreviewScreenController tripPreviewScreenController = Get.put(TripPreviewScreenController());

  final buttonKey = GlobalKey<FormState>();

  OverlayEntry? overlayEntry;
  final RxBool tooltipVisible = false.obs;

  void toggleTooltip(BuildContext context) {
    tooltipVisible.value ? hideTooltip() : showTooltip(context);
  }

  void showTooltip(BuildContext context) {
    if (buttonKey.currentContext == null) return;

    final RenderBox renderBox = buttonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: hideTooltip,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            left: position.dy - 100,
            top: position.dy + 20,
            child: Material(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: CustomPaint(
                      painter: UpwardTrianglePainter(),
                      child: const SizedBox(width: 15, height: 10),
                    ),
                  ),
                  Container(
                    width: Get.width / 1.5,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ccNavyText,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "The departure time is an estimate because the trip starts at the origin location.",
                      style: TextStyle(
                        color: ccBackground,
                        fontFamily: 'Inter', fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(overlayEntry!);
    tooltipVisible.value = true;
  }

  void hideTooltip() {
    overlayEntry?.remove();
    overlayEntry = null;
    tooltipVisible.value = false;
    update();
  }

  @override
  void onClose() {
    hideTooltip();
    super.onClose();
  }
}

class UpwardTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1E1E1E);

    final path = Path();
    path.moveTo(size.width / 2, 0);            // Top point
    path.lineTo(0, size.height);               // Bottom left
    path.lineTo(size.width, size.height);      // Bottom right
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}