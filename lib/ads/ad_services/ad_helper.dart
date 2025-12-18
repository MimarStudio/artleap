import 'package:Artleap.ai/shared/route_export.dart';

class AdHelper {
  static Future<void> showInterstitialAd(WidgetRef ref) async {
    final interstitialNotifier = ref.read(interstitialAdProvider);
    await interstitialNotifier.showInterstitialAd();
  }

  static Future<bool> showRewardedAd({
    required WidgetRef ref,
    required void Function(int coins) onRewardEarned,
    void Function()? onAdDismissed,
    void Function()? onAdFailed,
  }) async {
    final notifier = ref.read(rewardedAdNotifierProvider.notifier);

    return notifier.showAd(
      onRewardEarned: onRewardEarned,
      onAdDismissed: onAdDismissed,
      onAdFailedToShow: onAdFailed,
    );
  }

  static Future<bool> showRewardedAdWithSimpleCallback({
    required WidgetRef ref,
    required void Function(RewardItem reward) onRewardEarned,
    void Function()? onAdDismissed,
    void Function()? onAdFailed,
  }) async {
    return showRewardedAd(
      ref: ref,
      onRewardEarned: (coins) {
        onRewardEarned(RewardItem(coins, 'coins'));
      },
      onAdDismissed: onAdDismissed,
      onAdFailed: onAdFailed,
    );
  }

  static Future<void> preloadAds(WidgetRef ref) async {
    final rewardedNotifier = ref.read(rewardedAdNotifierProvider.notifier);
    await rewardedNotifier.loadAd();
  }

  // NEW METHODS - added for enhanced functionality

  /// Preloads rewarded ad when screen opens (enhanced version)
  static Future<void> preloadRewardedAd(WidgetRef ref) async {
    try {
      final remoteConfig = ref.read(remoteConfigProvider);
      final enabled = ref.read(rewardedAdsEnabledProvider);

      if (!enabled) {
        debugPrint('[AdHelper] Ads are disabled in remote config');
        return;
      }
      final adNotifier = ref.read(rewardedAdNotifierProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 500));
      adNotifier.loadAd();

    } catch (e, stack) {
      debugPrint('[AdHelper] Failed to preload ad: $e\n$stack');
    }
  }

  /// Shows rewarded ad with enhanced callbacks and error handling
  static Future<bool> showEnhancedRewardedAd({
    required WidgetRef ref,
    required BuildContext context,
    required void Function(int coins) onRewardEarned,
    void Function()? onAdDismissed,
    void Function()? onAdFailedToShow,
  }) async {
    final adNotifier = ref.read(rewardedAdNotifierProvider.notifier);

    final success = await adNotifier.showAd(
      onRewardEarned: onRewardEarned,
      onAdDismissed: onAdDismissed,
      onAdFailedToShow: onAdFailedToShow,
    );

    if (!success) {
      _showSnackbar(
        context,
        message: 'Ad is not ready yet. Please wait...',
        backgroundColor: Colors.orange,
      );

      // Try to load ad
      adNotifier.loadAd();
    }
    return success;
  }
  static void showAdLoadingSnackbar(BuildContext context) {
    appSnackBar('Ad Load', 'Ad is loading, please wait...');
  }

  static void showAdErrorSnackbar(BuildContext context, String message) {
    appErrorSnackBar('Error', message);
  }

  static void showRewardSuccessSnackbar(BuildContext context, int coins) {
    appSnackBar('Success', '🎉 You earned 2 credits!');
  }

  static void refreshUserProfileAfterReward(WidgetRef ref) {
    if (UserData.ins.userId != null) {
      ref.read(userProfileProvider.notifier).getUserProfileData(UserData.ins.userId!);
    }
  }

  static Widget buildAdLoadingIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Preparing ads...',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  static bool isAdReady(WidgetRef ref) {
    final adState = ref.read(rewardedAdNotifierProvider);
    return adState.canShowAd && adState.status == AdLoadStatus.loaded;
  }

  static bool isAdLoading(WidgetRef ref) {
    final adState = ref.read(rewardedAdNotifierProvider);
    return adState.status == AdLoadStatus.loading;
  }

  static RewardedAdState getAdState(WidgetRef ref) {
    return ref.read(rewardedAdNotifierProvider);
  }

  static void _showSnackbar(
      BuildContext context, {
        required String message,
        required Color backgroundColor,
        Duration duration = const Duration(seconds: 2),
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }
}