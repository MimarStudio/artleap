import 'package:Artleap.ai/shared/route_export.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  static const String routeName = "tutorial_screen";

  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  late PageController _pageController;
  bool _waitingForAdClose = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nativeAdProvider.notifier).loadSmallNativeAds();
      ref.read(centralAdManagementProvider.notifier).loadInterstitialAd();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onGetStartedPressed() async {
    final centralAdNotifier = ref.read(centralAdManagementProvider.notifier);
    if (centralAdNotifier.isAdLoaded('interstitial') &&
        centralAdNotifier.canShowAd()) {
      _waitingForAdClose = true;
      final didShow = await centralAdNotifier.showInterstitialAd();

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
    final centralAdNotifier = ref.read(centralAdManagementProvider.notifier);
    if (centralAdNotifier.isAdLoaded('interstitial') &&
        centralAdNotifier.canShowAd()) {
      _waitingForAdClose = true;
      final didShow = await centralAdNotifier.showInterstitialAd();

      if (!didShow) {
        _waitingForAdClose = false;
        await notifier.skipTutorial();
        if (mounted) {
          _navigateToNextScreen();
        }
      }
    } else {
      await notifier.skipTutorial();
      if (mounted) {
        _navigateToNextScreen();
      }
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
    final hasSeenTutorial =
    await ArtleapNavigationManager.getTutorialStatus(ref);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(tutorialStateProvider);
    final notifier = ref.read(tutorialStateProvider.notifier);
    final currentScreen = notifier.getCurrentScreen();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final mediaPadding = MediaQuery.of(context).padding;

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
      body: Padding(
        padding: EdgeInsets.only(
          top: mediaPadding.top,
          bottom: mediaPadding.bottom,
        ),
        child: Column(
          children: [
            Container(
              color: theme.colorScheme.surface,
              child: BannerAdWidget(uniqueScreenKey: '/tutorial'),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, right: 16.0),
                child: TextButton(
                  onPressed: _onSkipPressed,
                  style: TextButton.styleFrom(
                    foregroundColor:
                    theme.colorScheme.onSurface.withOpacity(0.7),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
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
                                    color: theme.colorScheme.shadow
                                        .withOpacity(0.2),
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
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.3),
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
                                  : theme.colorScheme.onSurface
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
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
                                  duration:
                                  const Duration(milliseconds: 300),
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
                                shadowColor:
                                theme.colorScheme.primary.withOpacity(0.3),
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
            _TutorialNativeAd(),
          ],
        ),
      ),
    );
  }
}

class _TutorialNativeAd extends ConsumerWidget {
  const _TutorialNativeAd();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final centralAdState = ref.watch(centralAdManagementProvider);
    final nativeAdState = ref.watch(nativeAdProvider);

    final adsList = nativeAdState.smallNativeAds;
    final isLoading = nativeAdState.isLoadingSmall;
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

    if (nativeAdState.errorMessage != null && adsList.isEmpty && isAdTypeLoaded) {
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
    if (!nativeAdState.showAds || !isAdTypeLoaded || adsList.isEmpty || ad == null) {
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