import 'package:Artleap.ai/shared/route_export.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SeePictureScreen extends ConsumerStatefulWidget {
  static const routeName = "see_picture_screen";
  final SeePictureParams? params;
  const SeePictureScreen({super.key, this.params});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SeePictureScreenState();
}

class _SeePictureScreenState extends ConsumerState<SeePictureScreen> {
  bool _adDialogShown = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(screenName: 'see image screen');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final centralAdNotifier = ref.read(centralAdManagementProvider.notifier);
      centralAdNotifier.setWidgetRef(ref);
      Future.delayed(const Duration(milliseconds: 500), () {
        ref.read(nativeAdProvider.notifier).loadSmallNativeAds();
        centralAdNotifier.loadRewardedAd();
      });

      final userProfile = ref.read(userProfileProvider).value!.userProfile;
      if (userProfile != null && userProfile.user.totalCredits == 0) {
        _showCreditsDialog();
      }

      final currentPrivacy =
      _privacyFromString(widget.params?.privacy ?? 'Public');
      ref
          .read(imagePrivacyProvider.notifier)
          .cachePrivacy(widget.params!.imageId!, currentPrivacy);
    });
  }

  void _showCreditsDialog() {
    final userProfile = ref.read(userProfileProvider).value!.userProfile;
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
    final centralAdNotifier = ref.read(centralAdManagementProvider.notifier);

    await centralAdNotifier.showRewardedAd(
      onRewardEarned: (coins) {
        AdHelper.showRewardSuccessSnackbar(context, coins);
        AdHelper.refreshUserProfileAfterReward(ref);
        _adDialogShown = false;
      },
      onAdDismissed: () {
        centralAdNotifier.loadRewardedAd();
        _adDialogShown = false;
      },
      onAdFailed: () {
        AdHelper.showAdErrorSnackbar(
          context,
          'Failed to show ad. Please try again.',
        );
        _adDialogShown = false;

        Future.delayed(const Duration(seconds: 2), () {
          centralAdNotifier.loadRewardedAd();
        });
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final planName = ref.watch(userProfileProvider).value!.userProfile?.user.planName ?? 'Free';
    final isFreePlan = planName.toLowerCase() == 'free';
    final cachedPrivacy = ref.watch(imagePrivacyForImageProvider(widget.params!.imageId ?? ''));
    final currentPrivacy = cachedPrivacy ?? _privacyFromString(widget.params!.privacy ?? 'Public');

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0A0A0A) : Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          _buildCustomAppBar(theme, isDark),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    if (widget.params!.userId != UserData.ins.userId)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ProfileNameFollowWidget(
                          profileName: widget.params!.profileName,
                          userId: widget.params!.userId,
                        ),
                      ),
                    const SizedBox(height: 24),
                    _buildImageSection(theme, isDark),
                    const SizedBox(height: 16),
                    _SeePictureNativeAd(),
                    const SizedBox(height: 24),
                    PictureOptionsWidget(
                      imageId: widget.params!.imageId,
                      creatorName: widget.params!.profileName,
                      imageUrl: widget.params!.image ?? "",
                      prompt: widget.params!.prompt,
                      modelName: widget.params!.modelName,
                      uint8ListImage: widget.params!.uint8ListImage,
                      currentUserId: UserData.ins.userId,
                      index: widget.params!.index,
                      creatorEmail: widget.params!.creatorEmail,
                      otherUserId: widget.params!.userId,
                      privacy: _privacyToString(currentPrivacy),
                      isPremiumUser: !isFreePlan,
                    ),
                    const SizedBox(height: 28),
                    PromptTextWidget(
                      prompt: widget.params!.prompt,
                    ),
                    const SizedBox(height: 28),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(ThemeData theme, bool isDark) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              child: IconButton(
                onPressed: () {
                  Navigation.pop();
                },
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : Colors.black,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  "AI Artwork Details",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
              child: IconButton(
                onPressed: () {
                  Navigation.pop();
                },
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.white : Colors.black,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              GestureDetector(
                onTap: () {
                  Navigation.pushNamed(FullImageViewerScreen.routeName,
                      arguments: FullImageScreenParams(
                        Image: widget.params!.image!,
                      ));
                },
                child: Container(
                  height: 380,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF1E1E1E) : Color(0xFFF5F5F5),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: widget.params!.image!,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 300),
                    placeholder: (context, url) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [Color(0xFF2D2D2D), Color(0xFF1E1E1E)]
                              : [Color(0xFFF0F0F0), Color(0xFFE5E5E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.photo,
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                          size: 50,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: isDark ? Color(0xFF2D2D2D) : Color(0xFFF5F5F5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade400,
                              size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load image',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigation.pushNamed(FullImageViewerScreen.routeName,
                          arguments: FullImageScreenParams(
                            Image: widget.params!.image!,
                          ));
                    },
                    splashColor: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    highlightColor: Colors.transparent,
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.7)
                        : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fullscreen_rounded,
                          size: 14,
                          color: isDark ? Colors.white70 : Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        'View fullscreen',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _privacyToString(ImagePrivacy privacy) {
    switch (privacy) {
      case ImagePrivacy.public:
        return 'public';
      case ImagePrivacy.private:
        return 'private';
    }
  }

  ImagePrivacy _privacyFromString(String privacy) {
    switch (privacy.toLowerCase()) {
      case 'public':
        return ImagePrivacy.public;
      case 'private':
        return ImagePrivacy.private;
      default:
        return ImagePrivacy.public;
    }
  }
}

class _SeePictureNativeAd extends ConsumerWidget {
  const _SeePictureNativeAd();

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