import 'package:Artleap.ai/shared/route_export.dart';
import 'package:Artleap.ai/ads/interstitial_ads/interstitial_ad_provider.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  static const String routeName = "tutorial_screen";

  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  late PageController _pageController;
  late ProviderSubscription<InterstitialAdState> _interstitialListener;

  bool _waitingForAdClose = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ Load SMALL native ads for TutorialScreen
      ref.read(nativeAdProvider.notifier).loadSmallNativeAds();
      ref.read(interstitialAdStateProvider.notifier).loadInterstitialAd();
    });

    _interstitialListener = ref.listenManual<InterstitialAdState>(
      interstitialAdStateProvider,
          (previous, next) {
        if (previous?.isShowing == true &&
            next.isShowing == false &&
            _waitingForAdClose) {
          _waitingForAdClose = false;
          _completeTutorialAndNavigate();
        }
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _interstitialListener.close();
    super.dispose();
  }

  void _onGetStartedPressed() async {
    final adState = ref.read(interstitialAdStateProvider);

    if (adState.isLoaded) {
      _waitingForAdClose = true;
      final didShow = await ref
          .read(interstitialAdStateProvider.notifier)
          .showInterstitialAd();

      if (!didShow) {
        _waitingForAdClose = false;
        _completeTutorialAndNavigate();
      }
    } else {
      _completeTutorialAndNavigate();
    }
  }

  void _onSkipPressed() async {
    final notifier = ref.read(tutorialStateProvider.notifier);
    await notifier.skipTutorial();
    if (mounted) {
      _navigateToNextScreen();
    }
  }

  void _completeTutorialAndNavigate() async {
    final notifier = ref.read(tutorialStateProvider.notifier);
    await notifier.completeTutorial();
    if (mounted) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() async {
    final userData = ArtleapNavigationManager.getUserDataFromStorage();
    final userId = userData['userId'] ?? "";
    final userName = userData['userName'] ?? "";
    final userProfilePicture = userData['userProfilePicture'] ?? "";
    final userEmail = userData['userEmail'] ?? "";
    final hasSeenTutorial = await ArtleapNavigationManager.getTutorialStatus(ref);
    await ArtleapNavigationManager.navigateBasedOnUserStatus(
      context: context,
      ref: ref,
      userId: userId,
      userName: userName,
      userProfilePicture: userProfilePicture,
      userEmail: userEmail,
      hasSeenTutorial: hasSeenTutorial,
    );
  }

  void _onPageChanged(int page) {
    ref.read(tutorialStateProvider.notifier).setCurrentPage(page);
  }

  // Widget for SMALL native ads
  Widget _buildNativeAdWidget(
      NativeAdState adState,
      int currentPage,
      bool isSmallScreen,
      BuildContext context,
      ) {
    if (!adState.showAds || !adState.isLoaded || adState.nativeAds.isEmpty) {
      return const SizedBox.shrink();
    }

    final index = currentPage % adState.nativeAds.length;
    final ad = adState.nativeAds[index];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 10 : 20,
        vertical: 12,
      ),
      child: SizedBox(
        height: isSmallScreen ? 120 : 140,
        width: double.infinity,
        child: AdWidget(ad: ad),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(tutorialStateProvider);
    final adState = ref.watch(nativeAdProvider);
    final notifier = ref.read(tutorialStateProvider.notifier);
    final currentScreen = notifier.getCurrentScreen();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, right: 16.0),
                child: TextButton(
                  onPressed: _onSkipPressed,
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

            // Main content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    // Tutorial images
                    SizedBox(
                      height: screenHeight * 0.55,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: notifier.totalPages,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, index) {
                          final screen = ref.watch(tutorialDataProvider)[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.08,
                              vertical: 8.0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.shadow.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  screen.imageAsset,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: theme.colorScheme.surfaceContainer,
                                      child: Icon(
                                        Icons.image,
                                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                                        size: 60,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),

            // Bottom section WITHOUT native ad (moved below)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: isSmallScreen ? 16.0 : 20.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Text content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentScreen.title,
                          style: AppTextstyle.interBold(
                            fontSize: isSmallScreen ? 16 : 18,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.start,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentScreen.description,
                          style: AppTextstyle.interRegular(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.start,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // Page indicators
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          notifier.totalPages,
                              (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: state.currentPage == index ? 24 : 8,
                            height: 6,
                            decoration: BoxDecoration(
                              color: state.currentPage == index
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Navigation buttons
                    SizedBox(
                      height: isSmallScreen ? 45 : 52,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (state.currentPage > 0)
                            SizedBox(
                              width: screenWidth * 0.35,
                              child: TextButton(
                                onPressed: () {
                                  final newPage = state.currentPage - 1;
                                  notifier.setCurrentPage(newPage);
                                  _pageController.animateToPage(
                                    newPage,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_back_ios_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Previous',
                                      style: AppTextstyle.interMedium(
                                        fontSize: 13,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            SizedBox(width: screenWidth * 0.35),

                          SizedBox(
                            width: screenWidth * 0.35,
                            child: ElevatedButton(
                              onPressed: state.isLastPage
                                  ? _onGetStartedPressed
                                  : () {
                                final newPage = state.currentPage + 1;
                                notifier.setCurrentPage(newPage);
                                _pageController.animateToPage(
                                  newPage,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                elevation: 2,
                                shadowColor: theme.colorScheme.primary.withOpacity(0.3),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    state.isLastPage ? 'Start' : 'Next',
                                    style: AppTextstyle.interMedium(
                                      fontSize: 13,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                  if (!state.isLastPage) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: theme.colorScheme.onPrimary,
                                      size: 12,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildNativeAdWidget(adState, state.currentPage, isSmallScreen, context),
          ],
        ),
      ),
    );
  }
}