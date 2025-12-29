import 'package:Artleap.ai/shared/route_export.dart';

final interstitialAdStateProvider = StateNotifierProvider<InterstitialAdNotifier, InterstitialAdState>((ref) {
  return InterstitialAdNotifier(ref);
});

class InterstitialAdState {
  final bool isLoading;
  final bool isLoaded;
  final bool isShowing;
  final String? error;
  final DateTime? lastShownTime;
  final int retryCount;

  InterstitialAdState({
    this.isLoading = false,
    this.isLoaded = false,
    this.isShowing = false,
    this.error,
    this.lastShownTime,
    this.retryCount = 0,
  });

  InterstitialAdState copyWith({
    bool? isLoading,
    bool? isLoaded,
    bool? isShowing,
    String? error,
    DateTime? lastShownTime,
    int? retryCount,
  }) {
    return InterstitialAdState(
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      isShowing: isShowing ?? this.isShowing,
      error: error ?? this.error,
      lastShownTime: lastShownTime ?? this.lastShownTime,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class InterstitialAdNotifier extends StateNotifier<InterstitialAdState> {
  final Ref ref;
  InterstitialAd? _interstitialAd;

  InterstitialAdNotifier(this.ref) : super(InterstitialAdState());

  Future<void> loadInterstitialAd() async {
    final showAds = ref.read(interstitialAdsEnabledProvider);
    if (!showAds) return;

    final maxRetryCount = ref.read(remoteConfigProvider).maxAdRetryCount;
    if (state.retryCount >= maxRetryCount) {
      state = state.copyWith(retryCount: 0);
      return;
    }

    if (_interstitialAd != null || state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    final adUnitId = ref.read(remoteConfigProvider).interstitialAdUnit;

    try {
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _setupAdCallbacks(ad);
            _interstitialAd = ad;
            state = state.copyWith(
              isLoading: false,
              isLoaded: true,
              retryCount: 0,
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            state = state.copyWith(
              isLoading: false,
              error: 'Failed to load ad: $error',
              retryCount: state.retryCount + 1,
            );
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Exception: $e',
        retryCount: state.retryCount + 1,
      );
      _interstitialAd = null;
    }
  }

  void _setupAdCallbacks(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        state = state.copyWith(isShowing: true);
        ref.read(isFullscreenAdShowingProvider.notifier).state = true;
        AppOpenAdManager.instance.disableForSession();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        state = state.copyWith(isShowing: false, error: 'Failed to show: $err');
        AppOpenAdManager.instance.enableForSession();
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        state = state.copyWith(
          isShowing: false,
          isLoaded: false,
          lastShownTime: DateTime.now(),
        );
        ref.read(isFullscreenAdShowingProvider.notifier).state = false;
        AppOpenAdManager.instance.enableForSession();
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
      },
      onAdImpression: (ad) {
      },
      onAdClicked: (ad) {
      },
    );
  }

  Future<bool> showInterstitialAd() async {
    final showAds = ref.read(interstitialAdsEnabledProvider);
    if (!showAds) return false;

    if (_interstitialAd == null) {
      await loadInterstitialAd();
      return false;
    }

    final now = DateTime.now();
    if (state.lastShownTime != null) {
      final secondsSinceLastAd = now.difference(state.lastShownTime!).inSeconds;
      final interval = ref.read(interstitialIntervalProvider);
      if (secondsSinceLastAd < interval) {
        return false;
      }
    }

    try {
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to show ad: $e');
      _interstitialAd = null;
      loadInterstitialAd();
      return false;
    }
  }

  void disposeAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    state = state.copyWith(
      isLoaded: false,
      isShowing: false,
      isLoading: false,
    );
    AppOpenAdManager.instance.enableForSession();
  }

  @override
  void dispose() {
    disposeAd();
    super.dispose();
  }
}