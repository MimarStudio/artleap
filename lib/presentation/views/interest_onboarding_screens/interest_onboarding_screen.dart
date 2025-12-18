import 'components/onboarding_step_content.dart';
import 'package:Artleap.ai/shared/route_export.dart';

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

    // Load the native ad when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nativeAdProvider.notifier).loadMultipleAds();
    });
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

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    final currentStepData = onboardingData[currentStep];
    final currentSelection = selectedOptions[currentStep];

    final adState = ref.watch(nativeAdProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: currentStep == 0
            ? null
            : IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () {
            if (currentStep > 0) {
              ref.read(interestOnboardingStepProvider.notifier).state--;
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigation.pushNamedAndRemoveUntil(BottomNavBar.routeName);
            },
            child: Text(
              'Skip',
              style: AppTextstyle.interMedium(
                fontSize: 16.0,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Native Ad at the TOP
            if (adState.showAds && adState.isLoaded && adState.nativeAds.isNotEmpty)
              _buildNativeAdWidget(
                adState,
                currentStep,
                isSmallScreen,
                context,
              ),

            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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

                      // Optional: You can show another ad at bottom if needed
                      // But based on your request, ad should be at top
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeAdWidget(
      NativeAdState adState,
      int currentStep,
      bool isSmallScreen,
      BuildContext context,
      ) {
    if (!adState.isLoaded || adState.nativeAds.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use a consistent ad for this screen or cycle through available ads
    final index = currentStep % adState.nativeAds.length;
    final ad = adState.nativeAds[index];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 32,
        vertical: 8,
      ),
      child: Container(
        height: 100, // Adjust height as needed
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}