import 'package:Artleap.ai/shared/route_export.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  final String uniqueScreenKey;

  const BannerAdWidget({
    super.key,
    required this.uniqueScreenKey,
  });

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  bool _loadRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_loadRequested) return;
    _loadRequested = true;
    Future.microtask(() {
      ref.read(centralAdManagementProvider.notifier).ensureBannerLoaded(collapsible: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bannerState = ref.watch(bannerAdStateProvider);
    final config = ref.watch(remoteConfigProvider);

    if (!config.showBannerAds) {
      return const SizedBox.shrink();
    }

    final isBannerReady = bannerState.isLoaded && bannerState.bannerAd != null &&
        bannerState.adLoaded && !bannerState.isCollapsible;


    if (isBannerReady) {
      return SizedBox(
        width: bannerState.adSize.width.toDouble(),
        height: bannerState.adSize.height.toDouble(),
        child: AdWidget(ad: bannerState.bannerAd!),
      );
    }

    if (bannerState.isLoading) {
      return const SizedBox(
        width: 320,
        height: 50,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return const SizedBox(height: 50);
  }
}