import 'package:Artleap.ai/providers/download_state_manager.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class ActionButtonsRow extends ConsumerWidget {
  final WidgetRef ref;
  const ActionButtonsRow({super.key, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final generatedImages = ref.watch(generateImageProvider).generatedImage;
    final generatedTextToImageData =
        ref.watch(generateImageProvider).generatedTextToImageData;
    final isLoading = ref.watch(generateImageProvider).isGenerateImageLoading;

    final currentImageData =
    _getCurrentImageData(generatedImages, generatedTextToImageData);

    if (isLoading || currentImageData == null) {
      return _buildLoadingButtons(theme);
    }

    return _buildActionButtons(context, ref, currentImageData, theme);
  }

  dynamic _getCurrentImageData(
      List<dynamic> generatedImages, List<dynamic> generatedTextToImageData) {
    if (generatedTextToImageData.isNotEmpty) {
      return generatedTextToImageData.first;
    } else if (generatedImages.isNotEmpty) {
      return generatedImages.first;
    }
    return null;
  }

  Widget _buildLoadingButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(4, (index) => _buildLoadingButton(theme)),
      ),
    );
  }

  Widget _buildLoadingButton(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, dynamic imageData, ThemeData theme) {
    final isCurrentUser = _isCurrentUserImage(imageData);
    final imageId = imageData.id ?? '';
    final imageUrl = imageData.imageUrl ?? '';
    final privacy = imageData.privacy ?? 'public';

    final List<Widget> buttons = [
      _buildFavoriteButton(context, ref, imageId, theme),
      _buildDownloadButton(context, ref, imageUrl, theme),
      _buildShareButton(context, ref, imageUrl, theme),
      _buildReportButton(context, ref, imageId, theme)
    ];

    if (isCurrentUser) {
      buttons.addAll([
        _buildDeleteButton(context, ref, imageId, theme),
      ]);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: buttons,
      ),
    );
  }

  bool _isCurrentUserImage(dynamic imageData) {
    return true;
  }

  Widget _buildFavoriteButton(
      BuildContext context, WidgetRef ref, String imageId, ThemeData theme) {
    final isLiked = ref.watch(favouriteProvider).usersFavourites != null
        ? ref
        .watch(favouriteProvider)
        .usersFavourites!
        .favorites
        .any((img) => img.id == imageId)
        : false;

    return _buildActionButton(
      icon: Icons.favorite_rounded,
      label: 'Favorite',
      color: Colors.red,
      theme: theme,
      isLikeButton: true,
      isLiked: isLiked,
      onTap: () async {
        AnalyticsService.instance.logButtonClick(buttonName: 'Favorite button event');
        final analyticsService = ref.read(analyticsServiceProvider);
        analyticsService.logCustomEvent(
            eventName: 'favourite_button_clicked(screen_after_result)',
            parameters: {
              'screen': 'screen_after_result',
            });
        try {
          final currentUserId = UserData.ins.userId ?? '';
          if (currentUserId.isNotEmpty && imageId.isNotEmpty) {
            await ref
                .read(favouriteProvider)
                .addToFavourite(currentUserId, imageId);
          }
        } catch (e) {
          // Handle error
        }
      },
    );
  }

  Widget _buildDownloadButton(
      BuildContext context, WidgetRef ref, String imageUrl, ThemeData theme) {
    final downloadState = ref.watch(downloadStateProvider);
    final favState = ref.watch(favProvider);

    final isLoading = downloadState.isDownloading || favState.isDownloading == true;

    // Get remaining downloads for next ad
    final remainingForAd = ref.read(downloadStateProvider.notifier).getRemainingDownloadsForNextAd();
    final downloadCount = downloadState.downloadCount;

    return Column(
      children: [
        Tooltip(
          message: remainingForAd == 0
              ? 'Next download will show an ad'
              : 'Downloads: $downloadCount (Next ad in $remainingForAd)',
          child: _buildActionButton(
            icon: Icons.download_rounded,
            label: 'Download',
            color: Colors.green,
            theme: theme,
            isLoading: isLoading,
            onTap: () => _handleDownload(context, ref, imageUrl),
          ),
        ),
        // Optional: Show download counter badge
        if (downloadCount > 0)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$downloadCount',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleDownload(BuildContext context, WidgetRef ref, String imageUrl) async {
    AnalyticsService.instance.logButtonClick(buttonName: 'download button event');
    final analyticsService = ref.read(analyticsServiceProvider);
    analyticsService.logCustomEvent(
        eventName: 'download_button_clicked(screen_after_result)',
        parameters: {
          'screen': 'screen_after_result',
        });
    if (imageUrl.isEmpty) {
      appSnackBar('Error', 'No image available to download', backgroundColor: AppColors.red);
      return;
    }
    try {
      await DownloadAdHelper.handleDownload(
        ref: ref,
        imageUrl: imageUrl,
        uint8ListObject: null,
        onDownloadComplete: () {
          appSnackBar('Success', 'Image downloaded successfully', backgroundColor: AppColors.green);
          final downloadCount = ref.read(downloadStateProvider.notifier).getDownloadCount();
          final remaining = ref.read(downloadStateProvider.notifier).getRemainingDownloadsForNextAd();
          print('[DOWNLOAD DEBUG] Total downloads: $downloadCount, Next ad in: $remaining downloads');
        },
      );

    } catch (e) {
      print('[DOWNLOAD DEBUG] Download failed: $e');
      appSnackBar('Error', 'Failed to download image', backgroundColor: AppColors.red);
    }
  }

  Widget _buildShareButton(
      BuildContext context, WidgetRef ref, String imageUrl, ThemeData theme) {
    return _buildActionButton(
      icon: Icons.share_rounded,
      label: 'Share',
      color: Colors.blue,
      theme: theme,
      onTap: () async {
        AnalyticsService.instance.logButtonClick(buttonName: 'share button event');
        final analyticsService = ref.read(analyticsServiceProvider);
        analyticsService.logCustomEvent(
            eventName: 'share_button_clicked(screen_after_result)',
            parameters: {
              'screen': 'screen_after_result',
            });
        await Share.shareUri(Uri.parse(imageUrl));
      },
    );
  }

  Widget _buildDeleteButton(
      BuildContext context, WidgetRef ref, String imageId, ThemeData theme) {
    final isLoading = ref.watch(imageActionsProvider).isDeleting;

    return _buildActionButton(
      icon: Icons.delete_rounded,
      label: 'Delete',
      color: Colors.red,
      theme: theme,
      isLoading: isLoading,
      onTap: () {
        AnalyticsService.instance.logButtonClick(buttonName: 'delete button event');
        final analyticsService = ref.read(analyticsServiceProvider);
        analyticsService.logCustomEvent(
            eventName: 'delete_image_button_clicked(screen_after_result)',
            parameters: {
              'screen': 'screen_after_result',
            });
        DialogService.confirmDelete(
          context: context,
          itemName: 'image',
          onDelete: () async {
            final success = await ref.read(imageActionsProvider).deleteImage(imageId);
            final analyticsService = ref.read(analyticsServiceProvider);
            analyticsService.logCustomEvent(
                eventName: 'confirm_delete_button_clicked(screen_after_result)',
                parameters: {
                  'screen': 'screen_after_result',
                });
            if (success) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const BottomNavBar()),
              );
            } else {
              Navigator.pop(context);
              appSnackBar('Error', 'Failed to Delete Image',backgroundColor: AppColors.red);
            }
          },
        );
      },
    );
  }

  Widget _buildReportButton(
      BuildContext context, WidgetRef ref, String imageId, ThemeData theme) {
    return _buildActionButton(
      icon: Icons.flag_rounded,
      label: 'Report',
      color: Colors.orange,
      theme: theme,
      onTap: () {
        final analyticsService = ref.read(analyticsServiceProvider);
        analyticsService.logCustomEvent(
            eventName: 'report_button_clicked(screen_after_result)',
            parameters: {
              'screen': 'screen_after_result',
            });
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return ReportImageBottomSheet(
              imageId: imageId,
              creatorId: UserData.ins.userId,
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
    bool isLoading = false,
    bool isLiked = false,
    bool isLikeButton = false,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(25),
                child: isLoading
                    ? Center(
                  child: LoadingAnimationWidget.threeArchedCircle(
                    color: color,
                    size: 24,
                  ),
                )
                    : isLikeButton
                    ? Center(
                  child: LikeButton(
                    size: 24,
                    isLiked: isLiked,
                    likeBuilder: (bool isLiked) {
                      return Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color:
                        isLiked ? color : color.withOpacity(0.6),
                        size: 24,
                      );
                    },
                    bubblesColor: BubblesColor(
                      dotPrimaryColor: color,
                      dotSecondaryColor: color,
                    ),
                    onTap: (isLiked) async {
                      onTap();
                      return !isLiked;
                    },
                  ),
                )
                    : Center(
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}