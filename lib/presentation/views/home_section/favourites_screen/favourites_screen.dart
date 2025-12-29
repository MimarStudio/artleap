import 'package:Artleap.ai/ads/interstitial_ads/interstitial_ad_provider.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class FavouritesScreen extends ConsumerStatefulWidget {
  static const String routeName = 'favourite-screen';
  const FavouritesScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _FavouritesScreenState();
}

class _FavouritesScreenState extends ConsumerState<FavouritesScreen> {
  bool _adShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(interstitialAdStateProvider.notifier).loadInterstitialAd();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_adShown) {
          _showInterstitialAd();
        }
      });
    });
  }

  Future<void> _showInterstitialAd() async {
    final adState = ref.read(interstitialAdStateProvider);

    if (adState.isLoaded) {
      final didShow = await ref
          .read(interstitialAdStateProvider.notifier)
          .showInterstitialAd();

      if (didShow) {
        _adShown = true;
        ref.read(interstitialAdStateProvider.notifier).loadInterstitialAd();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favouriteState = ref.watch(favouriteProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.onSurface,
      appBar: AppBar(
        title: Text(
          'My Favorites',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackgroundWidget(
        widget: RefreshIndicator(
          backgroundColor: theme.colorScheme.primary,
          color: theme.colorScheme.onPrimary,
          onRefresh: () async {
            try {
              await ref.read(favouriteProvider).getUserFav(UserData.ins.userId!);
            } catch (e) {
              debugPrint('Refresh error: $e');
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(theme, favouriteState),
                      const SizedBox(height: 24),
                      ResultsTextDropDownWidget(),
                    ],
                  ),
                ),
              ),
              if (favouriteState.isLoading)
                SliverToBoxAdapter(
                  child: _buildLoadingState(size, theme),
                )
              else if (favouriteState.usersFavourites == null ||
                  favouriteState.usersFavourites!.favorites.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(size, theme),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: ResultContainerWidget(
                    data: favouriteState.usersFavourites!.favorites,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme, dynamic favouriteState) {
    final favoriteCount = favouriteState.usersFavourites?.favorites.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.primaryContainer.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: theme.colorScheme.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Collection',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$favoriteCount ${favoriteCount == 1 ? 'favorite' : 'favorites'} saved',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Size size, ThemeData theme) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: LoadingState(
        useShimmer: true,
        loadingType: LoadingType.grid,
        shimmerItemCount: 6,
      ),
    );
  }

  Widget _buildEmptyState(Size size, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: size.width * 0.6,
            height: size.width * 0.4,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_outline_rounded,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No Favorites Yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Save your favorite AI creations from the explore section,\nand they will appear here for quick access.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              ref.read(bottomNavBarProvider).setPageIndex(1);
              await Navigator.pushReplacementNamed(
                  context, BottomNavBar.routeName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              shadowColor: theme.colorScheme.primary.withOpacity(0.3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.explore_rounded,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Explore Creations',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}