import 'package:Artleap.ai/ads/interstitial_ads/interstitial_ad_provider.dart';
import 'package:Artleap.ai/shared/route_export.dart';

final remoteConfigProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService.instance;
});

final adServiceProvider = Provider<AdService>((ref) {
  return AdService.instance;
});

final interstitialAdProvider = Provider<InterstitialAdNotifier>((ref) {
  return InterstitialAdNotifier(ref);
});

final rewardedAdProvider = Provider<RewardedAdManager>((ref) {
  return RewardedAdManager();
});

final appOpenAdProvider = Provider<AppOpenAdManager>((ref) {
  return AppOpenAdManager.instance;
});

final adInitializationProvider = FutureProvider<void>((ref) async {
  final adService = ref.read(adServiceProvider);
  await adService.initialize();
});

final shouldShowAdsProvider = Provider<bool>((ref) {
  final remoteConfig = ref.read(remoteConfigProvider);
  return remoteConfig.adsEnabled;
});

final bannerAdsEnabledProvider = Provider<bool>((ref) {
  final remoteConfig = ref.read(remoteConfigProvider);
  return remoteConfig.showBannerAds;
});

final interstitialAdsEnabledProvider = Provider<bool>((ref) {
  final remoteConfig = ref.read(remoteConfigProvider);
  return remoteConfig.showInterstitialAds;
});

final rewardedAdsEnabledProvider = Provider<bool>((ref) {
  final remoteConfig = ref.read(remoteConfigProvider);
  return remoteConfig.showRewardedAds;
});

final nativeAdsEnabledProvider = Provider<bool>((ref) {
  final remoteConfig = ref.read(remoteConfigProvider);
  return remoteConfig.showNativeAds;
});

final appOpenAdsEnabledProvider = Provider<bool>((ref) {
  final remoteConfig = ref.read(remoteConfigProvider);
  return remoteConfig.showAppOpenAds;
});

final interstitialIntervalProvider = Provider<int>((ref) {
  final remoteConfig = ref.read(remoteConfigProvider);
  return remoteConfig.interstitialInterval;
});

final isFullscreenAdShowingProvider = StateProvider<bool>((ref) => false);

final routeObserverProvider = Provider((ref) => RouteObserver<PageRoute>());