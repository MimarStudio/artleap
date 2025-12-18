import 'dart:ui';
import 'package:Artleap.ai/ads/banner_ads/banner_ad_widget.dart';
import 'package:Artleap.ai/providers/bottom_nav_bar_provider.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class BottomNavBar extends ConsumerStatefulWidget {
  static const String routeName = "bottom_nav_bar_screen";

  const BottomNavBar({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends ConsumerState<BottomNavBar> with SingleTickerProviderStateMixin {
  bool _initialized = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_initialized) return;
      _initialized = true;

      final userId = (AppData.instance.userId?.trim().isNotEmpty ?? false)
          ? AppData.instance.userId!.trim()
          : (UserData.ins.userId ?? '').trim();

      if (userId.isEmpty) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        }
        return;
      }
      await ref.read(userProfileProvider.notifier).getUserProfileData(userId);
      final profileState = ref.read(userProfileProvider).valueOrNull;
      final planName = profileState?.userProfile?.user.planName.toLowerCase() ?? 'free';
      final isFreeUser = planName == 'free';
      RemoteConfigService.instance.updateUserPlan(
        isFreeUser: isFreeUser,
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    ref.read(bottomNavBarProvider).setPageIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomNavBarState = ref.watch(bottomNavBarProvider);
    final pageIndex = bottomNavBarState.pageIndex;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: isKeyboardOpen
          ? const SizedBox.shrink()
          : _buildModernNavBar(pageIndex, theme),
      body: Column(
        children: [
          Expanded(
            child: (pageIndex >= 0 && pageIndex < bottomNavBarState.widgets.length)
                ? bottomNavBarState.widgets[pageIndex]
                : Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          if (!isKeyboardOpen) const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildModernNavBar(int currentIndex, ThemeData theme) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withOpacity(0.15),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: theme.colorScheme.onSurface.withOpacity(0.08),
              blurRadius: 15,
              spreadRadius: -5,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSideNavigationItem(
                          icon: FeatherIcons.home,
                          label: 'Home',
                          index: 0,
                          currentIndex: currentIndex,
                          theme: theme,
                          isLeft: true,
                        ),
                        _buildSideNavigationItem(
                          icon: FeatherIcons.edit3,
                          label: 'Create',
                          index: 1,
                          currentIndex: currentIndex,
                          theme: theme,
                          isLeft: true,
                        ),
                      ],
                    ),
                  ),
                  _buildCenterNavigationItem(
                    icon: FeatherIcons.users,
                    label: 'Community',
                    index: 2,
                    currentIndex: currentIndex,
                    theme: theme,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSideNavigationItem(
                          icon: FeatherIcons.video,
                          label: 'Reels',
                          index: 3,
                          currentIndex: currentIndex,
                          theme: theme,
                          isLeft: false,
                        ),
                        _buildSideNavigationItem(
                          icon: FeatherIcons.user,
                          label: 'Profile',
                          index: 4,
                          currentIndex: currentIndex,
                          theme: theme,
                          isLeft: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideNavigationItem({
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    required ThemeData theme,
    required bool isLeft,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isActive
              ? theme.colorScheme.primary.withOpacity(0.12)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isActive ? 22 : 20,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavigationItem({
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    required ThemeData theme,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: isActive ? _scaleAnimation.value : 1.0,
            child: Container(
              width: 70,
              height: 70,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive
                    ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                )
                    : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.onSurface.withOpacity(0.1),
                    theme.colorScheme.onSurface.withOpacity(0.05),
                  ],
                ),
                boxShadow: isActive
                    ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: isActive ? 26 : 22,
                    color: isActive
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.onPrimary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}