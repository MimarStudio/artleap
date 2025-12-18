import 'package:Artleap.ai/shared/route_export.dart';

final nativeAdProvider =
StateNotifierProvider<NativeAdNotifier, NativeAdState>((ref) {
  return NativeAdNotifier();
});

class NativeAdState {
  final List<NativeAd> nativeAds;
  final List<bool> adReadyStatus; // Track which ads are actually ready
  final bool isLoading;
  final bool isLoaded;
  final bool showAds;
  final int retryCount;
  final String? errorMessage;

  NativeAdState({
    List<NativeAd>? nativeAds,
    List<bool>? adReadyStatus,
    this.isLoading = false,
    this.isLoaded = false,
    this.showAds = true,
    this.retryCount = 0,
    this.errorMessage,
  })  : nativeAds = nativeAds ?? [],
        adReadyStatus = adReadyStatus ?? [];

  NativeAdState copyWith({
    List<NativeAd>? nativeAds,
    List<bool>? adReadyStatus,
    bool? isLoading,
    bool? isLoaded,
    bool? showAds,
    int? retryCount,
    String? errorMessage,
  }) {
    return NativeAdState(
      nativeAds: nativeAds ?? this.nativeAds,
      adReadyStatus: adReadyStatus ?? this.adReadyStatus,
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      showAds: showAds ?? this.showAds,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage,
    );
  }
}

class NativeAdNotifier extends StateNotifier<NativeAdState> {
  NativeAdNotifier() : super(NativeAdState());

  Future<void> loadMultipleAds() async {
    final config = RemoteConfigService.instance;

    if (!config.showNativeAds) {
      state = state.copyWith(showAds: false);
      return;
    }

    if (state.isLoading) return;

    // Dispose old ads
    for (var ad in state.nativeAds) {
      ad.dispose();
    }

    const int adCount = 5;

    // Pre-fill lists
    final List<NativeAd?> ads = List.filled(adCount, null);
    final List<bool> ready = List.filled(adCount, false);

    state = state.copyWith(
      nativeAds: [],
      adReadyStatus: [],
      isLoading: true,
      isLoaded: false,
    );

    int completed = 0;

    for (int i = 0; i < adCount; i++) {
      final index = i;

      final ad = NativeAd(
        adUnitId: config.nativeAdUnit,
        request: const AdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
          cornerRadius: 12,
        ),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            ads[index] = ad as NativeAd;
            ready[index] = true;
            completed++;

            _updateFinalStateIfDone(ads, ready, completed, adCount);
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            completed++;

            _updateFinalStateIfDone(ads, ready, completed, adCount);
          },
        ),
      );

      await ad.load();
    }
  }

  void _updateFinalStateIfDone(
      List<NativeAd?> ads,
      List<bool> ready,
      int completed,
      int adCount,
      ) {
    if (completed < adCount) return;

    final loadedAds = <NativeAd>[];
    final readyStatus = <bool>[];

    for (int i = 0; i < ads.length; i++) {
      if (ads[i] != null && ready[i]) {
        loadedAds.add(ads[i]!);
        readyStatus.add(true);
      }
    }

    state = state.copyWith(
      nativeAds: loadedAds,
      adReadyStatus: readyStatus,
      isLoading: false,
      isLoaded: loadedAds.isNotEmpty,
    );
  }


  // Check if a specific ad is ready to be displayed
  bool isAdReady(int index) {
    if (index >= 0 &&
        index < state.nativeAds.length &&
        index < state.adReadyStatus.length) {
      return state.adReadyStatus[index];
    }
    return false;
  }

  Future<void> loadInitialAd() async {
    final config = RemoteConfigService.instance;

    if (!config.showNativeAds) {
      state = state.copyWith(showAds: false);
      return;
    }

    if (state.isLoading || state.isLoaded) return;

    if (!AdService.instance.isInitialized) {
      await AdService.instance.initialize();
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final ad = NativeAd(
      adUnitId: config.nativeAdUnit,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        cornerRadius: 12,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          state = state.copyWith(
            nativeAds: [ad as NativeAd],
            adReadyStatus: [true],
            isLoading: false,
            isLoaded: true,
            retryCount: 0,
            errorMessage: null,
          );
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          state = state.copyWith(
            nativeAds: [],
            adReadyStatus: [],
            isLoading: false,
            isLoaded: false,
            retryCount: state.retryCount + 1,
            errorMessage: error.message,
          );
        },
      ),
    );

    ad.load();
  }

  Future<void> loadNativeAd() async {
    final config = RemoteConfigService.instance;

    if (!config.showNativeAds) {
      state = state.copyWith(showAds: false);
      return;
    }

    if (state.isLoading) return;

    for (var ad in state.nativeAds) {
      ad.dispose();
    }

    state = state.copyWith(
      nativeAds: [],
      adReadyStatus: [],
      isLoading: true,
      isLoaded: false,
      errorMessage: null,
    );

    final ad = NativeAd(
      adUnitId: config.nativeAdUnit,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        cornerRadius: 12,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          state = state.copyWith(
            nativeAds: [ad as NativeAd],
            adReadyStatus: [true],
            isLoading: false,
            isLoaded: true,
            retryCount: 0,
            errorMessage: null,
          );
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          state = state.copyWith(
            nativeAds: [],
            adReadyStatus: [],
            isLoading: false,
            isLoaded: false,
            retryCount: state.retryCount + 1,
            errorMessage: error.message,
          );
        },
      ),
    );

    await ad.load();
  }

  void disposeAd() {
    for (var ad in state.nativeAds) {
      ad.dispose();
    }
    state = state.copyWith(
        nativeAds: [],
        adReadyStatus: [],
        isLoaded: false,
        isLoading: false
    );
  }

  void safeDisposeAds() {
    for (var ad in state.nativeAds) {
      ad.dispose();
    }
  }

  @override
  void dispose() {
    for (var ad in state.nativeAds) {
      ad.dispose();
    }
    super.dispose();
  }
}