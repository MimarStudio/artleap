import 'package:Artleap.ai/shared/route_export.dart';

final nativeAdProvider = StateNotifierProvider<NativeAdNotifier, NativeAdState>((ref) {
  return NativeAdNotifier();
});

class NativeAdState {
  final List<NativeAd> mediumNativeAds;
  final List<NativeAd> smallNativeAds;
  final List<bool> mediumAdReadyStatus;
  final List<bool> smallAdReadyStatus;
  final bool isLoadingMedium;
  final bool isLoadingSmall;
  final bool isMediumLoaded;
  final bool isSmallLoaded;
  final bool showAds;
  final int retryCount;
  final String? errorMessage;

  NativeAdState({
    List<NativeAd>? mediumNativeAds,
    List<NativeAd>? smallNativeAds,
    List<bool>? mediumAdReadyStatus,
    List<bool>? smallAdReadyStatus,
    this.isLoadingMedium = false,
    this.isLoadingSmall = false,
    this.isMediumLoaded = false,
    this.isSmallLoaded = false,
    this.showAds = true,
    this.retryCount = 0,
    this.errorMessage,
  })  : mediumNativeAds = mediumNativeAds ?? [],
        smallNativeAds = smallNativeAds ?? [],
        mediumAdReadyStatus = mediumAdReadyStatus ?? [],
        smallAdReadyStatus = smallAdReadyStatus ?? [];

  NativeAdState copyWith({
    List<NativeAd>? mediumNativeAds,
    List<NativeAd>? smallNativeAds,
    List<bool>? mediumAdReadyStatus,
    List<bool>? smallAdReadyStatus,
    bool? isLoadingMedium,
    bool? isLoadingSmall,
    bool? isMediumLoaded,
    bool? isSmallLoaded,
    bool? showAds,
    int? retryCount,
    String? errorMessage,
  }) {
    return NativeAdState(
      mediumNativeAds: mediumNativeAds ?? this.mediumNativeAds,
      smallNativeAds: smallNativeAds ?? this.smallNativeAds,
      mediumAdReadyStatus: mediumAdReadyStatus ?? this.mediumAdReadyStatus,
      smallAdReadyStatus: smallAdReadyStatus ?? this.smallAdReadyStatus,
      isLoadingMedium: isLoadingMedium ?? this.isLoadingMedium,
      isLoadingSmall: isLoadingSmall ?? this.isLoadingSmall,
      isMediumLoaded: isMediumLoaded ?? this.isMediumLoaded,
      isSmallLoaded: isSmallLoaded ?? this.isSmallLoaded,
      showAds: showAds ?? this.showAds,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage,
    );
  }
}

class NativeAdNotifier extends StateNotifier<NativeAdState> {
  NativeAdNotifier() : super(NativeAdState());

  Future<void> loadSmallNativeAds() async {
    await _loadSmallAds(1);
  }

  Future<void> loadMediumNativeAds() async {
    await _loadMediumAds(1);
  }

  Future<void> loadMultipleNativeAds() async {
    await _loadMediumAds(5);
  }

  Future<void> preloadInitialMediumAds() async {
    if (state.mediumNativeAds.isEmpty) {
      await loadMoreMediumAds(5);
    }
  }


  Future<void> _loadSmallAds(int adCount) async {
    final config = RemoteConfigService.instance;

    if (!config.showNativeAds) {
      state = state.copyWith(showAds: false);
      return;
    }

    if (state.isLoadingSmall) return;

    for (var ad in state.smallNativeAds) {
      ad.dispose();
    }

    final List<NativeAd?> ads = List.filled(adCount, null);
    final List<bool> ready = List.filled(adCount, false);

    state = state.copyWith(
      smallNativeAds: [],
      smallAdReadyStatus: [],
      isLoadingSmall: true,
      isSmallLoaded: false,
    );

    int completed = 0;

    for (int i = 0; i < adCount; i++) {
      final index = i;

      final ad = NativeAd(
        adUnitId: config.nativeAdUnit,
        request: const AdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.small,
          cornerRadius: 8,
        ),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            ads[index] = ad as NativeAd;
            ready[index] = true;
            completed++;
            _updateSmallAdFinalStateIfDone(ads, ready, completed, adCount);
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            completed++;
            _updateSmallAdFinalStateIfDone(ads, ready, completed, adCount);
          },
        ),
      );

      await ad.load();
    }
  }

  Future<void> _loadMediumAds(int adCount) async {
    final config = RemoteConfigService.instance;

    if (!config.showNativeAds) {
      state = state.copyWith(showAds: false);
      return;
    }

    if (state.isLoadingMedium) return;

    for (var ad in state.mediumNativeAds) {
      ad.dispose();
    }

    final List<NativeAd?> ads = List.filled(adCount, null);
    final List<bool> ready = List.filled(adCount, false);

    state = state.copyWith(
      mediumNativeAds: [],
      mediumAdReadyStatus: [],
      isLoadingMedium: true,
      isMediumLoaded: false,
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
            _updateMediumAdFinalStateIfDone(ads, ready, completed, adCount);
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            completed++;
            _updateMediumAdFinalStateIfDone(ads, ready, completed, adCount);
          },
        ),
      );

      await ad.load();
    }
  }

  Future<void> loadMoreMediumAds(int count) async {
    final config = RemoteConfigService.instance;

    if (!config.showNativeAds || state.isLoadingMedium) return;

    state = state.copyWith(isLoadingMedium: true);

    final List<NativeAd> newAds = [];
    final List<bool> ready = [];

    int completed = 0;

    for (int i = 0; i < count; i++) {
      final ad = NativeAd(
        adUnitId: config.nativeAdUnit,
        request: const AdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
          cornerRadius: 12,
        ),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            newAds.add(ad as NativeAd);
            ready.add(true);
            completed++;

            if (completed == count) {
              state = state.copyWith(
                mediumNativeAds: [...state.mediumNativeAds, ...newAds],
                mediumAdReadyStatus: [
                  ...state.mediumAdReadyStatus,
                  ...ready
                ],
                isLoadingMedium: false,
                isMediumLoaded: true,
              );
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            completed++;

            if (completed == count) {
              state = state.copyWith(isLoadingMedium: false);
            }
          },
        ),
      );

      ad.load();
    }
  }

  void _updateSmallAdFinalStateIfDone(
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
      smallNativeAds: loadedAds,
      smallAdReadyStatus: readyStatus,
      isLoadingSmall: false,
      isSmallLoaded: loadedAds.isNotEmpty,
    );
  }

  void _updateMediumAdFinalStateIfDone(
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
      mediumNativeAds: loadedAds,
      mediumAdReadyStatus: readyStatus,
      isLoadingMedium: false,
      isMediumLoaded: loadedAds.isNotEmpty,
    );
  }

  bool isSmallAdReady(int index) {
    if (index >= 0 &&
        index < state.smallNativeAds.length &&
        index < state.smallAdReadyStatus.length) {
      return state.smallAdReadyStatus[index];
    }
    return false;
  }

  bool isMediumAdReady(int index) =>
      index < state.mediumAdReadyStatus.length &&
          state.mediumAdReadyStatus[index];

  Future<void> loadInitialAd() async {
    final config = RemoteConfigService.instance;

    if (!config.showNativeAds) {
      state = state.copyWith(showAds: false);
      return;
    }

    if (state.isLoadingMedium) return;

    if (!AdService.instance.isInitialized) {
      await AdService.instance.initialize();
    }

    state = state.copyWith(isLoadingMedium: true, errorMessage: null);

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
            mediumNativeAds: [ad as NativeAd],
            mediumAdReadyStatus: [true],
            isLoadingMedium: false,
            isMediumLoaded: true,
            retryCount: 0,
            errorMessage: null,
          );
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          state = state.copyWith(
            mediumNativeAds: [],
            mediumAdReadyStatus: [],
            isLoadingMedium: false,
            isMediumLoaded: false,
            retryCount: state.retryCount + 1,
            errorMessage: error.message,
          );
        },
      ),
    );

    ad.load();
  }

  void disposeAllAds() {
    for (var ad in state.smallNativeAds) {
      ad.dispose();
    }
    for (var ad in state.mediumNativeAds) {
      ad.dispose();
    }
    state = NativeAdState();
  }

  void disposeSmallAds() {
    for (var ad in state.smallNativeAds) {
      ad.dispose();
    }
    state = state.copyWith(
      smallNativeAds: [],
      smallAdReadyStatus: [],
      isSmallLoaded: false,
      isLoadingSmall: false,
    );
  }

  void disposeMediumAds() {
    for (var ad in state.mediumNativeAds) {
      ad.dispose();
    }
    state = state.copyWith(
      mediumNativeAds: [],
      mediumAdReadyStatus: [],
      isMediumLoaded: false,
      isLoadingMedium: false,
    );
  }


  void safeDisposeAds() {
    for (var ad in state.smallNativeAds) {
      ad.dispose();
    }
    for (var ad in state.mediumNativeAds) {
      ad.dispose();
    }
  }

  @override
  void dispose() {
    disposeAllAds();
    super.dispose();
  }
}