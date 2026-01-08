import 'dart:async';
import 'components/onboarding_step_content.dart';
import 'package:Artleap.ai/shared/route_export.dart';

final bannerAdLoadingProvider = StateProvider<bool>((ref) => false);
final nativeAdLoadingProvider = StateProvider<bool>((ref) => false);
final adsInitializedProvider = StateProvider<bool>((ref) => false);
final interstitialShownProvider = StateProvider<bool>((ref) => false);

class InterestOnboardingScreen extends ConsumerWidget {
  const InterestOnboardingScreen({super.key});
  static const String routeName = "interest_onboarding_screen";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAds(ref);
    });
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            BannerAdWidget(uniqueScreenKey: '/onboarding'),
            _SkipButton(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: ProgressBar(),
            ),
            const Expanded(
              child: _OnboardingContent(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeAds(WidgetRef ref) async {
    final adsInitialized = ref.read(adsInitializedProvider);
    if (adsInitialized) return;

    try {
      ref.read(bannerAdLoadingProvider.notifier).state = true;
      ref.read(nativeAdLoadingProvider.notifier).state = true;

      final centralAdNotifier = ref.read(centralAdManagementProvider.notifier);
      centralAdNotifier.setWidgetRef(ref);

      await Future.wait([
        centralAdNotifier.loadBannerAd(),
        ref.read(nativeAdProvider.notifier).loadSmallNativeAds(),
        centralAdNotifier.loadInterstitialAd(),
      ]);

      ref.read(adsInitializedProvider.notifier).state = true;
    } catch (e) {
      Future.delayed(const Duration(seconds: 2), () {
        _initializeAds(ref);
      });
    } finally {
      ref.read(bannerAdLoadingProvider.notifier).state = false;
      ref.read(nativeAdLoadingProvider.notifier).state = false;
    }
  }
}

class _SkipButton extends ConsumerWidget {
  const _SkipButton();

  Future<void> _showInterstitialAndLoadCollapsibleBanner(WidgetRef ref, BuildContext context) async {
    final interstitialAlreadyShown = ref.read(interstitialShownProvider);
    if (interstitialAlreadyShown) {
      await _loadCollapsibleBannerAndNavigate(ref, context);
      return;
    }

    try {
      final centralAdNotifier = ref.read(centralAdManagementProvider.notifier);
      final canShow = centralAdNotifier.canShowAd();
      final isInterstitialLoaded = centralAdNotifier.isAdLoaded('interstitial');

      if (isInterstitialLoaded && canShow) {
        final didShow = await centralAdNotifier.showInterstitialAd();

        if (didShow) {
          ref.read(interstitialShownProvider.notifier).state = true;
          await Future.delayed(const Duration(milliseconds: 500));
        }
        await _loadCollapsibleBannerAndNavigate(ref, context);
      } else {
        await _loadCollapsibleBannerAndNavigate(ref, context);
      }
    } catch (e) {
      await _loadCollapsibleBannerAndNavigate(ref, context);
    }
  }

  Future<void> _loadCollapsibleBannerAndNavigate(WidgetRef ref, BuildContext context) async {
    try {
      final centralAdNotifier = ref.read(centralAdManagementProvider.notifier);
      await centralAdNotifier.loadCollapsibleBannerAd();
    } catch (e) {}

    if (context.mounted) {
      Navigation.pushNamedAndRemoveUntil(BottomNavBar.routeName);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, right: 16.0),
        child: TextButton(
          onPressed: () async {
            await _showInterstitialAndLoadCollapsibleBanner(ref, context);
            final analyticsService = ref.read(analyticsServiceProvider);
            analyticsService.logCustomEvent(
              eventName: 'Skip_button_clicked',
              parameters: {
                'screen': 'onboarding_screen',
              },
            );
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
    );
  }
}

class _OnboardingContent extends ConsumerWidget {
  const _OnboardingContent();

  Future<void> _showInterstitialAndLoadCollapsibleBanner(WidgetRef ref, BuildContext context) async {
    final interstitialAlreadyShown = ref.read(interstitialShownProvider);
    if (interstitialAlreadyShown) {
      await _loadCollapsibleBannerSaveAndNavigate(ref, context);
      return;
    }

    try {
      final centralAdNotifier = ref.read(centralAdManagementProvider.notifier);
      final canShow = centralAdNotifier.canShowAd();
      final isInterstitialLoaded = centralAdNotifier.isAdLoaded('interstitial');

      if (isInterstitialLoaded && canShow) {
        final didShow = await centralAdNotifier.showInterstitialAd();

        if (didShow) {
          ref.read(interstitialShownProvider.notifier).state = true;
          await Future.delayed(const Duration(milliseconds: 500));
        }
        await _loadCollapsibleBannerSaveAndNavigate(ref, context);
      } else {
        await _loadCollapsibleBannerSaveAndNavigate(ref, context);
      }
    } catch (e) {
      await _loadCollapsibleBannerSaveAndNavigate(ref, context);
    }
  }

  Future<void> _loadCollapsibleBannerSaveAndNavigate(WidgetRef ref, BuildContext context) async {
    try {
      await _saveUserInterests(ref, context);

      final centralAdNotifier = ref.read(centralAdManagementProvider.notifier);
      await centralAdNotifier.loadCollapsibleBannerAd();
    } catch (e) {}

    if (context.mounted) {
      Navigation.pushNamedAndRemoveUntil(BottomNavBar.routeName);
    }
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
      final success = await ref.read(userPreferencesServiceProvider).updateUserInterests(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(interestOnboardingStepProvider);
    final onboardingData = ref.watch(onboardingDataProvider);
    final selectedOptions = ref.watch(selectedOptionsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    final currentStepData = onboardingData[currentStep];
    final currentSelection = selectedOptions[currentStep];
    final isLastStep = currentStep == onboardingData.length - 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: isSmallScreen ? 50 : 60,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16.0 : 32.0,
                    vertical: 10.0,
                  ),
                  child: OnboardingStepContent(
                    stepData: currentStepData,
                    currentStep: currentStep,
                    selectedIndex: currentSelection,
                    onOptionSelected: (index) {
                      final updatedSelections = List<int?>.from(selectedOptions);
                      updatedSelections[currentStep] = index;
                      ref.read(selectedOptionsProvider.notifier).state = updatedSelections;
                    },
                    onContinue: () => _handleContinue(ref, context, isLastStep),
                    isLastStep: isLastStep,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: 10,
                left: isSmallScreen ? 16.0 : 32.0,
                right: isSmallScreen ? 16.0 : 32.0,
              ),
              child: ContinueButton(
                isEnabled: currentSelection != null,
                onPressed: () => _handleContinue(ref, context, isLastStep),
                isLastStep: isLastStep,
              ),
            ),
            _OnboardingNativeAd(),
          ],
        );
      },
    );
  }

  Future<void> _handleContinue(WidgetRef ref, BuildContext context, bool isLastStep) async {
    final currentStep = ref.read(interestOnboardingStepProvider);
    final onboardingData = ref.read(onboardingDataProvider);
    final analyticsService = ref.read(analyticsServiceProvider);

    if (currentStep < onboardingData.length - 1) {
      AnalyticsService.instance.logButtonClick(buttonName: 'Next Button Onboarding $currentStep');
      ref.read(interestOnboardingStepProvider.notifier).state++;

      analyticsService.logCustomEvent(
        eventName: 'Next_button_clicked',
        parameters: {
          'screen': 'onboarding_screen',
        },
      );

    } else {
      AnalyticsService.instance.logButtonClick(buttonName: 'Finish Button Onboarding');
      analyticsService.logCustomEvent(
        eventName: 'Finish_button_clicked',
        parameters: {
          'screen': 'onboarding_screen',
        },
      );
      await _showInterstitialAndLoadCollapsibleBanner(ref, context);
    }
  }
}

class _OnboardingNativeAd extends ConsumerWidget {
  const _OnboardingNativeAd();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final adState = ref.watch(nativeAdProvider);
    final centralAdState = ref.watch(centralAdManagementProvider);

    final adsList = adState.smallNativeAds;
    final isLoading = adState.isLoadingSmall;
    final isAdTypeLoaded = centralAdState.adLoadStatus['smallNative'] ?? false;

    if (isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        padding: const EdgeInsets.all(10),
        height: 90,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    if (adState.errorMessage != null && adsList.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        padding: const EdgeInsets.all(10),
        height: 90,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.error.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                'Ad failed to load',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final ad = adsList.isNotEmpty ? adsList.first : null;

    if (!adState.showAds || !isAdTypeLoaded || adsList.isEmpty || ad == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.ads_click,
                size: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              Text(
                'Advertisement',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            width: double.infinity,
            child: AdWidget(ad: ad),
          ),
        ],
      ),
    );
  }
}