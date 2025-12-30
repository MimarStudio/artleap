import 'package:Artleap.ai/domain/community/providers/providers_setup.dart';
import 'components/saved_image_grid.dart';
import 'components/saved_images_header.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class SavedImagesScreen extends ConsumerStatefulWidget {
  static const String routeName = 'saved-images-screens';
  const SavedImagesScreen({super.key});

  @override
  ConsumerState<SavedImagesScreen> createState() => _SavedImagesScreenState();
}

class _SavedImagesScreenState extends ConsumerState<SavedImagesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nativeAdProvider.notifier).loadSmallNativeAds();
    });
  }

  Widget _buildNativeAdWidget(
      NativeAdState adState,
      BuildContext context,
      ) {
    if (!adState.showAds || !adState.isLoaded || adState.nativeAds.isEmpty) {
      return const SizedBox.shrink();
    }

    final ad = adState.nativeAds.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
              Text(
                'Advertisement',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreImages();
    }
  }

  void _loadMoreImages() {
    // Implement pagination logic here
  }

  void _unsaveImage(String imageId) async {
    try {
      await ref.read(saveProvider.notifier).toggleSave(imageId);
      appSnackBar('Removed', 'Removed from saved', backgroundColor:Colors.green);
    } catch (e) {
      appSnackBar('Error', 'Failed to Remove Image', backgroundColor:Colors.redAccent);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final savedStatus = ref.watch(saveProvider);
    final savedCountAsync = ref.watch(savedCountProvider);
    final adState = ref.watch(nativeAdProvider);

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SavedImagesHeader(savedCountAsync: savedCountAsync),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Your Collection',
                      style:
                      Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All the images you\'ve saved for later',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildNativeAdWidget(adState, context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            savedStatus.when(
              data: (savedStatus) {
                final savedImageIds = savedStatus.entries
                    .where((entry) => entry.value == true)
                    .map((entry) => entry.key)
                    .toList();

                if (savedImageIds.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.bookmark_border_rounded,
                      title: 'No Saved Images Yet',
                      subtitle: 'Start building your collection by saving your favorite AI-generated artworks. They\'ll appear here for easy access.',
                      iconColor: theme.colorScheme.primary,
                      actionText: 'Explore Artworks',
                      onAction: () => Navigator.pop(context),
                    ),
                  );
                }

                return SavedImagesGrid(
                  savedImageIds: savedImageIds,
                  onUnsave: _unsaveImage,
                );
              },
              loading: () => SliverFillRemaining(
                child: LoadingState(
                  message: 'Loading your collection...',
                ),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: ErrorState(
                  message: 'We couldn\'t load your saved images. Please try again.',
                  onRetry: () => ref.read(saveProvider.notifier).refreshSavedStatus(),
                  icon: Icons.error_outline_rounded,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );
  }
}