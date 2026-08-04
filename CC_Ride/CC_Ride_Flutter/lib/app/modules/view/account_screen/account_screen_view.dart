// ignore_for_file: deprecated_member_use

import 'package:carride/app/data/app_info.dart';
import 'package:carride/app/data/confing.dart';
import 'package:carride/app/data/data_store.dart';
import 'package:carride/app/routes/app_pages.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:carride/widgets/logout_delete_bottomsheet.dart';
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
                            // Profile hero — centered avatar, name,
                            // company subtitle and an Edit Profile link,
                            // matching the account-screen redesign.
                            Center(
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        Get.toNamed(Routes.PROFILE_SCREEN)
                                            ?.then((_) => c.update()),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: ccInputBorder, width: 2),
                                        color: ccIceBlue,
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
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w700,
                                                  color: ccPrimary,
                                                ),
                                              ),
                                            ),
                                        ),
                                        if (user != null &&
                                            (user["is_mobile_verify"] ==
                                                    "1" ||
                                                user["is_email_verify"] ==
                                                    "1"))
                                          Positioned(
                                            right: -2,
                                            bottom: -2,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: ccSurface,
                                              ),
                                              child: const Icon(
                                                Icons.verified_rounded,
                                                color: ccPrimary,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    user != null ? "${user["name"]}" : "",
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: ccNavyText,
                                    ),
                                  ),
                                  if (user != null &&
                                      user["company_name"] != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      "${user["company_name"]}",
                                      style: CCText.bodyMd
                                          .copyWith(color: ccSecondaryText),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () =>
                                        Get.toNamed(Routes.PERSONAL_DETAILS)
                                            ?.then((_) => c.update()),
                                    child: Text(
                                      "Edit Profile",
                                      style: CCText.labelSm
                                          .copyWith(color: ccPrimary),
                                    ),
                                  ),
                                ],
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
                          // ── Account section ──────────────────────────
                          // proferences[0] = Personal Info (covers name,
                          // phone and email + verification — there's no
                          // separate Work Email/Password screen to link to).
                          const _SectionLabel("Account"),
                          const SizedBox(height: 8),
                          _sectionCard(c, indices: const [0, 1, 2]),

                          const SizedBox(height: 20),

                          // ── Finance section ───────────────────────────
                          const _SectionLabel("Finance"),
                          const SizedBox(height: 8),
                          _sectionCard(c, indices: const [3, 4, 6]),

                          const SizedBox(height: 20),

                          // ── Preferences section ───────────────────────
                          const _SectionLabel("Preferences"),
                          const SizedBox(height: 8),
                          _sectionCard(c, indices: const [7, 8]),

                          const SizedBox(height: 20),

                          // ── Support section ───────────────────────────
                          const _SectionLabel("Support"),
                          const SizedBox(height: 8),
                          _sectionCard(c, indices: const [5]),

                          // ── Legal section — dynamic CMS pages (Privacy,
                          // Terms, etc.) fetched from pageListApi().
                          if (c.pageListApiModel?.pagelist?.isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 20),
                            const _SectionLabel("Legal"),
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
                                  for (int pi = 0;
                                      pi <
                                          c.pageListApiModel!.pagelist!
                                              .length;
                                      pi++)
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
                                      showDivider: pi !=
                                          c.pageListApiModel!.pagelist!
                                                  .length -
                                              1,
                                    ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),

                          // ── Sign out ───────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () {
                                logOutAndDeleteAccountBottomsheet(
                                  title: "Logout".tr,
                                  subtitle:
                                      "Are you sure you want to log out?".tr,
                                  buttonText: "Yes, Logout".tr,
                                  onTap: () {
                                    final storage = GetStorage();
                                    storage.erase();
                                    c.themeColores.toggleTheme(dark: false);
                                    c.languageScreenController.updateLanguage(
                                        const Locale('en', 'US'));
                                    c.themeColores.update();
                                    c.update();
                                    Get.offAllNamed(Routes.LOGIN_SCREEN);
                                  },
                                );
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFFFFEBEE),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(CCRadius.btn),
                                ),
                              ),
                              icon: const Icon(Icons.logout_rounded,
                                  color: Color(0xFFD32F2F), size: 18),
                              label: const Text(
                                "Sign Out",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD32F2F),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                logOutAndDeleteAccountBottomsheet(
                                  title: "Delete Account".tr,
                                  subtitle:
                                      "Are you sure you want to delete account?"
                                          .tr,
                                  buttonText: "Yes, Delete".tr,
                                  onTap: () => c.deleteAccountApi(),
                                );
                              },
                              child: Text(
                                "Close your account",
                                style: CCText.labelSm
                                    .copyWith(color: ccSecondaryText),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          Center(
                            child: Obx(() => Text(
                              AppInfo.versionLabel.value.isEmpty
                                  ? "CC_Ride"
                                  : AppInfo.versionLabel.value,
                              style: CCText.labelSm
                                  .copyWith(color: ccSecondaryText),
                            )),
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
      Icons.chat_bubble_outline_rounded,
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
      case 8:
        Get.toNamed(Routes.MESSAGE_LIST)?.then((_) => c.update());
        break;
    }
  }

  Widget _sectionCard(AccountScreenController c,
      {required List<int> indices}) {
    return Container(
      decoration: BoxDecoration(
        color: ccSurface,
        borderRadius: BorderRadius.circular(CCRadius.card),
        boxShadow: CCShadow.card,
      ),
      child: Column(
        children: [
          for (int j = 0; j < indices.length; j++)
            _MenuTile(
              icon: _prefIcon(indices[j]),
              label: "${c.proferences[indices[j]]}",
              onTap: () => _onPrefTap(indices[j], c),
              showDivider: j != indices.length - 1,
            ),
        ],
      ),
    );
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
    this.showDivider = true,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
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
                    color: ccIceBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: ccPrimary, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: ccNavyText,
                      )),
                ),
                const Icon(Icons.chevron_right_rounded,
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
