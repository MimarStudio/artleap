import 'dart:ui';
import 'package:Artleap.ai/ads/rewarded_ads/rewarded_Ad_helper.dart';
import 'package:Artleap.ai/presentation/views/feedback/view_feedback_screen.dart';
import 'package:Artleap.ai/shared/route_export.dart';
import '../feedback/feedback_submission_screen.dart';
import 'drawer_components/separator_widget.dart';
import 'drawer_components/glass_circle_button.dart';
import 'drawer_components/profile_menu_item.dart';
import 'drawer_components/theme_selector_menu_item.dart';
import 'social_media_bottom_sheet.dart';

class ProfileDrawer extends ConsumerStatefulWidget {
  final String profileImage;
  final String userName;
  final String userEmail;

  const ProfileDrawer({
    super.key,
    required this.profileImage,
    required this.userName,
    required this.userEmail,
  });

  @override
  _ProfileDrawerState createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends ConsumerState<ProfileDrawer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(screenName: 'Drawer');
      ref.read(userProfileProvider.notifier).getUserProfileData(UserData.ins.userId ?? "");
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final iconSize = screenSize.width * 0.06;

    final profileProvider = ref.watch(userProfileProvider);
    final user = profileProvider.value?.userProfile?.user;
    final isFreePlan = user?.planName.toLowerCase() == 'free';

    return Drawer(
      width: screenSize.width * 0.9,
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            _buildBackground(theme, isDark),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
              child: Container(color: Colors.transparent),
            ),
            _buildContent(context, theme, isDark, screenSize, iconSize, isFreePlan),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            theme.colorScheme.surface.withOpacity(0.9),
            theme.colorScheme.surface.withOpacity(0.8),
          ]
              : [
            const Color(0x5F0A0025),
            const Color(0x5E0A0025),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme, bool isDark, Size screenSize, double iconSize, bool isFreePlan) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: screenSize.height - bottomPadding,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCloseButton(context, iconSize, theme),
            _buildProfileHeader(context, theme, isDark, screenSize),
            if (isFreePlan) _buildUpgradeBanner(screenSize),
            10.spaceY,
            _buildGeneralSection(context, theme, screenSize, isFreePlan),
            10.spaceY,
            _buildAboutSection(context, theme, screenSize),
            _buildSupportSection(context, theme, screenSize), // NEW SECTION
            10.spaceY,
            _buildBottomSection(context, theme, isDark, screenSize),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, double iconSize, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, right: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: GlassCircleButton(
          icon: FeatherIcons.x,
          size: iconSize,
          onPressed: () => Navigator.pop(context),
          theme: theme,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ThemeData theme, bool isDark, Size screenSize) {
    return Padding(
      padding: EdgeInsets.only(left: screenSize.width * 0.05, top: 16, right: 16),
      child: Row(
        children: [
          Container(
            width: screenSize.width * 0.18,
            height: screenSize.width * 0.18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? theme.colorScheme.onSurface.withOpacity(0.3) : AppColors.white.withOpacity(0.3),
                width: 1.5,
              ),
              image: DecorationImage(
                image: widget.profileImage.isEmpty
                    ? const AssetImage(AppAssets.profilepic) as ImageProvider
                    : NetworkImage(widget.profileImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: screenSize.width * 0.04),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userName,
                style: AppTextstyle.interMedium(
                  color: isDark ? theme.colorScheme.onSurface : AppColors.white,
                  fontSize: screenSize.width * 0.04,
                ),
              ),
              SizedBox(height: screenSize.height * 0.01),
              Text(
                widget.userEmail,
                style: AppTextstyle.interMedium(
                  color: isDark ? theme.colorScheme.onSurface.withOpacity(0.8) : AppColors.white.withOpacity(0.8),
                  fontSize: screenSize.width * 0.035,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeBanner(Size screenSize) {
    return Padding(
      padding: EdgeInsets.only(left: screenSize.width * 0.05, top: 16, right: 16),
      child: UpgradeToProBanner(),
    );
  }

  Widget _buildGeneralSection(BuildContext context, ThemeData theme, Size screenSize, bool isFreePlan) {
    return Padding(
      padding: EdgeInsets.only(left: screenSize.width * 0.05, top: 16),
      child: _buildSection(
        context,
        title: "General",
        items: [
          ProfileMenuItem(
            icon: FeatherIcons.user,
            title: "Personal Information",
            onTap: () => Navigator.of(context).pushNamed("personal_info_screen"),
            theme: theme,
          ),
          isFreePlan
              ? ProfileMenuItem(
            icon: FeatherIcons.creditCard,
            title: "You don't have an active subscription",
            onTap: () => Navigator.of(context).pushNamed("choose_plan_screen"),
            color: theme.colorScheme.error,
            theme: theme,
          )
              : ProfileMenuItem(
            icon: FeatherIcons.creditCard,
            title: "Current Plan",
            onTap: () => _navigateTo(context, '/subscription-status'),
            theme: theme,
          ),
          ProfileMenuItem(
            icon: FeatherIcons.shield,
            title: "Privacy Policy",
            onTap: () => _navigateTo(context, '/privacy-policy'),
            theme: theme,
          ),
          ProfileMenuItem(
            icon: FeatherIcons.dollarSign,
            title: "Subscription Plans",
            onTap: () => Navigator.of(context).pushNamed("choose_plan_screen"),
            theme: theme,
          ),
          ProfileMenuItem(
            icon: FeatherIcons.heart,
            title: "Favourites",
            onTap: () => Navigator.pushNamed(context, FavouritesScreen.routeName),
            theme: theme,
          ),
          ProfileMenuItem(
            icon: FeatherIcons.messageCircle,
            title: "View Your Feedback",
            onTap: () => _viewFeedbackScreen(context),
            theme: theme,
          ),
          ThemeSelectorMenuItem(
            theme: theme,
            currentTheme: ref.watch(themeProvider),
            onThemeChanged: (ThemeMode newTheme) {
              _handleThemeChange(newTheme, ref);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, ThemeData theme, Size screenSize) {
    return Padding(
      padding: EdgeInsets.only(left: screenSize.width * 0.05, top: 16),
      child: _buildSection(
        context,
        title: "About",
        items: [
          ProfileMenuItem(
            icon: FeatherIcons.users,
            title: "Follow us on Social Media",
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                isScrollControlled: true,
                builder: (context) => const SocialMediaBottomSheet(),
              );
            },
            theme: theme,
          ),
          ProfileMenuItem(
            icon: FeatherIcons.info,
            title: "About Artleap",
            onTap: () => _navigateTo(context, '/about-artleap'),
            theme: theme,
          ),
        ],
      ),
    );
  }

  // NEW SECTION: Support Section
  Widget _buildSupportSection(BuildContext context, ThemeData theme, Size screenSize) {
    return Padding(
      padding: EdgeInsets.only(left: screenSize.width * 0.05, top: 16),
      child: _buildSection(
        context,
        title: "Support",
        items: [
          ProfileMenuItem(
            icon: FeatherIcons.helpCircle,
            title: "Help Center",
            onTap: () => _navigateTo(context, '/help-screen'),
            theme: theme,
          ),
          ProfileMenuItem(
            icon: FeatherIcons.messageCircle,
            title: "Send Feedback",
            onTap: () => _openFeedbackScreen(context),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, ThemeData theme, bool isDark, Size screenSize) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface.withOpacity(0.5) : const Color(0x991D0751),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: screenSize.width * 0.05, top: 10, bottom: 20),
        child: Column(
          children: [
            ProfileMenuItem(
              icon: FeatherIcons.logOut,
              title: "Logout",
              color: theme.colorScheme.error,
              onTap: () => _showLogoutDialog(context),
              theme: theme,
            ),
            ProfileMenuItem(
              icon: FeatherIcons.trash2,
              title: "Delete Account",
              color: theme.colorScheme.error.withOpacity(0.9),
              onTap: () => _showDeleteAccountDialog(context),
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SeparatorWidget(title: title),
        const SizedBox(height: 10),
        Column(children: items),
      ],
    );
  }

  void _handleThemeChange(ThemeMode newTheme, WidgetRef ref) {
    final profileProvider = ref.read(userProfileProvider);
    final user = profileProvider.value?.userProfile?.user;
    final isFreePlan = user?.planName.toLowerCase() == 'free';

    if (isFreePlan) {
      SimpleRewardedAdHelper.simpleRewardedAd(
        ref: ref,
        onAdDismissed: () {
          ref.read(themeProvider.notifier).setTheme(newTheme);
        },
        onAdFailed: () {
          ref.read(themeProvider.notifier).setTheme(newTheme);
        },
      );
    } else {
      ref.read(themeProvider.notifier).setTheme(newTheme);
    }
  }

  void _navigateTo(BuildContext context, String routeName) {
    AnalyticsService.instance.logButtonClick(buttonName: 'Drawer $routeName Button');
    final analyticsService = ref.read(analyticsServiceProvider);
    analyticsService.logCustomEvent(
        eventName: 'Drawer $routeName Button_clicked',
        parameters: {
          'screen': 'drawer_screen',
        });
    Navigator.pop(context);
    Navigator.pushNamed(context, routeName);
  }

  void _openFeedbackScreen(BuildContext context) {
    AnalyticsService.instance.logButtonClick(buttonName: 'Drawer Feedback Button');
    final analyticsService = ref.read(analyticsServiceProvider);
    analyticsService.logCustomEvent(
      eventName: 'Feedback_button_clicked',
      parameters: {
        'screen': 'drawer_screen',
        'source': 'drawer_menu',
      },
    );

    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedbackSubmissionScreen(
          pageUrl: '/drawer',
          featurePath: 'profile_drawer',
        ),
      ),
    );
  }

  void _viewFeedbackScreen(BuildContext context) {
    AnalyticsService.instance.logButtonClick(buttonName: 'Drawer Feedback Button');
    final analyticsService = ref.read(analyticsServiceProvider);
    analyticsService.logCustomEvent(
      eventName: 'view_feedback_button_clicked',
      parameters: {
        'screen': 'drawer_screen',
        'source': 'drawer_menu',
      },
    );

    Navigator.pop(context); 
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFeedbackListScreen(),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    DialogService.showAppDialog(
      context: context,
      type: DialogType.logout,
      title: 'Logout Account',
      message: 'You\'re about to logout from your account. Are you sure you want to continue?',
      confirmText: 'Logout',
      onConfirm: () {
        AnalyticsService.instance.logButtonClick(buttonName: 'Drawer Logout Button');
        final analyticsService = ref.read(analyticsServiceProvider);
        analyticsService.logCustomEvent(
            eventName: 'Logout_button_clicked',
            parameters: {
              'screen': 'drawer_screen',
            });
        AppLocal.ins.clearUSerData(Hivekey.userId);
        Navigation.pushNamedAndRemoveUntil(LoginScreen.routeName);
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    DialogService.showAppDialog(
      context: context,
      type: DialogType.confirmDelete,
      title: 'Delete Account',
      message: 'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.',
      confirmText: 'Delete Account',
      onConfirm: () {
        AnalyticsService.instance.logButtonClick(buttonName: 'Drawer Delete Account Button');
        final analyticsService = ref.read(analyticsServiceProvider);
        analyticsService.logCustomEvent(
            eventName: 'Delete_account_Button_clicked',
            parameters: {
              'screen': 'drawer_screen',
            });
        ref.read(userProfileProvider.notifier).deActivateAccount(UserData.ins.userId!);
      },
    );
  }
}