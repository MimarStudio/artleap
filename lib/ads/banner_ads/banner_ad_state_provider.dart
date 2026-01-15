import 'dart:async';
import 'dart:io';
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
  final BannerAd? bannerAd;

  BannerAdState({
    this.isLoading = false,
    this.adLoaded = false,
    AdSize? adSize,
    this.retryCount = 0,
    this.isCollapsible = false,
    this.isLoaded = false,
    this.bannerAd,
  }) : adSize = adSize ?? AdSize.banner;

  BannerAdState copyWith({
    bool? isLoading,
    bool? adLoaded,
    AdSize? adSize,
    int? retryCount,
    bool? isCollapsible,
    bool? isLoaded,
    BannerAd? bannerAd,
  }) {
    return BannerAdState(
      isLoading: isLoading ?? this.isLoading,
      adLoaded: adLoaded ?? this.adLoaded,
      adSize: adSize ?? this.adSize,
      retryCount: retryCount ?? this.retryCount,
      isCollapsible: isCollapsible ?? this.isCollapsible,
      isLoaded: isLoaded ?? this.isLoaded,
      bannerAd: bannerAd ?? this.bannerAd,
    );
  }
}

class BannerAdStateNotifier extends StateNotifier<BannerAdState> {
  final Ref _ref;
  BannerAd? _bannerAd;
  bool _isDisposed = false;
  Timer? _retryTimer;

  BannerAdStateNotifier(this._ref) : super(BannerAdState());

  void bannerLog(String msg) {
    debugPrint('📢 [BANNER_STATE] $msg');
  }


  Future<void> loadBannerAd({bool isCollapsible = false}) async {
    bannerLog('➡️ loadBannerAd() called | collapsible=$isCollapsible');

    if (_isDisposed) {
      bannerLog('⛔ blocked: notifier disposed');
      return;
    }

    if (state.isLoading) {
      bannerLog('⏳ blocked: already loading');
      return;
    }

    if (state.isLoaded) {
      bannerLog('ℹ️ blocked: already loaded');
      return;
    }

    final showBannerAds = _ref.read(bannerAdsEnabledProvider);
    bannerLog('ℹ️ bannerAdsEnabled=$showBannerAds');

    if (!showBannerAds) {
      bannerLog('⛔ blocked: RemoteConfig disabled banners');
      state = state.copyWith(
        isLoading: false,
        adLoaded: false,
        isLoaded: true,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      isCollapsible: isCollapsible,
    );

    bannerLog('📡 proceeding to load adaptive banner');
    await _loadAdaptiveBannerAd(isCollapsible: isCollapsible);
  }


  Future<void> _loadAdaptiveBannerAd({bool isCollapsible = false}) async {
    bannerLog('➡️ _loadAdaptiveBannerAd() | collapsible=$isCollapsible');

    if (_isDisposed) {
      bannerLog('⛔ disposed during adaptive load');
      return;
    }

    final showBannerAds = _ref.read(bannerAdsEnabledProvider);
    bannerLog('ℹ️ bannerAdsEnabled=$showBannerAds');

    if (!showBannerAds) {
      bannerLog('⛔ RemoteConfig disabled banners (adaptive)');
      state = state.copyWith(
        isLoading: false,
        adLoaded: false,
        isLoaded: true,
      );
      return;
    }

    final screenWidth =
    MediaQueryData.fromWindow(WidgetsBinding.instance.window)
        .size
        .width
        .truncate();

    bannerLog('📐 screenWidth=$screenWidth');

    final adaptiveAdSize =
    await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      screenWidth,
    );

    if (adaptiveAdSize == null) {
      bannerLog('🔴 adaptiveAdSize == NULL → abort');
      state = state.copyWith(
        isLoading: false,
        adLoaded: false,
        isLoaded: true,
      );
      return;
    }

    bannerLog('📐 adaptiveAdSize=$adaptiveAdSize');

    _bannerAd?.dispose();
    _bannerAd = null;

    final adUnitId = _ref.read(remoteConfigProvider).bannerAdUnit;
    bannerLog('📡 requesting banner | unit=$adUnitId');

    final adRequest = isCollapsible && !Platform.isIOS
        ? const AdRequest(extras: {'collapsible': 'bottom'})
        : const AdRequest();

    _bannerAd = BannerAd(
      size: adaptiveAdSize,
      adUnitId: adUnitId,
      request: adRequest,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          bannerLog('🟢 BANNER LOADED SUCCESSFULLY');

          if (_isDisposed) return;

          state = state.copyWith(
            isLoading: false,
            adLoaded: true,
            isLoaded: true,
            adSize: adaptiveAdSize,
            retryCount: 0,
            bannerAd: ad as BannerAd,
          );

          bannerLog('✅ state updated → adLoaded=true');

          _ref.read(centralAdManagementProvider.notifier)
              .onBannerAdLoaded(isCollapsible: isCollapsible);
        },
        onAdFailedToLoad: (Ad ad, AdError error) {
          bannerLog('🔴 BANNER FAILED | code=${error.code} | ${error.message} | ${error} ');
          ad.dispose();

          if (_isDisposed) return;

          state = state.copyWith(
            isLoading: false,
            adLoaded: false,
            isLoaded: true,
            bannerAd: null,
            retryCount: state.retryCount + 1,
          );

          if (state.retryCount < 3) {
            bannerLog('🔁 scheduling retry (${state.retryCount}/3)');
            _retryTimer?.cancel();
            _retryTimer = Timer(const Duration(seconds: 2), () {
              if (!_isDisposed) {
                _loadAdaptiveBannerAd(isCollapsible: isCollapsible);
              }
            });
          } else {
            bannerLog('⛔ retry limit reached');
          }

          _ref.read(centralAdManagementProvider.notifier)
              .onBannerAdFailed(isCollapsible: isCollapsible, error: error);
        },
        onAdOpened: (_) => bannerLog('📖 banner opened'),
        onAdClosed: (_) => bannerLog('❌ banner closed'),
        onAdImpression: (_) => bannerLog('👁️ banner impression'),
      ),
    );

    try {
      await _bannerAd!.load();
      bannerLog('📨 Banner load request SENT to SDK');
    } catch (e) {
      bannerLog('❌ EXCEPTION while loading banner: $e');
      state = state.copyWith(
        isLoading: false,
        adLoaded: false,
        isLoaded: true,
      );
    }
  }


  void disposeBanner() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _bannerAd?.dispose();
    _bannerAd = null;
    state = BannerAdState();
  }

  void retryLoading({bool isCollapsible = false}) {
    if (!_isDisposed && !state.isLoading) {
      state = state.copyWith(retryCount: 0);
      loadBannerAd(isCollapsible: isCollapsible);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    disposeBanner();
    super.dispose();
  }
}