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
    if (adState.isLoaded) {
      _waitingForAdClose = true;
      final didShow = await ref
          .read(interstitialAdStateProvider.notifier)
          .showInterstitialAd();
      if (!didShow) {
        _waitingForAdClose = false;
        widget.onPressed();
      }
    } else {
      widget.onPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: widget.isEnabled ? _handlePress : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.isEnabled
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withOpacity(0.5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        shadowColor: theme.colorScheme.primary.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.isLastStep ? "Get Started" : "Continue",
            style: AppTextstyle.interBold(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            widget.isLastStep ? Icons.rocket_launch : Icons.arrow_forward_ios,
            size: 18,
          ),
        ],
      ),
    );
  }
}