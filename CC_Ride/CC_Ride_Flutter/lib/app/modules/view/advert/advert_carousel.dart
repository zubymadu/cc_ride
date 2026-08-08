import 'package:carride/app/data/confing.dart';
import 'package:carride/app/modules/controllers/advert/advert_controller.dart';
import 'package:carride/utils/cc_ds.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

// Swipeable announcement/advert cards sourced from the admin console
// (Adverts page → GET /adverts.php) — shown on both the passenger home
// (replacing the My Bookings / Wallet / Refer & Earn / Help quick-actions
// row) and the driver home, right under the primary CTA on each screen.
class AdvertCarousel extends StatefulWidget {
  const AdvertCarousel({super.key});

  @override
  State<AdvertCarousel> createState() => _AdvertCarouselState();
}

class _AdvertCarouselState extends State<AdvertCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  final RxInt _page = 0.obs;

  AdvertController get _controller =>
      Get.isRegistered<AdvertController>() ? Get.find<AdvertController>() : Get.put(AdvertController());

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdvertController>(
      init: _controller,
      builder: (c) {
        if (c.isLoading && c.adverts.isEmpty) return const SizedBox.shrink();
        if (c.adverts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              child: PageView.builder(
                controller: _pageController,
                itemCount: c.adverts.length,
                onPageChanged: (i) => _page.value = i,
                itemBuilder: (context, i) => _AdvertCard(advert: c.adverts[i]),
              ),
            ),
            if (c.adverts.length > 1) ...[
              const SizedBox(height: 10),
              Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      c.adverts.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _page.value == i ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _page.value == i ? ccPrimary : ccInputBorder,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  )),
            ],
          ],
        );
      },
    );
  }
}

class _AdvertCard extends StatelessWidget {
  const _AdvertCard({required this.advert});
  final Advert advert;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: advert.linkUrl.isEmpty
            ? null
            : () async {
                final uri = Uri.tryParse(advert.linkUrl);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(CCRadius.card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                advert.imageUrl.startsWith('http')
                    ? advert.imageUrl
                    : '${Confing.imageurl}${advert.imageUrl}',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: ccIceBlue),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : Container(color: ccIceBlue),
              ),
              // Legible-title gradient — same idea as a hero banner overlay,
              // so the title reads regardless of how bright the image is.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      advert.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (advert.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        advert.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
