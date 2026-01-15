import 'dart:async';
import 'package:Artleap.ai/shared/theme/custom_theme_extension.dart';
import 'package:Artleap.ai/shared/route_export.dart';

final privacyPolicyLoadingProvider = StateProvider<bool>((ref) => false);
final privacyPolicyAdLoadedProvider = StateProvider<bool>((ref) => false);

class AcceptPrivacyPolicyScreen extends ConsumerStatefulWidget {
  const AcceptPrivacyPolicyScreen({super.key});
  static const String routeName = "accept_privacy_policy";

  @override
  ConsumerState<AcceptPrivacyPolicyScreen> createState() =>
      _AcceptPrivacyPolicyScreenState();
}

class _AcceptPrivacyPolicyScreenState
    extends ConsumerState<AcceptPrivacyPolicyScreen> {
  bool _adsInitialized = false;
  Timer? _adRetryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initializeAds();
    });
  }

  Future<void> _initializeAds() async {
    if (_adsInitialized) return;

    try {
      final centralAdNotifier = ref.read(centralAdManagementProvider.notifier);
      centralAdNotifier.setWidgetRef(ref);
      await Future.wait([
        centralAdNotifier.loadBannerAd(),
        centralAdNotifier.loadSmallNativeAds(),
      ]);

      if (mounted) {
        setState(() {
          _adsInitialized = true;
        });
        ref.read(privacyPolicyAdLoadedProvider.notifier).state = true;
      }

    } catch (e) {
      _adRetryTimer = Timer(Duration(seconds: 3), () {
        if (mounted && !_adsInitialized) {
          _initializeAds();
        }
      });
    }
  }

  @override
  void dispose() {
    _adRetryTimer?.cancel();
    super.dispose();
  }

  Future<void> _acceptPrivacyPolicy() async {
    final isLoading = ref.read(privacyPolicyLoadingProvider);
    if (isLoading) return;

    ref.read(privacyPolicyLoadingProvider.notifier).state = true;

    try {
      final userId = UserData.ins.userId;
      if (userId == null || userId.isEmpty) {
        throw Exception("User ID not found");
      }

      final success = await ref
          .read(userPreferencesServiceProvider)
          .acceptPrivacyPolicy(userId: userId, version: "1.0");

      if (!success) {
        if (mounted) {
          appSnackBar(
            'Error',
            'Failed to accept privacy policy. Please try again.',
            backgroundColor: AppColors.red,
          );
        }
        ref.read(privacyPolicyLoadingProvider.notifier).state = false;
        return;
      }
      await _showInterstitialIfAvailable();

      _navigateToInterestScreen();
    } catch (e) {
      if (mounted) {
        appSnackBar(
          'Error',
          'An error occurred. Please try again.',
          backgroundColor: AppColors.red,
        );
        ref.read(privacyPolicyLoadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _showInterstitialIfAvailable() async {
    try {
      final centralAdNotifier = ref.read(centralAdManagementProvider.notifier);
      final canShow = centralAdNotifier.canShowAd();
      final isLoaded = centralAdNotifier.isAdLoaded('interstitial');

      if (isLoaded && canShow) {
        final didShow = await centralAdNotifier.showInterstitialAd();
        if (didShow) {
          await Future.delayed(Duration(seconds: 1));
        }
      }
    } catch (e) {
      print('[PRIVACY POLICY] Error showing interstitial: $e');
    }
  }

  void _navigateToInterestScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(privacyPolicyLoadingProvider.notifier).state = false;
      if (mounted) {
        Navigation.pushNamedAndRemoveUntil(
            InterestOnboardingScreenWrapper.routeName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = theme.extension<CustomThemeExtension>()!;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 375;
    final isLoading = ref.watch(privacyPolicyLoadingProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: customTheme.onboardingBackground,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20.0 : 24.0,
            vertical: screenHeight * 0.04,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 1),
              Text(
                'Ready to dive into a world of\nlimitless possibilities?',
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 22,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onBackground,
                ),
              ),
              SizedBox(height: screenHeight * 0.08),
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return customTheme.headlineGradient.createShader(bounds);
                },
                child: Text(
                  'Take the leap,\nand we\'ll turn\nit into art!',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 38 : 45,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.1),
              Text(
                'With AI at your fingertips, every\nidea transforms into a stunning\nmasterpiece',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 15,
                  fontWeight: FontWeight.w500,
                  color: customTheme.secondaryText,
                  height: 1.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text.rich(
                  TextSpan(
                    text: 'I agree to the ',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 13,
                      color: customTheme.secondaryText,
                    ),
                    children: [
                      TextSpan(
                        text: 'Terms of use',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushNamed(context, '/privacy-policy');
                          },
                      ),
                      const TextSpan(
                          text: ' and acknowledged I have read the '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushNamed(context, '/privacy-policy');
                          },
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: isLoading ? null : _acceptPrivacyPolicy,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: isLoading
                        ? LinearGradient(
                      colors: [
                        Colors.grey.shade400,
                        Colors.grey.shade600
                      ],
                    )
                        : customTheme.buttonGradient,
                    boxShadow: isLoading
                        ? []
                        : [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      'Accept and Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 15 : 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              BannerAdWidget(uniqueScreenKey: '/privacy-policy'),
            ],
          ),
        ),
      ),
    );
  }
}