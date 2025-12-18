import 'dart:async';
import 'package:Artleap.ai/shared/route_export.dart';

final bannerAdStateProvider = StateNotifierProvider<BannerAdStateNotifier, BannerAdState>((ref) {
  return BannerAdStateNotifier(ref);
});

class BannerAdState {
  final bool isExpanded;
  final bool isLoading;
  final bool adLoaded;
  final AdSize adSize;
  final int retryCount;

  BannerAdState({
    this.isExpanded = true,
    this.isLoading = false,
    this.adLoaded = false,
    AdSize? adSize,
    this.retryCount = 0,
  }) : adSize = adSize ?? AdSize.banner;

  BannerAdState copyWith({
    bool? isExpanded,
    bool? isLoading,
    bool? adLoaded,
    AdSize? adSize,
    int? retryCount,
  }) {
    return BannerAdState(
      isExpanded: isExpanded ?? this.isExpanded,
      isLoading: isLoading ?? this.isLoading,
      adLoaded: adLoaded ?? this.adLoaded,
      adSize: adSize ?? this.adSize,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class BannerAdStateNotifier extends StateNotifier<BannerAdState> {
  final Ref _ref;
  BannerAd? _bannerAd;
  bool _isDisposed = false;
  Timer? _retryTimer;

  BannerAdStateNotifier(this._ref) : super(BannerAdState());

  Future<void> initializeBannerAd() async {
    if (_isDisposed || state.isLoading || state.adLoaded) return;

    state = state.copyWith(isLoading: true);

    final showBannerAds = _ref.read(bannerAdsEnabledProvider);
    if (!showBannerAds) {
      if (!_isDisposed) {
        state = state.copyWith(isLoading: false, adLoaded: false);
      }
      return;
    }

    await _calculateAdSize();
    await _loadBannerAd();
  }

  Future<void> _calculateAdSize() async {
    try {
      final adaptiveAdSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(300);
      if (adaptiveAdSize != null && !_isDisposed) {
        state = state.copyWith(adSize: adaptiveAdSize);
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(adSize: AdSize.banner);
      }
    }
  }

  Future<void> _loadBannerAd() async {
    if (_isDisposed) return;

    final showBannerAds = _ref.read(bannerAdsEnabledProvider);
    if (!showBannerAds) {
      if (!_isDisposed) {
        state = state.copyWith(isLoading: false, adLoaded: false);
      }
      return;
    }

    final adUnitId = _ref.read(remoteConfigProvider).bannerAdUnit;

    _bannerAd?.dispose();
    _bannerAd = null;

    _bannerAd = BannerAd(
      size: state.adSize,
      adUnitId: adUnitId,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (!_isDisposed) {
            state = state.copyWith(
              isLoading: false,
              adLoaded: true,
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
              retryCount: state.retryCount + 1,
            );

            _retryTimer?.cancel();
            if (state.retryCount < 3) {
              _retryTimer = Timer(const Duration(seconds: 2), () {
                if (!_isDisposed) {
                  _loadBannerAd();
                }
              });
            }
          }
        },
        onAdOpened: (Ad ad) {},
        onAdClosed: (Ad ad) {},
        onAdImpression: (Ad ad) {},
      ),
      request: const AdRequest(),
    );

    try {
      await _bannerAd!.load();
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          adLoaded: false,
        );
      }
    }
  }

  void toggleExpand() {
    if (!_isDisposed) {
      state = state.copyWith(isExpanded: !state.isExpanded);
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