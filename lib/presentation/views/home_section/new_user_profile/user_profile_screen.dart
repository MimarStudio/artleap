import 'package:Artleap.ai/ads/interstitial_ads/interstitial_ad_provider.dart';
import '../profile_screen/profile_screen_widgets/my_creations_widget.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});
  static const String routeName = "user_profile_screen";

  @override
  ConsumerState<UserProfileScreen> createState() =>
      _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  late final ProviderSubscription<InterstitialAdState> _adListener;

  bool _isAdNavigationPending = false;
  String? _pendingRouteName;

  @override
  void initState() {
    super.initState();

    /// Post-frame setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (UserData.ins.userId != null) {
        ref
            .read(userProfileProvider.notifier)
            .getUserProfileData(UserData.ins.userId!);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }

      AnalyticsService.instance
          .logScreenView(screenName: 'profile screen');

      ref
          .read(interstitialAdStateProvider.notifier)
          .loadInterstitialAd();
    });

    /// ✅ CORRECT Riverpod listener for initState
    _adListener = ref.listenManual<InterstitialAdState>(
      interstitialAdStateProvider,
          (previous, next) {
        if (previous?.isShowing == true &&
            next.isShowing == false &&
            _isAdNavigationPending) {
          _executeNavigation();
        }
      },
    );
  }

  /// Trigger navigation with ad
  Future<void> _handleNavigation(String routeName) async {
    if (_isAdNavigationPending) return;

    _isAdNavigationPending = true;
    _pendingRouteName = routeName;

    final didShowAd = await ref
        .read(interstitialAdStateProvider.notifier)
        .showInterstitialAd();

    /// If ad failed → navigate immediately
    if (!didShowAd) {
      _executeNavigation();
    }
  }

  /// Execute actual navigation
  void _executeNavigation() {
    final route = _pendingRouteName;

    _resetNavigationState();

    if (!mounted || route == null) return;

    if (route == 'saved-images-screens') {
      Navigator.of(context).pushNamed(route);
    } else if (route == NotificationScreen.routeName) {
      Navigator.of(context)
          .pushNamed(NotificationScreen.routeName);
    }
  }

  void _resetNavigationState() {
    _isAdNavigationPending = false;
    _pendingRouteName = null;
  }

  @override
  void dispose() {
    _adListener.close(); // ✅ REQUIRED
    _resetNavigationState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    final userProfileAsync = ref.watch(userProfileProvider);

    if (userProfileAsync.isLoading ||
        userProfileAsync.value?.userProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userPersonalData = userProfileAsync.value!.userProfile!;
    final user = userPersonalData.user;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          ref.read(bottomNavBarProvider).setPageIndex(0);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.deepPurple,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              /// Top actions
              SliverToBoxAdapter(
                child: SizedBox(
                  height: screenHeight * 0.2,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding:
                      const EdgeInsets.only(top: 16, right: 16),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final userId = UserData.ins.userId;
                          if (userId == null) {
                            return const SizedBox();
                          }

                          final notifications =
                          ref.watch(notificationProvider(userId));

                          final unreadCount =
                          notifications.maybeWhen(
                            data: (notifs) =>
                            notifs.where((n) => !n.isRead).length,
                            orElse: () => 0,
                          );

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.save,
                                    color: theme
                                        .colorScheme.onPrimary),
                                tooltip: "Saved Images",
                                onPressed: () {
                                  _handleNavigation(
                                      'saved-images-screens');
                                },
                              ),
                              IconButton(
                                icon: Badge(
                                  label: unreadCount > 0
                                      ? Text(unreadCount.toString())
                                      : null,
                                  child: Icon(
                                    Icons.notifications,
                                    color: theme
                                        .colorScheme.onPrimary,
                                    size: 30,
                                  ),
                                ),
                                onPressed: () {
                                  _handleNavigation(
                                      NotificationScreen.routeName);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              /// Profile content
              SliverToBoxAdapter(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: screenHeight -
                        (screenHeight * 0.2) -
                        MediaQuery.of(context).padding.top,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 16 + safeAreaBottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -60),
                          child: Padding(
                            padding:
                            const EdgeInsets.only(left: 15.0),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                _buildProfileHeader(
                                    user, theme, userPersonalData),
                              ],
                            ),
                          ),
                        ),
                        MyCreationsWidget(
                          listofCreations:
                          userPersonalData.user.images,
                          userName: user.username ?? 'User',
                          userId: user.id,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
      dynamic user, ThemeData theme, dynamic userPersonalData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
            Border.all(color: theme.colorScheme.surface, width: 4),
            image: user.profilePic != null &&
                user.profilePic!.isNotEmpty
                ? DecorationImage(
              image: NetworkImage(user.profilePic!),
              fit: BoxFit.cover,
            )
                : const DecorationImage(
              image: AssetImage(AppAssets.artstyle1),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          (user.username ?? 'User').toUpperCase(),
          style: AppTextstyle.interBold(
              fontSize: 22,
              color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          '@${user.email}',
          style: AppTextstyle.interMedium(
            fontSize: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatColumn(
              userPersonalData.user.followers.length.toString(),
              'Followers',
              theme,
            ),
            const SizedBox(width: 30),
            _buildStatColumn(
              userPersonalData.user.following.length.toString(),
              'Following',
              theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatColumn(
      String value, String label, ThemeData theme) {
    return Row(
      children: [
        Text(
          value,
          style: AppTextstyle.interBold(
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextstyle.interRegular(
            fontSize: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
