import 'package:Artleap.ai/ads/interstitial_ads/interstitial_ad_provider.dart';
import 'contionus_button.dart';
import 'option_card.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class OnboardingStepContent extends ConsumerWidget {
  final OnboardingStepData stepData;
  final int currentStep;
  final int? selectedIndex;
  final Function(int) onOptionSelected;
  final VoidCallback onContinue;
  final bool isLastStep;

  const OnboardingStepContent({
    super.key,
    required this.stepData,
    required this.currentStep,
    required this.selectedIndex,
    required this.onOptionSelected,
    required this.onContinue,
    required this.isLastStep,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final safePadding = mediaQuery.padding;

    if (isLastStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(interstitialAdStateProvider.notifier).loadInterstitialAd();
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStepIndicator(currentStep + 1, theme),
          const SizedBox(height: 20),
          Text(
            stepData.title,
            style: AppTextstyle.interBold(
              fontSize: isSmallScreen ? 24.0 : 28.0,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stepData.subtitle,
            style: AppTextstyle.interRegular(
              fontSize: isSmallScreen ? 16.0 : 18.0,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          ListView.builder(
            itemCount: stepData.options.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final isSelected = index == selectedIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: OptionCard(
                  title: stepData.options[index],
                  isSelected: isSelected,
                  onTap: () => onOptionSelected(index),
                ),
              );
            },
          ),
          const SizedBox(height: 16.0),
          ContinueButton(
            isEnabled: selectedIndex != null,
            onPressed: onContinue,
            isLastStep: isLastStep,
          ),
          SizedBox(height: safePadding.bottom),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepNumber, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: AppTextstyle.interBold(
                  fontSize: 12,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Step $stepNumber',
            style: AppTextstyle.interMedium(
              fontSize: 14,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}