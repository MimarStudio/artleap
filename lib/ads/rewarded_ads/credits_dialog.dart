import 'package:Artleap.ai/shared/route_export.dart';

class CreditsDialog extends ConsumerWidget {
  final bool isFreePlan;
  final VoidCallback onWatchAd;
  final VoidCallback onUpgrade;
  final VoidCallback onLater;
  final bool adDialogShown;
  final Function(bool) onDialogShownChanged;

  const CreditsDialog({
    super.key,
    required this.isFreePlan,
    required this.onWatchAd,
    required this.onUpgrade,
    required this.onLater,
    required this.adDialogShown,
    required this.onDialogShownChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adState = ref.watch(rewardedAdNotifierProvider);
    final isAdReady = adState.canShowAd;
    final isAdLoading = adState.status == AdLoadStatus.loading;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;

    final userProfile = ref.watch(userProfileProvider).valueOrNull?.userProfile;
    final rewardDailyCount = userProfile?.user.rewardDailyCount ?? 0;
    final canWatchAd = rewardDailyCount < 2;

    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 20,
          vertical: isSmallScreen ? 8 : 16,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.85,
            minHeight: isSmallScreen ? 300 : 400,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(context, isSmallScreen),
                SizedBox(height: isSmallScreen ? 12 : 16),
                _buildStatusCard(context, isSmallScreen, rewardDailyCount),
                SizedBox(height: isSmallScreen ? 16 : 20),
                _buildOptionsSection(context, isFreePlan, isAdReady, isAdLoading, isSmallScreen, ref, canWatchAd, rewardDailyCount),
                SizedBox(height: isSmallScreen ? 16 : 20),
                _buildActionButtons(context, isFreePlan, isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: isSmallScreen ? 60 : 80,
          height: isSmallScreen ? 60 : 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.workspace_premium_rounded,
              size: isSmallScreen ? 32 : 40,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Text(
          'Out of Credits',
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4),
        Text(
          isFreePlan ? 'Free Plan User' : 'Premium Plan',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, bool isSmallScreen, int rewardDailyCount) {
    final hasExceededAdLimit = rewardDailyCount >= 2;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: isSmallScreen ? 16 : 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Text(
                'Current Status',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            hasExceededAdLimit
                ? 'You\'ve watched 2 ads today (maximum reached). Upgrade to premium for unlimited credits.'
                : 'You\'ve used all your daily credits. Choose an option below to continue creating.',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection(
      BuildContext context,
      bool isFreePlan,
      bool isAdReady,
      bool isAdLoading,
      bool isSmallScreen,
      WidgetRef ref,
      bool canWatchAd,
      int rewardDailyCount,
      ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Get More Credits',
          style: TextStyle(
            fontSize: isSmallScreen ? 15 : 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: isSmallScreen ? 10 : 12),
        if (isFreePlan && canWatchAd) ...[
          _buildOptionCard(
            context,
            title: isAdReady ? 'Watch an Ad ($rewardDailyCount/2)' : 'Loading Ad',
            subtitle: isAdReady ? 'Earn free credits instantly' : 'Please wait...',
            icon: Icons.play_circle_fill_rounded,
            iconColor: Colors.blueAccent,
            isActive: isAdReady && !isAdLoading,
            isLoading: isAdLoading,
            isSmallScreen: isSmallScreen,
            onTap: () {
              if (isAdReady && !isAdLoading) {
                onWatchAd();
              }
            },
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
        ],
        _buildOptionCard(
          context,
          title: 'Upgrade to Premium',
          subtitle: rewardDailyCount >= 2
              ? 'Unlimited credits (ads limit reached)'
              : 'Unlimited credits & premium features',
          icon: Icons.stars_rounded,
          iconColor: Colors.amber,
          isActive: true,
          isSmallScreen: isSmallScreen,
          onTap: onUpgrade,
        ),
        if (isFreePlan && rewardDailyCount >= 2) ...[
          SizedBox(height: isSmallScreen ? 10 : 12),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: isSmallScreen ? 14 : 16,
                  color: Colors.orange,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    'Daily ad limit reached (2/2). Upgrade for unlimited credits.',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color iconColor,
        required bool isActive,
        bool isLoading = false,
        required bool isSmallScreen,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive ? onTap : null,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(isActive ? 0.5 : 0.3),
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.1),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: isActive
                ? [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: isSmallScreen ? 40 : 48,
                height: isSmallScreen ? 40 : 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: isSmallScreen ? 20 : 24,
                    color: isActive ? iconColor : iconColor.withOpacity(0.5),
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 13,
                        color: isActive
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: isSmallScreen ? 16 : 20,
                  height: isSmallScreen ? 16 : 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              else if (isActive)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: isSmallScreen ? 14 : 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isFreePlan, bool isSmallScreen) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              onDialogShownChanged(false);
              onLater();
            },
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
              ),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Text(
              'Later',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onUpgrade,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            child: Text(
              'Upgrade',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Enhanced showCreditsDialog function with WidgetsBinding to prevent _debugLocked error
void showCreditsDialog({
  required BuildContext context,
  required WidgetRef ref,
  required bool isFreePlan,
  required VoidCallback onWatchAd,
  required VoidCallback onUpgrade,
  required VoidCallback onLater,
  required bool adDialogShown,
  required Function(bool) onDialogShownChanged,
}) {
  // First, check if the context is still valid
  if (!context.mounted) {
    debugPrint('Context is not mounted, skipping dialog');
    return;
  }

  // Use WidgetsBinding to ensure we're not in the middle of a build
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Double-check if context is still valid
    if (!context.mounted) {
      debugPrint('Context is not mounted in post-frame callback');
      return;
    }

    // Check if a dialog is already showing on this context
    final modalRoute = ModalRoute.of(context);
    if (modalRoute?.isCurrent != true) {
      // If not current, wait a bit and try again
      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
          _showDialogSafely(
            context: context,
            ref: ref,
            isFreePlan: isFreePlan,
            onWatchAd: onWatchAd,
            onUpgrade: onUpgrade,
            onLater: onLater,
            adDialogShown: adDialogShown,
            onDialogShownChanged: onDialogShownChanged,
          );
        }
      });
      return;
    }

    _showDialogSafely(
      context: context,
      ref: ref,
      isFreePlan: isFreePlan,
      onWatchAd: onWatchAd,
      onUpgrade: onUpgrade,
      onLater: onLater,
      adDialogShown: adDialogShown,
      onDialogShownChanged: onDialogShownChanged,
    );
  });
}

// Helper function to safely show the dialog
void _showDialogSafely({
  required BuildContext context,
  required WidgetRef ref,
  required bool isFreePlan,
  required VoidCallback onWatchAd,
  required VoidCallback onUpgrade,
  required VoidCallback onLater,
  required bool adDialogShown,
  required Function(bool) onDialogShownChanged,
}) {
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: true,
      builder: (context) => CreditsDialog(
        isFreePlan: isFreePlan,
        onWatchAd: onWatchAd,
        onUpgrade: onUpgrade,
        onLater: onLater,
        adDialogShown: adDialogShown,
        onDialogShownChanged: onDialogShownChanged,
      ),
    ).then((_) {
      // Dialog closed callback
      onDialogShownChanged(false);
    });
  } catch (e) {
    debugPrint('Error showing credits dialog: $e');
    // Try one more time with a delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CreditsDialog(
            isFreePlan: isFreePlan,
            onWatchAd: onWatchAd,
            onUpgrade: onUpgrade,
            onLater: onLater,
            adDialogShown: adDialogShown,
            onDialogShownChanged: onDialogShownChanged,
          ),
        );
      }
    });
  }
}

// Helper function for when ad closes to show credits dialog safely
void showCreditsDialogAfterAd({
  required BuildContext context,
  required WidgetRef ref,
  required bool isFreePlan,
  required VoidCallback onWatchAd,
  required VoidCallback onUpgrade,
  required VoidCallback onLater,
  required Function(bool) onDialogShownChanged,
}) {
  // First close any existing dialog
  if (Navigator.canPop(context)) {
    Navigator.of(context).pop();
  }

  // Wait a moment for the ad to fully close
  Future.delayed(const Duration(milliseconds: 100), () {
    // Then show credits dialog using the safe method
    showCreditsDialog(
      context: context,
      ref: ref,
      isFreePlan: isFreePlan,
      onWatchAd: onWatchAd,
      onUpgrade: onUpgrade,
      onLater: onLater,
      adDialogShown: true,
      onDialogShownChanged: onDialogShownChanged,
    );
  });
}