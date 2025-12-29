import 'dart:async';
import 'package:Artleap.ai/shared/route_export.dart';

class AppOpenAdManager {
  static AppOpenAdManager? _instance;
  static AppOpenAdManager get instance {
    _instance ??= AppOpenAdManager._();
    return _instance!;
  }

  AppOpenAdManager._();

  AppOpenAd? _appOpenAd;
  bool _isLoading = false;
  bool _isAdLoaded = false;
  DateTime? _lastShownTime;
  int _retryCount = 0;
  bool _canShowAd = true;
  bool _isDisposed = false;
  Completer<void>? _loadCompleter;

  Future<void> loadAppOpenAd(WidgetRef ref) async {
    if (_isDisposed) return;

    if (_loadCompleter != null) {
      return _loadCompleter!.future;
    }

    _loadCompleter = Completer<void>();

    try {
      if (!AdService.instance.isInitialized) {
        await AdService.instance.initialize();
      }

      final showAppOpenAds = ref.read(appOpenAdsEnabledProvider);

      if (!showAppOpenAds || !_canShowAd) {
        _loadCompleter?.complete();
        _loadCompleter = null;
        return;
      }

      if (_appOpenAd != null || _isLoading || _isAdLoaded) {
        _loadCompleter?.complete();
        _loadCompleter = null;
        return;
      }

      final maxRetryCount = ref.read(remoteConfigProvider).maxAdRetryCount;

      if (_retryCount >= maxRetryCount) {
        _retryCount = 0;
        _loadCompleter?.complete();
        _loadCompleter = null;
        return;
      }

      _isLoading = true;
      _isAdLoaded = false;

      final adUnitId = ref.read(remoteConfigProvider).appOpenAdUnit;

      await AppOpenAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (AppOpenAd ad) {
            _appOpenAd = ad;
            _isLoading = false;
            _isAdLoaded = true;
            _retryCount = 0;

            _setupAdCallbacks(ref);
            _loadCompleter?.complete();
            _loadCompleter = null;
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isLoading = false;
            _isAdLoaded = false;
            _appOpenAd = null;
            _retryCount++;
            _loadCompleter?.complete();
            _loadCompleter = null;
          },
        ),
      );
    } catch (e) {
      _isLoading = false;
      _isAdLoaded = false;
      _retryCount++;
      _loadCompleter?.complete();
      _loadCompleter = null;
    }
  }

  void _setupAdCallbacks(WidgetRef ref) {
    if (_appOpenAd == null) return;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (AppOpenAd ad) {
        ref.read(isFullscreenAdShowingProvider.notifier).state = true;
      },
      onAdImpression: (AppOpenAd ad) {},
      onAdFailedToShowFullScreenContent: (AppOpenAd ad, AdError error) {
        _appOpenAd = null;
        _isAdLoaded = false;
        loadAppOpenAd(ref);
        ref.read(isFullscreenAdShowingProvider.notifier).state = false;
      },
      onAdDismissedFullScreenContent: (AppOpenAd ad) {
        _appOpenAd = null;
        _isAdLoaded = false;
        _lastShownTime = DateTime.now();
        loadAppOpenAd(ref);
        ref.read(isFullscreenAdShowingProvider.notifier).state = false;
      },
      onAdClicked: (AppOpenAd ad) {},
      onAdWillDismissFullScreenContent: (AppOpenAd ad) {},
    );
  }

  Future<bool> showAppOpenAd(WidgetRef ref) async {
    if (_isDisposed) return false;

    try {
      final showAppOpenAds = ref.read(appOpenAdsEnabledProvider);
      if (!showAppOpenAds || !_canShowAd) {
        return false;
      }

      if (!_isAdLoaded || _appOpenAd == null) {
        await loadAppOpenAd(ref);

        if (!_isAdLoaded || _appOpenAd == null) {
          return false;
        }
      }

      final now = DateTime.now();
      if (_lastShownTime != null) {
        final minutesSinceLastAd = now.difference(_lastShownTime!).inMinutes;
        if (minutesSinceLastAd < 5) {
          return false;
        }
      }

      await _appOpenAd!.show();
      _lastShownTime = now;
      return true;
    } catch (e) {
      _appOpenAd = null;
      _isAdLoaded = false;
      await loadAppOpenAd(ref);
      return false;
    }
  }

  bool get isAdLoaded => _isAdLoaded;

  void disableForSession() {
    _canShowAd = false;
  }

  void enableForSession() {
    _canShowAd = true;
  }

  void dispose() {
    _isDisposed = true;
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isLoading = false;
    _isAdLoaded = false;
    _loadCompleter?.complete();
    _loadCompleter = null;
  }
}