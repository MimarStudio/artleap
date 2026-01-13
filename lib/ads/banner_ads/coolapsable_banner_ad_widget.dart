import 'package:Artleap.ai/shared/route_export.dart';

class CollapsibleBannerAdWidget extends ConsumerWidget {
  final String uniqueScreenKey;

  const CollapsibleBannerAdWidget({
    super.key,
    required this.uniqueScreenKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannerState = ref.watch(bannerAdStateProvider);
    final centralAdState = ref.watch(centralAdManagementProvider);

    final isCollapsibleBannerActive =
        centralAdState.adLoadStatus['collapsibleBanner'] == true;

    final isBannerLoaded = bannerState.isLoaded &&
        bannerState.bannerAd != null &&
        bannerState.adLoaded &&
        bannerState.isCollapsible;

    if (!isBannerLoaded || !isCollapsibleBannerActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(centralAdManagementProvider.notifier).loadCollapsibleBannerAd();
      });
      return const SizedBox(height: 50);
    }

    return SizedBox(
      width: bannerState.adSize.width.toDouble(),
      height: bannerState.adSize.height.toDouble(),
      child: AdWidget(ad: bannerState.bannerAd!),
    );
  }
}
