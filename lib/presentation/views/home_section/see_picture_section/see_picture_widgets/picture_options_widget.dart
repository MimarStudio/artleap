import 'package:Artleap.ai/providers/download_state_manager.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class PictureOptionsWidget extends ConsumerWidget {
  final String? imageUrl;
  final String? prompt;
  final String? modelName;
  final String? creatorName;
  final String? creatorEmail;
  final Uint8List? uint8ListImage;
  final bool? isGeneratedScreenNavigation;
  final bool? isRecentGeneration;
  final String? currentUserId;
  final String? otherUserId;
  final int? index;
  final String? imageId;
  final String privacy;
  final bool isPremiumUser;

  const PictureOptionsWidget({
    super.key,
    this.imageUrl,
    this.prompt,
    this.modelName,
    this.creatorName,
    this.creatorEmail,
    this.isGeneratedScreenNavigation,
    this.isRecentGeneration,
    this.uint8ListImage,
    this.currentUserId,
    this.otherUserId,
    this.index,
    this.imageId,
    required this.privacy,
    required this.isPremiumUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentUser = otherUserId == UserData.ins.userId;
    final theme = Theme.of(context);
    final downloadState = ref.watch(downloadStateProvider);
    final favState = ref.watch(favProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            "Image Actions",
            style: AppTextstyle.interMedium(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 16,
                children: [
                  _buildActionButton(
                    icon: Icons.favorite_rounded,
                    label: "Favorite",
                    color: Colors.red,
                    context: context,
                    isLiked:
                    ref.watch(favouriteProvider).usersFavourites != null
                        ? ref
                        .watch(favouriteProvider)
                        .usersFavourites!
                        .favorites
                        .any((img) => img.id == imageId)
                        : false,
                    onTap: () async {
                      AnalyticsService.instance.logButtonClick(buttonName: 'Favorite button event');
                      final analyticsService = ref.read(analyticsServiceProvider);
                      analyticsService.logCustomEvent(
                          eventName: 'favourite_button_clicked(see_picture_screen)',
                          parameters: {
                            'screen': 'see_picture_screen',
                          });
                      try {
                        await ref
                            .read(favouriteProvider)
                            .addToFavourite(currentUserId!, imageId!);
                      } catch (e) {}
                    },
                    isLikeButton: true,
                  ),
                  _buildActionButton(
                    icon: Icons.download_rounded,
                    label: "Download",
                    color: Colors.green,
                    context: context,
                    isLoading: downloadState.isDownloading || favState.isDownloading == true,
                    onTap: () => _handleDownload(context, ref),
                  ),
                  _buildActionButton(
                    icon: Icons.share_rounded,
                    label: "Share",
                    color: Colors.blue,
                    context: context,
                    onTap: () async {
                      await Share.shareUri(Uri.parse(imageUrl!));
                      AnalyticsService.instance.logButtonClick(buttonName: 'share button event');
                      final analyticsService = ref.read(analyticsServiceProvider);
                      analyticsService.logCustomEvent(
                          eventName: 'share_button_clicked(see_picture_screen)',
                          parameters: {
                            'screen': 'see_picture_screen',
                          });
                    },
                  ),
                  if (isCurrentUser) ...[
                    _buildActionButton(
                      icon: Icons.lock_rounded,
                      label: "Privacy",
                      color: Colors.purple,
                      context: context,
                      showPremiumIcon: !isPremiumUser,
                      onTap: () async {
                        final analyticsService = ref.read(analyticsServiceProvider);
                        analyticsService.logCustomEvent(
                            eventName: 'privacy_button_clicked(see_picture_screen)',
                            parameters: {
                              'screen': 'see_picture_screen',
                            });
                        if (!isPremiumUser) {
                          DialogService.showPremiumUpgrade(
                              context: context,
                              featureName: "Privacy Settings",
                              onConfirm: () {
                                Navigator.of(context).pushNamed(ChoosePlanScreen.routeName);
                              });
                          return;
                        }

                        await Future.delayed(const Duration(milliseconds: 100));

                        final result = await DialogService.showPrivacyDialog(
                          context: context,
                          imageId: imageId!,
                          userId: currentUserId!,
                          initialPrivacy: _privacyFromString(privacy),
                        );

                        if (result != null) {
                          ref.read(imagePrivacyProvider.notifier).refresh();
                          ref
                              .read(imagePrivacyProvider.notifier)
                              .cachePrivacy(imageId!, result);
                          appSnackBar('Success', 'Privacy settings updated',
                              backgroundColor: AppColors.green);
                        }
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.delete_rounded,
                      label: "Delete",
                      color: Colors.red,
                      isLoading: ref.watch(imageActionsProvider).isDeleting,
                      context: context,
                      onTap: () {
                        AnalyticsService.instance.logButtonClick(buttonName: 'delete button event');
                        final analyticsService = ref.read(analyticsServiceProvider);
                        analyticsService.logCustomEvent(
                            eventName: 'delete_button_clicked(see_picture_screen)',
                            parameters: {
                              'screen': 'see_picture_screen',
                            });
                        DialogService.confirmDelete(
                          context: context,
                          itemName: 'image',
                          onDelete: () async {
                            final success = await ref.read(imageActionsProvider).deleteImage(imageId!);
                            final analyticsService = ref.read(analyticsServiceProvider);
                            analyticsService.logCustomEvent(
                                eventName: 'delete_confirm_image_button_clicked(see_picture_screen)',
                                parameters: {
                                  'screen': 'see_picture_screen',
                                });
                            if (success) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const BottomNavBar()),
                              );
                            } else {
                              Navigator.pop(context);
                              appSnackBar('Error', 'Failed to delete image', backgroundColor: AppColors.red);
                            }
                          },
                        );
                      },
                    ),
                  ],
                  _buildActionButton(
                    icon: Icons.flag_rounded,
                    context: context,
                    label: "Report",
                    color: Colors.orange,
                    onTap: () {
                      final analyticsService = ref.read(analyticsServiceProvider);
                      analyticsService.logCustomEvent(
                          eventName: 'report_image_button_clicked(see_picture_screen)',
                          parameters: {
                            'screen': 'see_picture_screen',
                          });
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) {
                          return ReportImageBottomSheet(
                            imageId: imageId,
                            creatorId: otherUserId,
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleDownload(BuildContext context, WidgetRef ref) async {
    if (imageUrl == null || imageUrl!.isEmpty) {
      appSnackBar('Error', 'No image available to download', backgroundColor: AppColors.red);
      return;
    }
    final analyticsService = ref.read(analyticsServiceProvider);
    analyticsService.logCustomEvent(
        eventName: 'download_image_button_clicked',
        parameters: {
          'screen': 'see_picture_screen',
        });
    try {
      AnalyticsService.instance.logButtonClick(buttonName: 'download button event');

      await DownloadAdHelper.handleDownload(
        ref: ref,
        imageUrl: imageUrl!,
        uint8ListObject: uint8ListImage,
        onDownloadComplete: () {
          appSnackBar('Success', 'Image downloaded successfully', backgroundColor: AppColors.green);
        },
      );

    } catch (e) {
      print('[DOWNLOAD DEBUG] Download failed: $e');
      appSnackBar('Error', 'Failed to download image', backgroundColor: AppColors.red);
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    bool isLoading = false,
    bool isLiked = false,
    bool isLikeButton = false,
    bool showPremiumIcon = false,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return Tooltip(
      message: label,
      child: Container(
        width: 60,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(16),
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
                          size: 28,
                          isLiked: isLiked,
                          likeBuilder: (bool isLiked) {
                            return Icon(
                              isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isLiked
                                  ? color
                                  : color.withOpacity(0.6),
                              size: 28,
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
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                if (showPremiumIcon)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        "PRO",
                        style: AppTextstyle.interMedium(
                          fontSize: 6,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextstyle.interMedium(
                color: theme.colorScheme.onSurface,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}