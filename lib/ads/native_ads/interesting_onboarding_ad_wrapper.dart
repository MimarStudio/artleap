import 'package:Artleap.ai/shared/route_export.dart';

class InterestOnboardingScreenWrapper extends ConsumerStatefulWidget {
  static const String routeName = "interest_onboarding_screen";
  const InterestOnboardingScreenWrapper({super.key});

  @override
  ConsumerState<InterestOnboardingScreenWrapper> createState() =>
      _InterestOnboardingScreenWrapperState();
}

class _InterestOnboardingScreenWrapperState
    extends ConsumerState<InterestOnboardingScreenWrapper> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(centralAdManagementProvider.notifier).loadSmallNativeAds();
      ref.read(centralAdManagementProvider.notifier).loadBannerAd();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const InterestOnboardingScreen();
  }
}