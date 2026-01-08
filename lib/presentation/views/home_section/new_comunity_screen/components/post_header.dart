import 'package:Artleap.ai/shared/route_export.dart';

class PostHeader extends ConsumerStatefulWidget {
  final dynamic image;
  final String? imageId;
  final String? profilePic;
  final String? imageUrl;
  final Uint8List? uint8ListImage;
  final String? currentUserId;
  final String? otherUserId;

  const PostHeader({
    super.key,
    required this.image,
    this.imageId,
    this.imageUrl,
    this.uint8ListImage,
    this.currentUserId,
    this.otherUserId,
    required this.profilePic,
  });

  @override
  ConsumerState<PostHeader> createState() => _PostHeaderState();
}

class _PostHeaderState extends ConsumerState<PostHeader> {
  late dynamic _filteredImage;
  late String? _filteredImageUrl;
  late String? _filteredImageId;
  late String? _filteredOtherUserId;

  @override
  void initState() {
    super.initState();
    _filterImageData();
  }

  @override
  void didUpdateWidget(PostHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image ||
        oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imageId != widget.imageId ||
        oldWidget.otherUserId != widget.otherUserId) {
      _filterImageData();
    }
  }

  void _filterImageData() {
    _filteredImage = widget.image;
    _filteredImageUrl =
        widget.imageUrl ?? widget.image?.imageUrl ?? widget.image?.url;
    _filteredImageId =
        widget.imageId ?? widget.image?.id ?? widget.image?.imageId;
    _filteredOtherUserId =
        widget.otherUserId ?? widget.image?.userId ?? widget.image?.creatorId;
  }

  String _getUserInitials(dynamic image) {
    final processedImage = image ?? _filteredImage;
    if (processedImage.username != null &&
        processedImage.username!.isNotEmpty) {
      final names = processedImage.username!.split(' ');
      if (names.length > 1) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      }
      return processedImage.username!.substring(0, 1).toUpperCase();
    }
    if (processedImage.userEmail != null &&
        processedImage.userEmail!.isNotEmpty) {
      return processedImage.userEmail!.substring(0, 1).toUpperCase();
    }
    return 'A';
  }

  String _getDisplayName(dynamic image) {
    final processedImage = image ?? _filteredImage;
    if (processedImage.username != null &&
        processedImage.username!.isNotEmpty) {
      return processedImage.username!;
    }
    if (processedImage.userEmail != null &&
        processedImage.userEmail!.isNotEmpty) {
      return processedImage.userEmail!.split('@')[0];
    }
    return 'Anonymous Artist';
  }

  String _getTimeAgo(dynamic image) {
    final processedImage = image ?? _filteredImage;

    if (processedImage.createdAt == null) return 'Recently';

    // parse the string to DateTime
    final createdAt = DateTime.parse(processedImage.createdAt).toLocal();
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} week${(difference.inDays / 7).floor() > 1 ? 's' : ''} ago';
    } else {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
    }
  }

  void _handleDownload(BuildContext context) {
    final theme = Theme.of(context);
    final downloadUrl = _filteredImageUrl;
    final downloadUint8List = widget.uint8ListImage;
    ref.read(favProvider).downloadImage(downloadUrl!, uint8ListObject: downloadUint8List);
    AnalyticsService.instance.logButtonClick(buttonName: 'Download button(Community Post Page)');
    final analyticsService = ref.read(analyticsServiceProvider);
    analyticsService.logCustomEvent(
        eventName: 'download_button_clicked(Community Post Page)',
        parameters: {
          'screen': 'community_post_page',
        });
    appSnackBar('Downloading', 'Downloading image...',backgroundColor: theme.colorScheme.primary);
  }

  void _handleShare(BuildContext context) async {
    final theme = Theme.of(context);
    final shareUrl = _filteredImageUrl;
    AnalyticsService.instance.logButtonClick(buttonName: 'Share button(Community Post Page)');
    final analyticsService = ref.read(analyticsServiceProvider);
    analyticsService.logCustomEvent(
        eventName: 'share_button_clicked(Community Post Page)',
        parameters: {
          'screen': 'community_post_page',
        });
    if (shareUrl != null) {
      await Share.shareUri(Uri.parse(shareUrl));
    } else {
      appSnackBar('Error', 'Unable to share image',backgroundColor: AppColors.red);
    }
  }

  void _handleReport(BuildContext context) {
    final reportImageId = _filteredImageId;
    final reportCreatorId = _filteredOtherUserId;
    AnalyticsService.instance.logButtonClick(buttonName: 'Report button(Community Post Page)');
    final analyticsService = ref.read(analyticsServiceProvider);
    analyticsService.logCustomEvent(
        eventName: 'report_button_clicked(Community Post Page)',
        parameters: {
          'screen': 'community_post_page',
        });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportImageBottomSheet(
        imageId: reportImageId,
        creatorId: reportCreatorId,
      ),
    );
  }

  void _handleMoreOptions(String value, BuildContext context) {
    switch (value) {
      case 'download':
        _handleDownload(context);
        break;
      case 'share':
        _handleShare(context);
        break;
      case 'report':
        _handleReport(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          InkWell(
            onTap: _filteredOtherUserId != null
                ? () {
              AnalyticsService.instance.logButtonClick(buttonName: 'Other User Profile(Community Post Page)');
              final analyticsService = ref.read(analyticsServiceProvider);
              analyticsService.logCustomEvent(
                  eventName: 'User_profile_clicked(Community Post Page)',
                  parameters: {
                    'screen': 'community_post_page',
                  });
              Navigation.pushNamed(
                OtherUserProfileScreen.routeName,
                arguments: OtherUserProfileParams(
                  userId: _filteredOtherUserId!,
                  profileName: _getDisplayName(_filteredImage),
                ),
              );
            }
                : null,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: widget.profilePic != null
                    ? Image.network(
                  widget.profilePic!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      _getUserInitials(_filteredImage),
                      style: AppTextstyle.interBold(
                        fontSize: 18,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                )
                    : Center(
                  child: Text(
                    _getUserInitials(_filteredImage),
                    style: AppTextstyle.interBold(
                      fontSize: 18,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: _filteredOtherUserId != null
                      ? () {
                    Navigation.pushNamed(
                      OtherUserProfileScreen.routeName,
                      arguments: OtherUserProfileParams(
                        userId: _filteredOtherUserId!,
                        profileName: _getDisplayName(_filteredImage),
                      ),
                    );
                  }
                      : null,
                  child: Text(
                    _getDisplayName(_filteredImage),
                    style: AppTextstyle.interBold(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'AI Art Creator • ${_getTimeAgo(_filteredImage)}',
                  style: AppTextstyle.interRegular(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.more_horiz,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            onSelected: (value) => _handleMoreOptions(value, context),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(
                      Icons.download_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Download',
                      style: AppTextstyle.interMedium(
                        color: theme.colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(
                      Icons.share_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Share',
                      style: AppTextstyle.interMedium(
                        color: theme.colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Report',
                      style: AppTextstyle.interMedium(
                        color: theme.colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}