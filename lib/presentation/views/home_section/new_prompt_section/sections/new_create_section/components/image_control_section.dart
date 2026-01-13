import 'dart:io';
import 'package:Artleap.ai/providers/keyboard_provider.dart';
import 'package:Artleap.ai/shared/utilities/photo_permission_helper.dart';
import 'package:Artleap.ai/providers/generate_image_provider.dart';
import 'package:Artleap.ai/shared/constants/app_static_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'styles_bottom_sheet.dart';
import 'style_selection_card.dart';
import 'image_preview_redesign.dart';
import 'image_selection_button_redesign.dart';
import 'inspiration_button_redesign.dart';
import 'ratio_selection_redesign.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class ImageControlsRedesign extends ConsumerWidget {
  final VoidCallback onImageSelected;
  final bool isPremiumUser;

  const ImageControlsRedesign({
    super.key,
    required this.onImageSelected,
    this.isPremiumUser = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final provider = ref.watch(generateImageProvider);
    final images = provider.images;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (images.isNotEmpty) ...[
          ImagePreviewRedesign(
            imageFile: images.first,
            onRemove: () =>
                ref.read(generateImageProvider.notifier).clearImagesList(),
          ),
          16.spaceY,
        ],
        _buildControlsGrid(context, ref, theme),
      ],
    );
  }

  Widget _buildControlsGrid(
      BuildContext context, WidgetRef ref, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ImageSelectionButtonRedesign(
                  hasImage: ref.watch(generateImageProvider).images.isNotEmpty,
                  onPressed: () => _handleImagePick(context, ref),
                  showPremiumIcon: !isPremiumUser,
                ),
              ),
              10.spaceX,
              const Expanded(
                child: InspirationButtonRedesign(),
              ),
            ],
          ),
          _buildStyleSelection(context, ref, theme),
          16.spaceY,
          _buildNumberSelection(ref, theme,context),
          16.spaceY,
          _buildAspectRatioSelection(ref, theme),
        ],
      ),
    );
  }

  Widget _buildNumberSelection(WidgetRef ref, ThemeData theme, BuildContext context) {
    final provider = ref.watch(generateImageProvider);
    final selectedImageNumber = provider.selectedImageNumber;
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = (screenWidth / 15).clamp(10, 30).toDouble();
    ref.watch(keyboardVisibleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Number of Images",
          style: AppTextstyle.interMedium(
            fontSize: 12,
            color: theme.colorScheme.onSurface,
          ),
        ),
        8.spaceY,
        Wrap(
          spacing: spacing,
          runSpacing: 16,
          alignment: WrapAlignment.start,
          children: provider.imageNumber.map((number) {
            return RatioSelectionRedesign(
              text: number.toString(),
              isSelected: number == selectedImageNumber,
              onTap: () {
                ref.read(generateImageProvider.notifier).selectedImageNumber = number;
                ref.read(keyboardControllerProvider).hideKeyboard(context);
                AnalyticsService.instance.logButtonClick(buttonName: 'Number of Images');
                final analyticsService = ref.read(analyticsServiceProvider);
                analyticsService.logCustomEvent(
                    eventName: 'Number_of_Images_Selected',
                    parameters: {
                      'screen': 'Prompt_screen',
                    });
              },
              credits: ref.watch(generateImageProvider).images.isEmpty
                  ? number * 2
                  : number * 24,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAspectRatioSelection(WidgetRef ref, ThemeData theme) {
    final selectedRatio = ref.watch(generateImageProvider).aspectRatio;
    ref.watch(keyboardVisibleProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Aspect Ratio",
          style: AppTextstyle.interMedium(
            fontSize: 12,
            color: theme.colorScheme.onSurface,
          ),
        ),
        8.spaceY,
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: freePikAspectRatio.length,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (context, index) => 6.spaceX,
            itemBuilder: (context, index) {
              final ratio = freePikAspectRatio[index];
              return RatioSelectionRedesign(
                text: ratio['title'] ?? '',
                isSelected: ratio['value'] == selectedRatio,
                onTap: () {
                  ref.read(generateImageProvider.notifier).aspectRatio = ratio['value'];
                  ref.read(keyboardControllerProvider).hideKeyboard(context);
                  AnalyticsService.instance.logButtonClick(buttonName: 'Aspect Ratio Button');
                  final analyticsService = ref.read(analyticsServiceProvider);
                  analyticsService.logCustomEvent(
                      eventName: 'Number_of_Ratio_selected',
                      parameters: {
                        'screen': 'Prompt_screen',
                      });
                  },
                isAspectRatio: true,
                aspectRatio: ratio['value'],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStyleSelection(BuildContext context, WidgetRef ref, ThemeData theme) {
    final provider = ref.watch(generateImageProvider);
    final images = provider.images;
    final selectedStyle = provider.selectedStyle;
    final styles = images.isEmpty ? freePikStyles : textToImageStyles;
    final displayedStyles = _reorderStylesWithSelectedFirst(styles, selectedStyle!).take(4);

    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Style",
                style: AppTextstyle.interMedium(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  showStylesBottomSheet(context, ref);
                  AnalyticsService.instance.logButtonClick(buttonName: 'Image Style Button');
                  final analyticsService = ref.read(analyticsServiceProvider);
                  analyticsService.logCustomEvent(
                      eventName: 'More_Image_Styles_button_clicked',
                      parameters: {
                        'screen': 'Prompt_screen',
                      });
                  },
                child: Text(
                  "View All",
                  style: AppTextstyle.interMedium(
                    fontSize: 13,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ...displayedStyles.map((style) {
                  return StyleSelectionCard(
                    title: style['title'] ?? '',
                    icon: style['icon'] ?? '',
                    isSelected: style['title'] == selectedStyle,
                    onTap: () => ref.read(generateImageProvider.notifier).selectedStyle = style['title'],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _reorderStylesWithSelectedFirst(
      List<Map<String, String>> styles,
      String selectedStyle
      ) {
    final selected = styles.firstWhere(
          (style) => style['title'] == selectedStyle,
      orElse: () => styles.first,
    );

    final otherStyles = styles.where((style) => style['title'] != selectedStyle).toList();

    return [selected, ...otherStyles];
  }

  Future<void> _handleImagePick(BuildContext context, WidgetRef ref) async {
    try {
      if (!isPremiumUser) {
        DialogService.showPremiumUpgrade(
          context: context,
          featureName: "Reference Image",
            onConfirm: (){
              Navigator.of(context).pushNamed(ChoosePlanScreen.routeName);
            }
        );
        return;
      }

      if (Platform.isAndroid) {
        final hasPermission = await PhotoPermissionHelper.requestPhotoPermission();
        if (!hasPermission) {
          if (context.mounted) {
            await _showPermissionSettingsDialog(context);
          }
          return;
        }
      }
      await ref.read(generateImageProvider.notifier).pickImage();
      onImageSelected();

    } catch (e) {
      if (context.mounted) {
        appSnackBar('Error', 'Failed to pick image: ${e.toString()}');
      }
    }
  }

  Future<void> _showPermissionSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Photo Access Required',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'This app needs access to your photos to select images. '
              'Please enable photo access in your device settings.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}