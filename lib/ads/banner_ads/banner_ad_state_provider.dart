import 'dart:async';
import 'package:Artleap.ai/shared/route_export.dart';

final bannerAdStateProvider = StateNotifierProvider<BannerAdStateNotifier, BannerAdState>((ref) {
  return BannerAdStateNotifier(ref);
});

class BannerAdState {
  final bool isLoading;
  final bool adLoaded;
  final AdSize adSize;
  final int retryCount;
  final bool isCollapsible;
  final bool isLoaded;

  BannerAdState({
    this.isLoading = false,
    this.adLoaded = false,
    AdSize? adSize,
    this.retryCount = 0,
    this.isCollapsible = false,
    this.isLoaded = false,
  }) : adSize = adSize ?? AdSize.banner;

  BannerAdState copyWith({
    bool? isLoading,
    bool? adLoaded,
    AdSize? adSize,
    int? retryCount,
    bool? isCollapsible,
    bool? isLoaded,
  }) {
    return BannerAdState(
      isLoading: isLoading ?? this.isLoading,
      adLoaded: adLoaded ?? this.adLoaded,
      adSize: adSize ?? this.adSize,
      retryCount: retryCount ?? this.retryCount,
      isCollapsible: isCollapsible ?? this.isCollapsible,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class BannerAdStateNotifier extends StateNotifier<BannerAdState> {
  final Ref _ref;
  BannerAd? _bannerAd;
  bool _isDisposed = false;
  Timer? _retryTimer;

  BannerAdStateNotifier(this._ref) : super(BannerAdState());

  Future<void> initializeBannerAd({bool isCollapsible = false}) async {
    if (_isDisposed || state.isLoading || state.isLoaded) return;

    state = state.copyWith(
      isLoading: true,
      isCollapsible: isCollapsible,
    );

    final showBannerAds = _ref.read(bannerAdsEnabledProvider);
    if (!showBannerAds) {
      if (!_isDisposed) {
        state = state.copyWith(isLoading: false, adLoaded: false, isLoaded: true);
      }
      return;
    }

    await _loadCollapsibleBannerAd();
  }

  Future<void> _loadCollapsibleBannerAd() async {
    if (_isDisposed) return;

    final showBannerAds = _ref.read(bannerAdsEnabledProvider);
    if (!showBannerAds) {
      if (!_isDisposed) {
        state = state.copyWith(isLoading: false, adLoaded: false, isLoaded: true);
      }
      return;
    }

    // Get adaptive ad size first
    final screenWidth = MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width.truncate();
    final adaptiveAdSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(screenWidth);

    if (adaptiveAdSize == null) {
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          adLoaded: false,
          isLoaded: true,
        );
      }
      return;
    }

    _bannerAd?.dispose();
    _bannerAd = null;

    final adUnitId = _ref.read(remoteConfigProvider).bannerAdUnit;

    // Create collapsible request if enabled
    final adRequest = state.isCollapsible
        ? const AdRequest(extras: {"collapsible": "bottom"})
        : const AdRequest();

    _bannerAd = BannerAd(
      size: adaptiveAdSize,
      adUnitId: adUnitId,
      request: adRequest,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (!_isDisposed) {
            state = state.copyWith(
              isLoading: false,
              adLoaded: true,
              isLoaded: true,
              adSize: adaptiveAdSize,
              retryCount: 0,
            );
          }
        },
        onAdFailedToLoad: (Ad ad, AdError error) {
          ad.dispose();
          if (!_isDisposed) {
            state = state.copyWith(
              isLoading: false,
              adLoaded: false,
              isLoaded: true,
              retryCount: state.retryCount + 1,
            );

            _retryTimer?.cancel();
            if (state.retryCount < 3) {
              _retryTimer = Timer(const Duration(seconds: 2), () {
                if (!_isDisposed) {
                  _loadCollapsibleBannerAd();
                }
              });
            }
          }
        },
        onAdOpened: (Ad ad) {},
        onAdClosed: (Ad ad) {},
        onAdImpression: (Ad ad) {},
      ),
    );

    try {
      await _bannerAd!.load();
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          adLoaded: false,
          isLoaded: true,
        );
      }
    }
  }

  BannerAd? get bannerAd => _bannerAd;

  void retryLoading() {
    if (!_isDisposed && !state.isLoading) {
      state = state.copyWith(retryCount: 0);
      initializeBannerAd();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }
}