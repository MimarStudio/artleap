import 'package:Artleap.ai/widgets/state_widgets/image_loading_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class PostImage extends ConsumerWidget {
  final dynamic image;
  final HomeScreenProvider homeProvider;
  final int index;

  const PostImage({
    super.key,
    required this.image,
    required this.homeProvider,
    required this.index,
  });

  String _getDisplayName(dynamic image) {
    if (image.username != null && image.username!.isNotEmpty) {
      return image.username!;
    }
    if (image.userEmail != null && image.userEmail!.isNotEmpty) {
      return image.userEmail!.split('@')[0];
    }
    return 'Anonymous Artist';
  }

  Widget _buildImageLoading(BuildContext context) {
    return const ImageLoadingEffect(
      width: double.infinity,
      height: 450,
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: 450,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              size: 60,
            ),
            const SizedBox(height: 12),
            Text(
              'Image not available',
              style: AppTextstyle.interRegular(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isImageVisible = homeProvider.visibleImages.contains(image.imageUrl);

    return VisibilityDetector(
      key: Key('image-${image.id}'),
      onVisibilityChanged: (info) {
        if (!context.mounted) return;
        const double bufferZone = 500.0;
        final bool isInBufferZone =
            info.visibleBounds.top - bufferZone < 0 &&
                info.visibleBounds.bottom + bufferZone > 0;

        if (isInBufferZone && !homeProvider.visibleImages.contains(image.imageUrl)) {
          ref.read(homeScreenProvider).visibilityInfo(info, image.imageUrl);
        }
      },
      child: GestureDetector(
        onTap: () {
          AnalyticsService.instance.logButtonClick(buttonName: 'Image Clicked(Community Post Page)');
          final analyticsService = ref.read(analyticsServiceProvider);
          analyticsService.logCustomEvent(
              eventName: 'Image_clicked(Community Post Page)',
              parameters: {
                'screen': 'community_post_page',
              });
          Navigation.pushNamed(
            SeePictureScreen.routeName,
            arguments: SeePictureParams(
              imageId: image.id,
              userId: image.userId,
              profileName: image.username ?? _getDisplayName(image),
              image: image.imageUrl,
              prompt: image.prompt,
              modelName: image.modelName,
              createdDate: image.createdAt,
              index: index,
              creatorEmail: image.userEmail,
              privacy: image.privacy,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          height: 450,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
          ),
          child: isImageVisible
              ? CachedNetworkImage(
            imageUrl: image.imageUrl,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            placeholder: (context, url) => _buildImageLoading(context),
            errorWidget: (context, url, error) => _buildErrorPlaceholder(context),
            cacheKey: image.imageUrl,
            maxWidthDiskCache: 1080,
            maxHeightDiskCache: 1080,
            useOldImageOnUrlChange: true,
          ) : _buildImageLoading(context),
        ),
      ),
    );
  }
}