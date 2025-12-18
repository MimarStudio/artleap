import 'package:Artleap.ai/ads/interstitial_ads/interstitial_ad_provider.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class ContinueButton extends ConsumerWidget {
  final bool isEnabled;
  final VoidCallback onPressed;
  final bool isLastStep;

  const ContinueButton({
    super.key,
    required this.isEnabled,
    required this.onPressed,
    required this.isLastStep,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? () => _handlePress(ref) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 2,
          disabledBackgroundColor:
          theme.colorScheme.onSurface.withOpacity(0.12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLastStep ? "Get Started" : "Continue",
              style: AppTextstyle.interBold(
                fontSize: 16.0,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isLastStep
                  ? Icon(
                Icons.rocket_launch,
                key: const ValueKey('rocket'),
                size: 16,
                color: theme.colorScheme.onPrimary,
              )
                  : Icon(
                Icons.arrow_forward_ios_outlined,
                key: const ValueKey('arrow'),
                size: 16,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePress(WidgetRef ref) async {
    if (isLastStep) {
      final adState = ref.read(interstitialAdStateProvider);
      if (adState.isLoaded) {
        final adShown = await ref.read(interstitialAdStateProvider.notifier).showInterstitialAd();
        if (!adShown) {
          onPressed();
        } else {
          ref.listen<InterstitialAdState>(
            interstitialAdStateProvider,
                (previous, next) {
              if (previous?.isShowing == true && next.isShowing == false) {
                onPressed();
                ref
                  ..read(interstitialAdStateProvider)
                  ..read(interstitialAdStateProvider.notifier);
              }
            },
          );
        }
      } else {
        onPressed();
      }
    } else {
      onPressed();
    }
  }
}