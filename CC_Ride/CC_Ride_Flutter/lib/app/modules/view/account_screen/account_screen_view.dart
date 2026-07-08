// ignore_for_file: deprecated_member_use

import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/logout_delete_bottomsheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../controllers/account_controllers/account_screen_controller.dart';

class AccountScreenView extends GetView<AccountScreenController> {
  const AccountScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AccountScreenController>();
    return GetBuilder<AccountScreenController>(
      init: AccountScreenController(),
      initState: (state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          c.pageListApi();
        });
      },
      builder: (_) {
        final user = getData.read("userLogin");
        final hasPic = user != null &&
            user["profile_pic"] != null &&
            user["profile_pic"].toString().isNotEmpty;

        return Scaffold(
          backgroundColor: ccBackground,
          body: c.isLoading
              ? const Center(child: CircularProgressIndicator(color: ccPrimary))
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── App bar + profile hero ──────────────────────────
                    SliverToBoxAdapter(
                      child: Container(
                        color: ccSurface,
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 16,
                          left: 20,
                          right: 20,
                          bottom: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "My Account",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: ccNavyText,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Profile row
                            GestureDetector(
                              onTap: () => Get.toNamed(Routes.PROFILE_SCREEN)
                                  ?.then((_) => c.update()),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF001B3D), ccPrimary],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(CCRadius.card),
                                  boxShadow: CCShadow.card,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.4),
                                            width: 2),
                                        color:
                                            Colors.white.withOpacity(0.1),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: hasPic
                                          ? FadeInImage.assetNetwork(
                                              placeholder:
                                                  "assets/image/ezgif.com-crop.gif",
                                              image:
                                                  "${Confing.imageurl}${user!["profile_pic"]}",
                                              fit: BoxFit.cover,
                                              imageErrorBuilder:
                                                  (_, __, ___) =>
                                                      Image.asset(
                                                "assets/image/ezgif.com-crop.gif",
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                user != null &&
                                                        user["name"] != null
                                                    ? user["name"][0]
                                                        .toString()
                                                        .toUpperCase()
                                                    : "?",
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user != null
                                                ? "${user["name"]}"
                                                : "",
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            user != null
                                                ? "${user["email"]}"
                                                : "",
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13,
                                              color: Colors.white
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(99),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                      child: const Text(
                                        "View",
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // ── Preferences section ──────────────────────
                          const _SectionLabel("Personalization & Preferences"),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: ccSurface,
                              borderRadius:
                                  BorderRadius.circular(CCRadius.card),
                              boxShadow: CCShadow.card,
                            ),
                            child: Column(
                              children: [
                                for (int i = 0;
                                    i < c.proferences.length;
                                    i++) ...[
                                  _MenuTile(
                                    icon: _prefIcon(i),
                                    label: "${c.proferences[i]}",
                                    onTap: () => _onPrefTap(i, c),
                                    showDivider:
                                        i != c.proferences.length - 1,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Account & Security section ───────────────
                          const _SectionLabel("Account & Security"),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: ccSurface,
                              borderRadius:
                                  BorderRadius.circular(CCRadius.card),
                              boxShadow: CCShadow.card,
                            ),
                            child: Column(
                              children: [
                                if (c.pageListApiModel?.pagelist != null)
                                  for (int pi = 0;
                                      pi <
                                          c.pageListApiModel!.pagelist!
                                              .length;
                                      pi++) ...[
                                    _MenuTile(
                                      icon: Icons.description_outlined,
                                      label:
                                          "${c.pageListApiModel!.pagelist![pi].title}",
                                      onTap: () {
                                        Get.toNamed(
                                          Routes.PAGE_LIST_DESCRIPTION,
                                          arguments: {
                                            "title":
                                                "${c.pageListApiModel!.pagelist![pi].title}",
                                            "description":
                                                "${c.pageListApiModel!.pagelist![pi].description}",
                                          },
                                        );
                                      },
                                      showDivider: true,
                                    ),
                                  ],
                                for (int ai = 0;
                                    ai < c.accountSecurity.length;
                                    ai++)
                                  _MenuTile(
                                    icon: ai == 0
                                        ? Icons.logout_rounded
                                        : Icons.delete_outline_rounded,
                                    label: "${c.accountSecurity[ai]}",
                                    isDestructive: true,
                                    showDivider:
                                        ai != c.accountSecurity.length - 1,
                                    onTap: () {
                                      if (ai == 0) {
                                        logOutAndDeleteAccountBottomsheet(
                                          title: "Logout".tr,
                                          subtitle:
                                              "Are you sure you want to log out?"
                                                  .tr,
                                          buttonText: "Yes, Logout".tr,
                                          onTap: () {
                                            final storage = GetStorage();
                                            storage.erase();
                                            c.themeColores
                                                .toggleTheme(dark: false);
                                            c.languageScreenController
                                                .updateLanguage(
                                                    const Locale('en', 'US'));
                                            c.themeColores.update();
                                            c.update();
                                            Get.offAllNamed(
                                                Routes.LOGIN_SCREEN);
                                          },
                                        );
                                      } else if (ai == 1) {
                                        logOutAndDeleteAccountBottomsheet(
                                          title: "Delete Account".tr,
                                          subtitle:
                                              "Are you sure you want to delete account?"
                                                  .tr,
                                          buttonText: "Yes, Delete".tr,
                                          onTap: () => c.deleteAccountApi(),
                                        );
                                      }
                                    },
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),
                        ]),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  IconData _prefIcon(int i) {
    const icons = [
      Icons.person_outline_rounded,
      Icons.directions_car_outlined,
      Icons.receipt_long_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.attach_money_rounded,
      Icons.help_outline_rounded,
      Icons.people_outline_rounded,
      Icons.language_rounded,
    ];
    return i < icons.length ? icons[i] : Icons.settings_outlined;
  }

  void _onPrefTap(int i, AccountScreenController c) {
    switch (i) {
      case 0:
        Get.toNamed(Routes.PERSONAL_DETAILS)?.then((_) => c.update());
        break;
      case 1:
        Get.toNamed(Routes.VEHICLES_LIST)?.then((_) => c.update());
        break;
      case 2:
        Get.toNamed(Routes.MY_BOOKING_SCREEN)?.then((_) => c.update());
        break;
      case 3:
        Get.toNamed(Routes.WALLET_SCREEN)?.then((_) => c.update());
        break;
      case 4:
        Get.toNamed(Routes.EARNING_SCREEN)?.then((_) => c.update());
        break;
      case 5:
        Get.toNamed(Routes.HELP_SCREEN)?.then((_) => c.update());
        break;
      case 6:
        Get.toNamed(Routes.REFER_SCREEN)?.then((_) => c.update());
        break;
      case 7:
        Get.toNamed(Routes.LANGUAGE_SCREEN)?.then((_) => c.update());
        break;
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: CCText.labelSm.copyWith(
        color: ccSecondaryText,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.isDestructive = false,
    this.showDivider = true,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isDestructive;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFD32F2F) : ccNavyText;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CCRadius.card),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? const Color(0xFFFFEBEE)
                        : ccIceBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon,
                      color: isDestructive
                          ? const Color(0xFFD32F2F)
                          : ccPrimary,
                      size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: color,
                      )),
                ),
                trailing ??
                    Icon(Icons.chevron_right_rounded,
                        color: ccSecondaryText, size: 20),
              ],
            ),
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 66),
            color: ccInputBorder,
          ),
      ],
    );
  }
}
