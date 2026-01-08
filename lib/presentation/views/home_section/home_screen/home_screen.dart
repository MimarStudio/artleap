import 'package:Artleap.ai/shared/route_export.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(userProfileProvider.notifier).updateUserCredits();
        ref.read(nativeAdProvider.notifier).loadSmallNativeAds();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    if (profileAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final userProfile = profileAsync.value?.userProfile?.user;
    final shouldRefresh = ref.watch(refreshProvider);
    ref.watch(bottomNavBarProvider);
    final theme = Theme.of(context);

    if (shouldRefresh && UserData.ins.userId != null) {
      Future.microtask(() {
        ref.read(userProfileProvider.notifier).getUserProfileData(UserData.ins.userId!);
      });
    }
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      key: _scaffoldKey,
      drawer: ProfileDrawer(
        profileImage: userProfile?.profilePic ?? '',
        userName: userProfile?.username ?? 'Guest',
        userEmail: userProfile?.email ?? 'guest@example.com',
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeScreenTopBar(
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HomeScreenSearchBar(),
                    const SizedBox(height: 20),
                    const PortraitOptions(),
                    const SizedBox(height: 20),
                    AiFiltersGrid(),
                    const SizedBox(height: 24),
                    _HomeNativeAd(),
                    const TrendingStyles(),
                    const SizedBox(height: 24),
                    const PromptTemplates(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeNativeAd extends ConsumerWidget {
  const _HomeNativeAd();

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