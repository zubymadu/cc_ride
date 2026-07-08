// ignore_for_file: deprecated_member_use

import 'package:carride/app/modules/controllers/account_controllers/profile_controllers/profile_screen_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/state_manager.dart';

class LifetimeHighlights extends GetView<ProfileScreenController> {
  const LifetimeHighlights({super.key});

  static const Color _yellow = Color(0xFFFFB800);
  static const Color _yellowLight = Color(0x1FFFB800);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'Lifetime highlights',
            style: TextStyle(
              color: ccNavyText,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          itemCount: controller.lifetimeText.length,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 115,
          ),
          itemBuilder: (context, index) {
            final stats = controller.userProfileApiModel!.stats!;

            String label;
            Color color;
            Color bgColor;
            String img;

            Color _tier(double val, double low, double high) {
              if (val < low) return ccError;
              if (val < high) return _yellow;
              return ccSuccess;
            }

            Color _tierBg(double val, double low, double high) {
              if (val < low) return ccErrorLight;
              if (val < high) return _yellowLight;
              return ccSuccessLight;
            }

            String _tierLabel(double val, double low, double high) {
              if (val < low) return 'Beginner';
              if (val < high) return 'Elite';
              return 'Very Pro';
            }

            String _tierImg(double val, double low, double high) {
              if (val < low) return 'assets/image/svg/Alert.svg';
              if (val < high) return 'assets/image/svg/diamond.svg';
              return 'assets/image/svg/checkmark.svg';
            }

            final double v0 =
                double.parse('${stats.peopleDriven}');
            final double v1 =
                double.parse('${stats.avgRating}');
            final double v2 =
                double.parse('${stats.ridesTaken}');
            final double v3 =
                double.parse('${stats.kmShared}');

            final List<double> vals = [v0, v1, v2, v3];
            final List<double> lows = [50, 4.0, 50, 100];
            final List<double> highs = [200, 4.5, 200, 500];

            color = _tier(vals[index], lows[index], highs[index]);
            bgColor = _tierBg(vals[index], lows[index], highs[index]);
            label = _tierLabel(vals[index], lows[index], highs[index]);
            img = _tierImg(vals[index], lows[index], highs[index]);

            final List<String> displayVals = [
              '${stats.peopleDriven}',
              '${stats.avgRating}',
              '${stats.ridesTaken}',
              '${stats.kmShared}',
            ];

            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ccSurface,
                borderRadius: BorderRadius.circular(CCRadius.card),
                boxShadow: CCShadow.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayVals[index],
                          style: const TextStyle(
                            color: ccNavyText,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      if (index == 1) ...[
                        const SizedBox(width: 5),
                        SvgPicture.asset(
                          'assets/image/svg/star-filled.svg',
                          color: _yellow,
                          height: 16,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${controller.lifetimeText[index]}',
                    style: const TextStyle(
                      color: ccSecondaryText,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          img,
                          color: color,
                          height: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
