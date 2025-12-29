import 'package:Artleap.ai/shared/route_export.dart';

class SimpleRewardedAdHelper {
  static Future<void> simpleRewardedAd({
    required WidgetRef ref,
    required VoidCallback onAdDismissed,
    VoidCallback? onRewardEarned,
    VoidCallback? onAdFailed,
  }) async {
    final adState = ref.read(rewardedAdNotifierProvider);

    if (!adState.canShowAd) {
      await AdHelper.preloadRewardedAd(ref);
      if (onAdFailed != null) onAdFailed();
      return;
    }

    await AdHelper.showRewardedAdWithSimpleCallback(
      ref: ref,
      onRewardEarned: (coins) {
      },
      onAdDismissed: () {
        final adNotifier = ref.read(rewardedAdNotifierProvider.notifier);
        adNotifier.loadAd();
        onAdDismissed();
      },
      onAdFailed: () {
        final adNotifier = ref.read(rewardedAdNotifierProvider.notifier);
        adNotifier.loadAd();
        if (onAdFailed != null) onAdFailed();
      },
    );
  }
}