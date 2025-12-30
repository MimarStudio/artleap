import 'package:Artleap.ai/shared/route_export.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  final bool isCollapsible;
  final bool useAdaptiveSize;

  const BannerAdWidget({
    super.key,
    this.isCollapsible = false,
    this.useAdaptiveSize = true,
  });

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  final BannerAdManager _adManager = BannerAdManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBannerAd();
    });
  }

  Future<void> _loadBannerAd() async {
    if (widget.useAdaptiveSize && widget.isCollapsible) {
      await _adManager.loadAdaptiveCollapsibleBanner(
        ref: ref,
        context: context,
        onAdFailedToLoad: (error) {
          debugPrint('Failed to load collapsible banner ad: $error');
        },
      );
    } else if (widget.isCollapsible) {
      await _adManager.loadBannerAd(
        ref: ref,
        adSize: AdSize.banner,
        onAdFailedToLoad: (error) {
          debugPrint('Failed to load banner ad: $error');
        },
        isCollapsible: true,
      );
    } else {
      await _adManager.loadBannerAd(
        ref: ref,
        adSize: AdSize.banner,
        onAdFailedToLoad: (error) {
          debugPrint('Failed to load banner ad: $error');
        },
        isCollapsible: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBannerAds = ref.watch(bannerAdsEnabledProvider);

    if (!showBannerAds) {
      return const SizedBox.shrink();
    }

    return _adManager.getBannerWidget(ref);
  }

  @override
  void dispose() {
    _adManager.dispose();
    super.dispose();
  }
}