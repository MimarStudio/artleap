import 'package:Artleap.ai/ads/interstitial_ads/interstitial_ad_provider.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class ContinueButton extends ConsumerStatefulWidget {
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
  ConsumerState<ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends ConsumerState<ContinueButton> {
  late final ProviderSubscription<InterstitialAdState> _adListener;
  bool _waitingForAdClose = false;

  @override
  void initState() {
    super.initState();

    /// ✅ Listen once for ad close
    _adListener = ref.listenManual<InterstitialAdState>(
      interstitialAdStateProvider,
          (previous, next) {
        if (previous?.isShowing == true &&
            next.isShowing == false &&
            _waitingForAdClose) {
          _waitingForAdClose = false;
          widget.onPressed();
        }
      },
    );
  }

  @override
  void dispose() {
    _adListener.close();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (!widget.isLastStep) {
      widget.onPressed();
      return;
    }

    final adState = ref.read(interstitialAdStateProvider);

    /// ✅ If ad is loaded → show it
    if (adState.isLoaded) {
      _waitingForAdClose = true;
      final didShow = await ref
          .read(interstitialAdStateProvider.notifier)
          .showInterstitialAd();

      /// Safety fallback
      if (!didShow) {
        _waitingForAdClose = false;
        widget.onPressed();
      }
    } else {
      /// Fallback if SDK failed
      widget.onPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.isEnabled ? _handlePress : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.isLastStep ? "Get Started" : "Continue",
              style: AppTextstyle.interBold(fontSize: 16),
            ),
            const SizedBox(width: 10),
            Icon(
              widget.isLastStep
                  ? Icons.rocket_launch
                  : Icons.arrow_forward_ios,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
