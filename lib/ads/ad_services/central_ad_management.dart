import 'dart:async';
import 'package:Artleap.ai/shared/route_export.dart';

final centralAdManagementProvider = StateNotifierProvider<CentralAdManagementNotifier, CentralAdManagementState>((ref) {
  return CentralAdManagementNotifier(ref);
});

class CentralAdManagementState {
  final bool isInitialized;
  final Map<String, bool> adLoadStatus;
  final Map<String, DateTime?> lastAdRequestTime;
  final DateTime? lastAdShownTime;
  final bool isShowingAd;
  final Map<String, int> adRequestCount;

  CentralAdManagementState({
    this.isInitialized = false,
    Map<String, bool>? adLoadStatus,
    Map<String, DateTime?>? lastAdRequestTime,
    this.lastAdShownTime,
    this.isShowingAd = false,
    Map<String, int>? adRequestCount,
  })  : adLoadStatus = adLoadStatus ?? {
    'appOpen': false,
    'interstitial': false,
    'rewarded': false,
    'native': false,
    'smallNative': false,
    'banner': false,
    'collapsibleBanner': false,
  },
        lastAdRequestTime = lastAdRequestTime ?? {
          'appOpen': null,
          'interstitial': null,
          'rewarded': null,
          'native': null,
          'smallNative': null,
          'banner': null,
          'collapsibleBanner': null,
        },
        adRequestCount = adRequestCount ?? {
          'appOpen': 0,
          'interstitial': 0,
          'rewarded': 0,
          'native': 0,
          'smallNative': 0,
          'banner': 0,
          'collapsibleBanner': 0,
        };

  CentralAdManagementState copyWith({
    bool? isInitialized,
    Map<String, bool>? adLoadStatus,
    Map<String, DateTime?>? lastAdRequestTime,
    DateTime? lastAdShownTime,
    bool? isShowingAd,
    Map<String, int>? adRequestCount,
  }) {
    return CentralAdManagementState(
      isInitialized: isInitialized ?? this.isInitialized,
      adLoadStatus: adLoadStatus ?? this.adLoadStatus,
      lastAdRequestTime: lastAdRequestTime ?? this.lastAdRequestTime,
      lastAdShownTime: lastAdShownTime ?? this.lastAdShownTime,
      isShowingAd: isShowingAd ?? this.isShowingAd,
      adRequestCount: adRequestCount ?? this.adRequestCount,
    );
  }
}

class CentralAdManagementNotifier extends StateNotifier<CentralAdManagementState> {
  final Ref ref;
  bool _isDisposed = false;
  AppOpenAdManager? _appOpenAdManager;
  Timer? _adRefreshTimer;
  WidgetRef? _cachedWidgetRef;

  CentralAdManagementNotifier(this.ref) : super(CentralAdManagementState()) {
  }

  void setWidgetRef(WidgetRef widgetRef) {
    if (!_isDisposed) {
      _cachedWidgetRef = widgetRef;
      if (!state.isInitialized) {
        _initialize();
      }
    }
  }

  Future<void> _initialize() async {
    if (_isDisposed) return;

    try {
      await ref.read(adServiceProvider).initialize();
      await _preloadEssentialAds();

      if (!_isDisposed) {
        state = state.copyWith(isInitialized: true);
      }
    } catch (e) {
      Future.delayed(Duration(seconds: 5), () {
        if (!_isDisposed) {
          _initialize();
        }
      });
    }
  }

  void _startAdRefreshTimer() {
    _adRefreshTimer = Timer.periodic(Duration(minutes: 5), (_) {
      if (!_isDisposed) {
        _refreshExpiredAds();
      }
    });
  }

  void _refreshExpiredAds() {
    final now = DateTime.now();
    final newStatus = Map<String, bool>.from(state.adLoadStatus);
    final newRequestTimes = Map<String, DateTime?>.from(state.lastAdRequestTime);

    bool shouldRefresh = false;

    for (var entry in state.adLoadStatus.entries) {
      if (entry.value) {
        final lastRequestTime = state.lastAdRequestTime[entry.key];
        if (lastRequestTime != null && now.difference(lastRequestTime).inMinutes > 30) {
          newStatus[entry.key] = false;
          newRequestTimes[entry.key] = null;
          shouldRefresh = true;
        }
      }
    }

    if (shouldRefresh && !_isDisposed) {
      state = state.copyWith(
        adLoadStatus: newStatus,
        lastAdRequestTime: newRequestTimes,
      );
      _preloadEssentialAds();
    }
  }

  Future<void> _preloadEssentialAds() async {
    if (_isDisposed) return;

    try {
      await Future.wait([
        loadAppOpenAd(),
        loadInterstitialAd(),
        loadSmallNativeAds(),
        loadCollapsibleBannerAd(),
      ]);
    } catch (e) {
    }
  }

  Future<void> loadAppOpenAd() async {
    if (_isDisposed || !_shouldLoadAd('appOpen') || _cachedWidgetRef == null) return;

    try {
      _appOpenAdManager = _cachedWidgetRef!.read(appOpenAdProvider);
      await _appOpenAdManager!.loadAppOpenAd(_cachedWidgetRef!);

      if (!_isDisposed) {
        final newStatus = Map<String, bool>.from(state.adLoadStatus);
        final newRequestTimes = Map<String, DateTime?>.from(state.lastAdRequestTime);
        final newRequestCount = Map<String, int>.from(state.adRequestCount);

        newStatus['appOpen'] = true;
        newRequestTimes['appOpen'] = DateTime.now();
        newRequestCount['appOpen'] = (newRequestCount['appOpen'] ?? 0) + 1;

        state = state.copyWith(
          adLoadStatus: newStatus,
          lastAdRequestTime: newRequestTimes,
          adRequestCount: newRequestCount,
        );
      }
    } catch (e) {
      _scheduleRetry('appOpen');
    }
  }

  Future<void> loadInterstitialAd() async {
    if (_isDisposed || !_shouldLoadAd('interstitial') || _cachedWidgetRef == null) return;

    try {
      await _cachedWidgetRef!.read(interstitialAdStateProvider.notifier).loadInterstitialAd();

      if (!_isDisposed) {
        final newStatus = Map<String, bool>.from(state.adLoadStatus);
        final newRequestTimes = Map<String, DateTime?>.from(state.lastAdRequestTime);
        final newRequestCount = Map<String, int>.from(state.adRequestCount);

        newStatus['interstitial'] = true;
        newRequestTimes['interstitial'] = DateTime.now();
        newRequestCount['interstitial'] = (newRequestCount['interstitial'] ?? 0) + 1;

        state = state.copyWith(
          adLoadStatus: newStatus,
          lastAdRequestTime: newRequestTimes,
          adRequestCount: newRequestCount,
        );
      }
    } catch (e) {
      _scheduleRetry('interstitial');
    }
  }

  Future<void> loadSmallNativeAds() async {
    if (_isDisposed || !_shouldLoadAd('smallNative') || _cachedWidgetRef == null) return;

    try {
      await _cachedWidgetRef!.read(nativeAdProvider.notifier).loadSmallNativeAds();

      if (!_isDisposed) {
        final newStatus = Map<String, bool>.from(state.adLoadStatus);
        final newRequestTimes = Map<String, DateTime?>.from(state.lastAdRequestTime);
        final newRequestCount = Map<String, int>.from(state.adRequestCount);

        newStatus['smallNative'] = true;
        newRequestTimes['smallNative'] = DateTime.now();
        newRequestCount['smallNative'] = (newRequestCount['smallNative'] ?? 0) + 1;

        state = state.copyWith(
          adLoadStatus: newStatus,
          lastAdRequestTime: newRequestTimes,
          adRequestCount: newRequestCount,
        );
      }
    } catch (e) {
      _scheduleRetry('smallNative');
    }
  }

  Future<void> loadMediumNativeAds() async {
    if (_isDisposed || !_shouldLoadAd('native') || _cachedWidgetRef == null) return;

    try {
      await _cachedWidgetRef!.read(nativeAdProvider.notifier).loadMediumNativeAds();

      if (!_isDisposed) {
        final newStatus = Map<String, bool>.from(state.adLoadStatus);
        final newRequestTimes = Map<String, DateTime?>.from(state.lastAdRequestTime);
        final newRequestCount = Map<String, int>.from(state.adRequestCount);

        newStatus['native'] = true;
        newRequestTimes['native'] = DateTime.now();
        newRequestCount['native'] = (newRequestCount['native'] ?? 0) + 1;

        state = state.copyWith(
          adLoadStatus: newStatus,
          lastAdRequestTime: newRequestTimes,
          adRequestCount: newRequestCount,
        );
      }
    } catch (e) {
      _scheduleRetry('native');
    }
  }

  Future<void> loadBannerAd({bool forceReload = false}) async {
    if (_isDisposed) return;
    if (_cachedWidgetRef == null) {
      return;
    }

    try {
      final currentBannerState = _cachedWidgetRef!.read(bannerAdStateProvider);
      final shouldLoad = forceReload || !currentBannerState.isLoaded || !currentBannerState.adLoaded;

      if (!shouldLoad) {
        return;
      }

      if (currentBannerState.isLoaded) {
        _cachedWidgetRef!.read(bannerAdStateProvider.notifier).dispose();
      }

      await _cachedWidgetRef!.read(bannerAdStateProvider.notifier).initializeBannerAd(
        isCollapsible: false,
      );

      if (!_isDisposed) {
        final newStatus = Map<String, bool>.from(state.adLoadStatus);
        final newRequestTimes = Map<String, DateTime?>.from(state.lastAdRequestTime);
        final newRequestCount = Map<String, int>.from(state.adRequestCount);

        newStatus['banner'] = true;
        newRequestTimes['banner'] = DateTime.now();
        newRequestCount['banner'] = (newRequestCount['banner'] ?? 0) + 1;

        state = state.copyWith(
          adLoadStatus: newStatus,
          lastAdRequestTime: newRequestTimes,
          adRequestCount: newRequestCount,
        );
      }
    } catch (e) {
      _scheduleRetry('banner');
    }
  }

  Future<void> loadCollapsibleBannerAd({bool forceReload = false}) async {
    if (_isDisposed) return;
    if (_cachedWidgetRef == null) {
      return;
    }

    try {
      final currentBannerState = _cachedWidgetRef!.read(bannerAdStateProvider);
      final shouldLoad = forceReload || !currentBannerState.isLoaded || !currentBannerState.adLoaded || !currentBannerState.isCollapsible;

      if (!shouldLoad) {
        return;
      }

      if (currentBannerState.isLoaded) {
        _cachedWidgetRef!.read(bannerAdStateProvider.notifier).dispose();
      }

      await _cachedWidgetRef!.read(bannerAdStateProvider.notifier).initializeBannerAd(
        isCollapsible: true,
      );

      if (!_isDisposed) {
        final newStatus = Map<String, bool>.from(state.adLoadStatus);
        final newRequestTimes = Map<String, DateTime?>.from(state.lastAdRequestTime);
        final newRequestCount = Map<String, int>.from(state.adRequestCount);

        newStatus['collapsibleBanner'] = true;
        newRequestTimes['collapsibleBanner'] = DateTime.now();
        newRequestCount['collapsibleBanner'] = (newRequestCount['collapsibleBanner'] ?? 0) + 1;

        state = state.copyWith(
          adLoadStatus: newStatus,
          lastAdRequestTime: newRequestTimes,
          adRequestCount: newRequestCount,
        );
      }
    } catch (e) {
      _scheduleRetry('collapsibleBanner');
    }
  }

  Future<void> loadRewardedAd() async {
    if (_isDisposed || !_shouldLoadAd('rewarded') || _cachedWidgetRef == null) return;

    try {
      await AdHelper.preloadRewardedAd(_cachedWidgetRef!);

      if (!_isDisposed) {
        final newStatus = Map<String, bool>.from(state.adLoadStatus);
        final newRequestTimes = Map<String, DateTime?>.from(state.lastAdRequestTime);
        final newRequestCount = Map<String, int>.from(state.adRequestCount);

        newStatus['rewarded'] = true;
        newRequestTimes['rewarded'] = DateTime.now();
        newRequestCount['rewarded'] = (newRequestCount['rewarded'] ?? 0) + 1;

        state = state.copyWith(
          adLoadStatus: newStatus,
          lastAdRequestTime: newRequestTimes,
          adRequestCount: newRequestCount,
        );
      }
    } catch (e) {
      _scheduleRetry('rewarded');
    }
  }

  Future<bool> showAppOpenAd() async {
    if (_isDisposed || _appOpenAdManager == null || _cachedWidgetRef == null) {
      return false;
    }

    try {
      if (!_canShowAd()) {
        return false;
      }

      state = state.copyWith(isShowingAd: true);
      final result = await _appOpenAdManager!.showAppOpenAd(_cachedWidgetRef!);

      if (result) {
        state = state.copyWith(
          isShowingAd: false,
          lastAdShownTime: DateTime.now(),
        );
        _markAdAsUsed('appOpen');
        Future.delayed(Duration(seconds: 1), () => loadAppOpenAd());
      } else {
        state = state.copyWith(isShowingAd: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isShowingAd: false);
      return false;
    }
  }

  Future<bool> showInterstitialAd() async {
    if (_isDisposed || _cachedWidgetRef == null) {
      return false;
    }

    try {
      if (!_canShowAd()) {
        return false;
      }

      state = state.copyWith(isShowingAd: true);

      final interstitialNotifier = _cachedWidgetRef!.read(interstitialAdStateProvider.notifier);
      final interstitialState = _cachedWidgetRef!.read(interstitialAdStateProvider);
      final isLoaded = interstitialState.isLoaded;

      if (!isLoaded) {
        state = state.copyWith(isShowingAd: false);
        return false;
      }

      final result = await interstitialNotifier.showInterstitialAd();

      if (result) {
        state = state.copyWith(
          isShowingAd: false,
          lastAdShownTime: DateTime.now(),
        );
        _markAdAsUsed('interstitial');
        Future.delayed(Duration(seconds: 1), () => loadInterstitialAd());
      } else {
        state = state.copyWith(isShowingAd: false);
        Future.delayed(Duration(seconds: 1), () => loadInterstitialAd());
      }

      return result;
    } catch (e) {
      state = state.copyWith(isShowingAd: false);
      Future.delayed(Duration(seconds: 1), () => loadInterstitialAd());
      return false;
    }
  }

  Future<bool> showRewardedAd({
    required Function(int) onRewardEarned,
    Function()? onAdDismissed,
    Function()? onAdFailed,
  }) async {
    if (_isDisposed || _cachedWidgetRef == null) {
      return false;
    }

    try {
      if (!_canShowAd()) {
        return false;
      }

      state = state.copyWith(isShowingAd: true);

      final result = await AdHelper.showRewardedAd(
        ref: _cachedWidgetRef!,
        onRewardEarned: onRewardEarned,
        onAdDismissed: () {
          state = state.copyWith(
            isShowingAd: false,
            lastAdShownTime: DateTime.now(),
          );
          _markAdAsUsed('rewarded');
          Future.delayed(Duration(seconds: 1), () => loadRewardedAd());
          onAdDismissed?.call();
        },
        onAdFailed: () {
          state = state.copyWith(isShowingAd: false);
          Future.delayed(Duration(seconds: 1), () => loadRewardedAd());
          onAdFailed?.call();
        },
      );

      return result;
    } catch (e) {
      state = state.copyWith(isShowingAd: false);
      return false;
    }
  }

  Future<void> forceReloadBanner({bool isCollapsible = false}) async {
    if (_isDisposed) return;
    if (isCollapsible) {
      _markAdAsUsed('collapsibleBanner');
      await loadCollapsibleBannerAd();
    } else {
      _markAdAsUsed('banner');
      await loadBannerAd();
    }
  }

  void _markAdAsUsed(String adType) {
    if (_isDisposed) return;

    final newStatus = Map<String, bool>.from(state.adLoadStatus);
    final newRequestTimes = Map<String, DateTime?>.from(state.lastAdRequestTime);

    newStatus[adType] = false;
    newRequestTimes[adType] = null;

    state = state.copyWith(
      adLoadStatus: newStatus,
      lastAdRequestTime: newRequestTimes,
    );
  }

  void reloadAd(String adType, {bool isCollapsible = false}) {
    if (_isDisposed) return;

    _markAdAsUsed(adType);

    switch (adType) {
      case 'appOpen':
        loadAppOpenAd();
        break;
      case 'interstitial':
        loadInterstitialAd();
        break;
      case 'smallNative':
        loadSmallNativeAds();
        break;
      case 'native':
        loadMediumNativeAds();
        break;
      case 'banner':
        loadBannerAd();
        break;
      case 'collapsibleBanner':
        loadCollapsibleBannerAd();
        break;
      case 'rewarded':
        loadRewardedAd();
        break;
    }
  }

  void reloadAllAds() {
    if (_isDisposed) return;

    final newStatus = Map<String, bool>.from(state.adLoadStatus);
    final newRequestTimes = Map<String, DateTime?>.from(state.lastAdRequestTime);

    for (var key in newStatus.keys) {
      newStatus[key] = false;
      newRequestTimes[key] = null;
    }

    state = state.copyWith(
      adLoadStatus: newStatus,
      lastAdRequestTime: newRequestTimes,
    );

    _preloadEssentialAds();
  }

  bool _shouldLoadAd(String adType) {
    final showAds = _getAdEnabledStatus(adType);
    final isAlreadyLoaded = state.adLoadStatus[adType] ?? false;
    final lastRequestTime = state.lastAdRequestTime[adType];

    if (!showAds) {
      return false;
    }

    if (isAlreadyLoaded) {
      return false;
    }

    if (lastRequestTime != null) {
      final secondsSinceLastRequest = DateTime.now().difference(lastRequestTime).inSeconds;
      if (secondsSinceLastRequest < 10) {
        return false;
      }
    }

    return true;
  }

  void _scheduleRetry(String adType) {
    Future.delayed(Duration(seconds: 30), () {
      if (!_isDisposed) {
        reloadAd(adType);
      }
    });
  }

  bool _canShowAd() {
    if (state.isShowingAd) {
      return false;
    }

    if (state.lastAdShownTime != null) {
      final secondsSinceLastAd = DateTime.now().difference(state.lastAdShownTime!).inSeconds;
      if (secondsSinceLastAd < 10) {
        return false;
      }
    }

    return true;
  }

  bool canShowAd() {
    return _canShowAd();
  }

  bool _getAdEnabledStatus(String adType) {
    if (_cachedWidgetRef == null) {
      return false;
    }

    try {
      final config = _cachedWidgetRef!.read(remoteConfigProvider);

      bool enabled = false;
      switch (adType) {
        case 'appOpen':
          enabled = config.showAppOpenAds;
          break;
        case 'interstitial':
          enabled = config.showInterstitialAds;
          break;
        case 'native':
        case 'smallNative':
          enabled = config.showNativeAds;
          break;
        case 'banner':
        case 'collapsibleBanner':
          enabled = config.showBannerAds;
          break;
        case 'rewarded':
          enabled = config.showRewardedAds;
          break;
        default:
          enabled = true;
      }

      return enabled;
    } catch (e) {
      return false;
    }
  }

  bool isAdLoaded(String adType) {
    return state.adLoadStatus[adType] ?? false;
  }

  bool isBannerCollapsible() {
    if (_cachedWidgetRef == null) {
      return false;
    }
    final bannerState = _cachedWidgetRef!.read(bannerAdStateProvider);
    return bannerState.isCollapsible && bannerState.isLoaded && bannerState.adLoaded;
  }

  int getAdRequestCount(String adType) {
    return state.adRequestCount[adType] ?? 0;
  }

  void resetAdRequestCount(String adType) {
    if (_isDisposed) return;

    final newRequestCount = Map<String, int>.from(state.adRequestCount);
    newRequestCount[adType] = 0;

    state = state.copyWith(adRequestCount: newRequestCount);
  }

  @override
  @override
  void dispose() {
    _isDisposed = true;
    _adRefreshTimer?.cancel();
    _appOpenAdManager?.dispose();
    if (_cachedWidgetRef != null) {
      try {
        _cachedWidgetRef!.read(interstitialAdStateProvider.notifier).disposeAd();
        _cachedWidgetRef!.read(nativeAdProvider.notifier).disposeAllAds();
      } catch (e) {
      }
    }
    try {
      ref.read(bannerAdStateProvider.notifier).dispose();
    } catch (e) {
    }

    super.dispose();
  }
}

class CentralAdWrapper extends ConsumerWidget {
  final Widget child;

  const CentralAdWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(centralAdManagementProvider.notifier).setWidgetRef(ref);
    final adState = ref.watch(centralAdManagementProvider);
    return child;
  }

}