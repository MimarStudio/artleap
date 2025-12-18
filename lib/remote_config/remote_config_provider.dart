import 'package:Artleap.ai/shared/route_export.dart';

final remoteConfigProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService.instance;
});

final remoteConfigInitializationProvider = FutureProvider<void>((ref) async {
  final remoteConfig = ref.read(remoteConfigProvider);
  await remoteConfig.initialize();
});


class EffectiveAdsConfig {
  final bool showBanner;
  final bool showInterstitial;
  final bool showRewarded;
  final bool showNative;
  final bool showAppOpen;

  const EffectiveAdsConfig({
    required this.showBanner,
    required this.showInterstitial,
    required this.showRewarded,
    required this.showNative,
    required this.showAppOpen,
  });

  factory EffectiveAdsConfig.allDisabled() {
    return const EffectiveAdsConfig(
      showBanner: false,
      showInterstitial: false,
      showRewarded: false,
      showNative: false,
      showAppOpen: false,
    );
  }
}



final effectiveAdsProvider = Provider<EffectiveAdsConfig>((ref) {
  final remoteConfig = ref.watch(remoteConfigProvider);
  final userProfileAsync = ref.watch(userProfileProvider);

  final isFreeUser = userProfileAsync.valueOrNull?.isFreeUser ?? true;
  if (!isFreeUser) {
    return EffectiveAdsConfig.allDisabled();
  }

  return EffectiveAdsConfig(
    showBanner: remoteConfig.showBannerAds,
    showInterstitial: remoteConfig.showInterstitialAds,
    showRewarded: remoteConfig.showRewardedAds,
    showNative: remoteConfig.showNativeAds,
    showAppOpen: remoteConfig.showAppOpenAds,
  );
});
