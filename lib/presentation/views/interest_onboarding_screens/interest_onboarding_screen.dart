import 'components/onboarding_step_content.dart';
import 'package:Artleap.ai/shared/route_export.dart';
import 'package:Artleap.ai/ads/banner_ads/banner_ad_widget.dart';

class InterestOnboardingScreen extends ConsumerStatefulWidget {
  const InterestOnboardingScreen({super.key});
  static const String routeName = "interest_onboarding_screen";

  @override
  ConsumerState<InterestOnboardingScreen> createState() => _InterestOnboardingScreenState();
}

class _InterestOnboardingScreenState extends ConsumerState<InterestOnboardingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load native ads on initialization
      ref.read(nativeAdProvider.notifier).loadSmallNativeAds();
    });
  }

  Widget _buildNativeAdWidget(
      NativeAdState adState,
      int currentStep,
      bool isSmallScreen,
      BuildContext context,
      ) {
    if (!adState.showAds || !adState.isLoaded || adState.nativeAds.isEmpty) {
      return const SizedBox.shrink();
    }

    final index = currentStep % adState.nativeAds.length;
    final ad = adState.nativeAds[index];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.ads_click,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              Text(
                'Advertisement',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: isSmallScreen ? 90 : 100,
            width: double.infinity,
            child: AdWidget(ad: ad),
          ),
        ],
      ),
    );
  }

  Future<void> _saveUserInterests(WidgetRef ref, BuildContext context) async {
    final selectedOptions = ref.read(selectedOptionsProvider);
    final onboardingData = ref.read(onboardingDataProvider);
    final userId = UserData.ins.userId;

    if (userId == null || userId.isEmpty) {
      if (context.mounted) {
        appSnackBar(
          'Error',
          'User not found. Please login again.',
          backgroundColor: AppColors.red,
        );
      }
      return;
    }

    final List<String> selectedInterests = [];
    final List<String> categories = [];

    for (int i = 0; i < selectedOptions.length; i++) {
      final selectedIndex = selectedOptions[i];
      if (selectedIndex != null &&
          onboardingData[i].options.length > selectedIndex) {
        selectedInterests.add(onboardingData[i].options[selectedIndex]);
        categories.add('category_$i');
      }
    }

    if (selectedInterests.isNotEmpty) {
      final success =
      await ref.read(userPreferencesServiceProvider).updateUserInterests(
        userId: userId,
        selected: selectedInterests,
        categories: categories,
      );

      if (!success && context.mounted) {
        appSnackBar(
          'Error',
          'Failed to save interests.',
          backgroundColor: AppColors.red,
        );
      }
    }
  }

  void _handleContinue(WidgetRef ref, BuildContext context) {
    final currentStep = ref.read(interestOnboardingStepProvider);
    final onboardingData = ref.read(onboardingDataProvider);

    if (currentStep < onboardingData.length - 1) {
      ref.read(interestOnboardingStepProvider.notifier).state++;
    } else {
      _saveUserInterests(ref, context).then((_) {
        Navigation.pushNamedAndRemoveUntil(BottomNavBar.routeName);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentStep = ref.watch(interestOnboardingStepProvider);
    final onboardingData = ref.watch(onboardingDataProvider);
    final selectedOptions = ref.watch(selectedOptionsProvider);
    final adState = ref.watch(nativeAdProvider); // Watch native ad state

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final screenHeight = MediaQuery.of(context).size.height;
    final mediaPadding = MediaQuery.of(context).padding;

    final currentStepData = onboardingData[currentStep];
    final currentSelection = selectedOptions[currentStep];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: EdgeInsets.only(
          top: mediaPadding.top,
          bottom: mediaPadding.bottom,
        ),
        child: Column(
          children: [
            Container(
              color: theme.colorScheme.surface,
              child: const BannerAdWidget(),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, right: 16.0),
                child: TextButton(
                  onPressed: () {
                    Navigation.pushNamedAndRemoveUntil(BottomNavBar.routeName);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'Skip',
                    style: AppTextstyle.interMedium(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: ProgressBar(),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16.0 : 32.0,
                          vertical: 16.0,
                        ),
                        child: OnboardingStepContent(
                          stepData: currentStepData,
                          currentStep: currentStep,
                          selectedIndex: currentSelection,
                          onOptionSelected: (index) {
                            final updatedSelections =
                            List<int?>.from(selectedOptions);
                            updatedSelections[currentStep] = index;
                            ref.read(selectedOptionsProvider.notifier).state =
                                updatedSelections;
                          },
                          onContinue: () => _handleContinue(ref, context),
                          isLastStep:
                          currentStep == onboardingData.length - 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildNativeAdWidget(adState, currentStep, isSmallScreen, context),
          ],
        ),
      ),
    );
  }
}