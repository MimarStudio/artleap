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
  BannerAd? _localBannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createLocalBanner();
    });
  }

  Future<void> _createLocalBanner() async {
    final config = ref.read(remoteConfigProvider);
    if (!config.showBannerAds) return;

    final width =
    MediaQuery.of(context).size.width.truncate();

    final size =
    await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (!mounted || size == null) return;

    _localBannerAd = BannerAd(
      adUnitId: config.bannerAdUnit,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    await _localBannerAd!.load();
  }

  @override
  void dispose() {
    _localBannerAd?.dispose();
    _localBannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _localBannerAd == null) {
      return const SizedBox(height: 50);
    }

    return SizedBox(
      width: _localBannerAd!.size.width.toDouble(),
      height: _localBannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _localBannerAd!),
    );
  }
}
