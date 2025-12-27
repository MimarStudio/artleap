import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:Artleap.ai/shared/route_export.dart';

final isLoadingProvider = StateProvider<bool>((ref) => false);
final adPreloadedProvider = StateProvider<bool>((ref) => false);

ScreenSizeCategory getScreenSizeCategory(BuildContext context) {
  final width = MediaQuery.of(context).size.width;

  if (width < 375) return ScreenSizeCategory.extraSmall;
  if (width < 414) return ScreenSizeCategory.small;
  if (width < 600) return ScreenSizeCategory.medium;
  return ScreenSizeCategory.large;
}

enum ScreenSizeCategory { extraSmall, small, medium, large }

class PromptCreateScreenRedesign extends ConsumerStatefulWidget {
  const PromptCreateScreenRedesign({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PromptCreateScreenRedesignState();
}

class _PromptCreateScreenRedesignState
    extends ConsumerState<PromptCreateScreenRedesign>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _adDialogShown = false;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_isMounted) return;
      try {
        AnalyticsService.instance.logScreenView(screenName: 'generating screen');
        await AdHelper.preloadRewardedAd(ref);
        if (!_isMounted) return;

        final userProfile = ref.read(userProfileProvider).valueOrNull?.userProfile;
        if (userProfile != null && userProfile.user.totalCredits == 0) {
          _showCreditsDialog();
        }
      } catch (e) {
        debugPrint('Error in initState callback: $e');
      }
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scrollController.addListener(_handleScroll);
  }

  Future<bool> _checkNetworkAvailability() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _handleScroll() {
    if (!_isMounted) return;

    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      FocusScope.of(context).unfocus();
      ref.read(keyboardVisibleProvider.notifier).state = false;
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _isValidPrompt(String prompt) {
    final trimmedPrompt = prompt.trim();
    return trimmedPrompt.isNotEmpty && trimmedPrompt.length >= 2;
  }

  void _handleGenerate() async {
    if (!_isMounted) return;

    final theme = Theme.of(context);
    final userProfile = ref.read(userProfileProvider).valueOrNull?.userProfile;
    final generateImageProviderState = ref.watch(generateImageProvider);

    if (userProfile == null || userProfile.user.totalCredits <= 0) {
      if (!_adDialogShown) {
        _adDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isMounted) {
            _showCreditsDialog();
          }
        });
      }
      return;
    }

    final isNetworkAvailable = await _checkNetworkAvailability();
    if (!isNetworkAvailable) {
      if (!_isMounted) return;
      appSnackBar(
        "No Internet Connection",
        "Please check your network connection and try again",
        backgroundColor: theme.colorScheme.error,
      );
      return;
    }

    if (generateImageProviderState.containsSexualWords) {
      if (!_isMounted) return;
      appSnackBar(
        "Warning!",
        "Your prompt contains sexual words.",
        backgroundColor: theme.colorScheme.error,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    ref.read(keyboardVisibleProvider.notifier).state = false;

    if (generateImageProviderState.selectedImageNumber == null &&
        generateImageProviderState.images.isEmpty) {
      if (!_isMounted) return;
      appSnackBar(
        "Error",
        "Please select number of images",
        backgroundColor: theme.colorScheme.error,
      );
      return;
    }

    final promptText = generateImageProviderState.promptTextController.text;
    if (!_isValidPrompt(promptText)) {
      if (!_isMounted) return;
      appSnackBar(
        "Error",
        "Please write a meaningful prompt",
        backgroundColor: theme.colorScheme.error,
      );
      return;
    }

    final isTextToImage = generateImageProviderState.images.isEmpty;
    final requiredCredits = generateImageProviderState.selectedImageNumber! *
        (isTextToImage ? 2 : 24);

    if (userProfile.user.totalCredits < requiredCredits) {
      if (!_isMounted) return;
      appSnackBar(
        "Insufficient Credits",
        "You need $requiredCredits credits to generate ${generateImageProviderState.selectedImageNumber} ${isTextToImage ? 'images' : 'variations'}",
        backgroundColor: theme.colorScheme.error,
      );
      return;
    }

    AnalyticsService.instance
        .logButtonClick(buttonName: 'Generate button event');
    ref.read(isLoadingProvider.notifier).state = true;
    _animationController.forward();

    bool success = false;

    if (isTextToImage) {
      success =
      await ref.read(generateImageProvider.notifier).generateTextToImage();
      if (!success) {
        success = await ref
            .read(generateImageProvider.notifier)
            .generateLeonardoTxt2Image();
      }
    } else {
      await ref.read(generateImageProvider.notifier).generateImgToImg();
    }

    if (!_isMounted) return;

    ref.read(isLoadingProvider.notifier).state = false;
    _animationController.reverse();

    if (success && _isMounted) {
      Navigation.pushNamed(ResultScreenRedesign.routeName);
    } else if (_isMounted) {
      appSnackBar(
        "Error",
        "Failed to Generate Image",
        backgroundColor: theme.colorScheme.error,
      );
    }
  }

  void _showCreditsDialog() {
    if (!_isMounted) return;

    final userProfile = ref.read(userProfileProvider).valueOrNull?.userProfile;
    final planName = userProfile?.user.planName ?? 'Free';
    final isFreePlan = planName.toLowerCase() == 'free';

    showCreditsDialog(
      context: context,
      ref: ref,
      isFreePlan: isFreePlan,
      onWatchAd: () {
        Navigator.of(context).pop();
        _showRewardedAd();
      },
      onUpgrade: () {
        Navigator.of(context).pop();
        Navigation.pushNamed(ChoosePlanScreen.routeName);
      },
      onLater: () {
        Navigator.of(context).pop();
        _adDialogShown = false;
      },
      adDialogShown: _adDialogShown,
      onDialogShownChanged: (value) {
        _adDialogShown = value;
      },
    );
  }

  Future<void> _showRewardedAd() async {
    if (!_isMounted) return;

    await AdHelper.showRewardedAd(
      ref: ref,
      onRewardEarned: (coins) {
        if (!_isMounted) return;

        // Use post-frame callback for snackbar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isMounted) return;
          AdHelper.showRewardSuccessSnackbar(context, coins);
        });

        AdHelper.refreshUserProfileAfterReward(ref);
        _adDialogShown = false;
      },
      onAdDismissed: () {
        if (!_isMounted) return;

        // IMPORTANT: Use WidgetsBinding to handle post-ad actions
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isMounted) return;

          try {
            // First check if we need to pop anything
            final canPop = Navigator.canPop(context);
            if (canPop) {
              // Use a microtask to ensure widget tree is stable
              Future.microtask(() {
                if (_isMounted) {
                  Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                }
              });
            }
          } catch (e) {
            debugPrint('Error in onAdDismissed: $e');
          }
        });

        // Use another post-frame callback for loading the next ad
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isMounted) return;
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!_isMounted) return;
            final adNotifier = ref.read(rewardedAdNotifierProvider.notifier);
            adNotifier.loadAd();
          });
        });

        _adDialogShown = false;
      },
      onAdFailed: () {
        if (!_isMounted) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isMounted) return;
          AdHelper.showAdErrorSnackbar(
            context,
            'Failed to show ad. Please try again.',
          );
        });

        _adDialogShown = false;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isMounted) return;
          Future.delayed(const Duration(seconds: 2), () {
            if (!_isMounted) return;
            final adNotifier = ref.read(rewardedAdNotifierProvider.notifier);
            adNotifier.loadAd();
          });
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMounted)
      return const SizedBox();

    final theme = Theme.of(context);
    final shouldRefresh = ref.watch(refreshProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final screenSize = getScreenSizeCategory(context);
    final planName = ref
        .watch(userProfileProvider)
        .valueOrNull
        ?.userProfile
        ?.user
        .planName ??
        'Free';
    final isFreePlan = planName.toLowerCase() == 'free';
    final isKeyboardVisible = ref.watch(keyboardVisibleProvider);

    if (shouldRefresh && UserData.ins.userId != null) {
      Future.microtask(() {
        if (_isMounted) {
          ref
              .read(userProfileProvider.notifier)
              .getUserProfileData(UserData.ins.userId!);
        }
      });
    }

    final horizontalPadding = screenSize == ScreenSizeCategory.small ||
        screenSize == ScreenSizeCategory.extraSmall
        ? 16.0
        : 24.0;
    final topPadding = screenSize == ScreenSizeCategory.small ||
        screenSize == ScreenSizeCategory.extraSmall
        ? 16.0
        : 24.0;

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (!didPop && !isLoading) {
          ref.read(bottomNavBarProvider).setPageIndex(0);
          if (isKeyboardVisible) {
            ref.read(keyboardControllerProvider).hideKeyboard(context);
          }
        }
      },
      child: Stack(
        children: [
          AppBackgroundWidget(
            widget: GestureDetector(
              onTap: () {
                ref.read(isDropdownExpandedProvider.notifier).state = false;
                if (isKeyboardVisible) {
                  ref.read(keyboardControllerProvider).hideKeyboard(context);
                }
                FocusScope.of(context).unfocus();
              },
              child: Padding(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: topPadding,
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PromptInputRedesign(),
                      const SizedBox(height: 16),
                      PrivacySelectionSection(
                        isPremiumUser: !isFreePlan,
                      ),
                      const SizedBox(height: 16),
                      ImageControlsRedesign(
                        onImageSelected: () {
                          AnalyticsService.instance.logButtonClick(
                            buttonName:
                            'picking image from gallery button event',
                          );
                        },
                        isPremiumUser: !isFreePlan,
                      ),
                      SizedBox(
                          height: screenSize == ScreenSizeCategory.small ||
                              screenSize == ScreenSizeCategory.extraSmall
                              ? 100.0
                              : 120.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          GenerationFooterRedesign(
            onGenerate: _handleGenerate,
            isLoading: isLoading,
          ),
          if (isLoading)
            LoadingOverlayRedesign(
              animationController: _animationController,
              fadeAnimation: _fadeAnimation,
            ),
        ],
      ),
    );
  }
}