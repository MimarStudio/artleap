import 'package:Artleap.ai/domain/community/providers/providers_setup.dart';
import 'package:Artleap.ai/presentation/views/saved_images_screen/components/saved_image_grid.dart';
import 'package:Artleap.ai/presentation/views/saved_images_screen/components/saved_images_header.dart';
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

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreImages();
    }
  }

  void _loadMoreImages() {
    // Implementation for loading more images
  }

  void _unsaveImage(String imageId) async {
    try {
      await ref.read(saveProvider.notifier).toggleSave(imageId);
      appSnackBar('Removed', 'Removed from saved', backgroundColor: Colors.green);
    } catch (e) {
      appSnackBar('Error', 'Failed to Remove Image', backgroundColor: Colors.redAccent);
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
    final mediaPadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
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
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All the images you\'ve saved for later',
                        style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withOpacity(0.7),
                        ),
                      ),
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
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: mediaPadding.bottom),
                        child: Center(
                          child: EmptyState(
                            icon: Icons.bookmark_border_rounded,
                            title: 'No Saved Images Yet',
                            subtitle:
                            'Start building your collection by saving your favorite AI-generated artworks.',
                            iconColor: theme.colorScheme.primary,
                            actionText: 'Explore Artworks',
                            onAction: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    );
                  }

                  return SavedImagesGrid(
                    savedImageIds: savedImageIds,
                    onUnsave: _unsaveImage,
                  );
                },
                loading: () => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: LoadingState(
                      message: 'Loading your collection...',
                    ),
                  ),
                ),
                error: (error, stack) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: ErrorState(
                      message:
                      'We couldn\'t load your saved images. Please try again.',
                      onRetry: () =>
                          ref.read(saveProvider.notifier).refreshSavedStatus(),
                      icon: Icons.error_outline_rounded,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: mediaPadding.bottom + 110),
              ),
            ],
          ),
          Positioned(
            bottom: mediaPadding.bottom + 10,
            left: 16,
            right: 16,
            child: _SavedImagesNativeAd(),
          ),
        ],
      ),
    );
  }
}

class _SavedImagesNativeAd extends ConsumerWidget {
  const _SavedImagesNativeAd();

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
        margin: EdgeInsets.zero,
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
        margin: EdgeInsets.zero,
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
      margin: EdgeInsets.zero,
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