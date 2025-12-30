import 'package:Artleap.ai/domain/api_services/api_response.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class ActionButtons extends StatelessWidget {
  final bool isActive;
  final UserSubscriptionModel? subscription;

  const ActionButtons({
    super.key,
    required this.isActive,
    required this.subscription,
  });

  void _handleCancelSubscription(BuildContext context, WidgetRef ref) {
    final paymentMethod = subscription?.paymentMethod?.toLowerCase() ?? '';

    if (paymentMethod == 'stripe') {
      _showStripeCancelDialog(context, ref);
    } else {
      _showPlatformCancelGuide(paymentMethod,context);
    }
  }

  void _showStripeCancelDialog(BuildContext context, WidgetRef ref) {
    DialogService.showAppDialog(
      context: context,
      type: DialogType.confirmDelete,
      title: 'Cancel Subscription?',
      message:
      'We\'re sorry to see you go. If you cancel Your Subscription you will lose all your credits ',
      confirmText: 'Cancel Plan',
      cancelText: 'Keep Plan',
      icon: Icons.warning_rounded,
      onConfirm: () async {
        final userId = subscription?.userId;
        if (userId == null) return;

        try {
          final response = await ref.read(
            cancelSubscriptionProvider(
              CancelSubscriptionParams(
                userId: userId,
                immediate: true,
              ),
            ).future,
          );

          if (response.status == Status.completed) {
            ref.invalidate(currentSubscriptionProvider(userId));

            DialogService.showSuccess(
              context: context,
              title: 'Subscription Cancelled',
              message: 'Your subscription has been successfully cancelled.',
              onConfirm: () {
                  Navigator.pushReplacementNamed(context,BottomNavBar.routeName);
              },
            );
          }
          else {
            appErrorSnackBar('Error', response.message ?? 'Failed to cancel subscription');
          }
        } catch (e) {
          appErrorSnackBar('Error', e.toString());
        }
      },
      extraData: {
        'planName': subscription?.planSnapshot?.name ?? 'Unknown Plan',
      },
    );
  }


  void _showPlatformCancelGuide(String paymentMethod,BuildContext context) {
    final (title, message) = _getPlatformCancelConfig(paymentMethod);

    DialogService.showAppDialog(
      context: context,
      type: DialogType.warning,
      title: title,
      message: message,
      confirmText: 'Got It',
      cancelText: 'Cancel',
      icon: Icons.payment,
    );
  }

  (String, String) _getPlatformCancelConfig(String paymentMethod) {
    switch (paymentMethod) {
      case 'google_play':
      case 'google_pay':
        return (
        'Cancel Google Play Subscription',
        'To cancel your subscription, please visit the Google Play Store:\n\n'
            '1. Open Google Play Store\n'
            '2. Tap your profile icon\n'
            '3. Go to "Payments & subscriptions" → "Subscriptions"\n'
            '4. Find "Artleap.ai" and cancel your subscription'
        );
      case 'apple':
      case 'appstore':
        return (
        'Cancel Apple App Store Subscription',
        'To cancel your subscription, please visit the App Store:\n\n'
            '1. Open Settings app\n'
            '2. Tap your name\n'
            '3. Go to "Subscriptions"\n'
            '4. Find "Artleap.ai" and cancel your subscription'
        );
      default:
        return (
        'Cancel Subscription',
        'Please contact our support team or visit the platform '
            'where you originally purchased the subscription to cancel.'
        );
    }
  }

  bool get _shouldShowCancelButton {
    if (!isActive) return false;
    if (subscription == null) return false;
    if (subscription!.planSnapshot?.type == 'free') return false;
    if (subscription!.autoRenew != true) return false;

    final paymentMethod = subscription!.paymentMethod?.toLowerCase();
    return paymentMethod != null && paymentMethod.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final theme = Theme.of(context);
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, ChoosePlanScreen.routeName);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isActive && subscription?.planSnapshot?.name != 'Free'
                      ? 'Change Plan'
                      : 'Subscribe Now',
                  style: AppTextstyle.interBold(
                    fontSize: 16,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            if (_shouldShowCancelButton)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    _handleCancelSubscription(context, ref);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel Subscription',
                    style: AppTextstyle.interBold(
                      fontSize: 16,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}