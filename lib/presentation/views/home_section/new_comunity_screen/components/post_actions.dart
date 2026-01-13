import 'package:Artleap.ai/domain/community/providers/providers_setup.dart';
import 'comment_bottom_sheet.dart';
import 'package:Artleap.ai/shared/route_export.dart';

final likeAnimationProvider = StateProvider.family<bool, String>((ref, imageId) => false);

class PostActions extends ConsumerWidget {
  final dynamic image;

  const PostActions({super.key, required this.image});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final imageId = image.id?.toString() ?? '${image.hashCode}';

    final likeStatus = ref.watch(likeProvider(imageId));
    final saveStatus = ref.watch(saveProvider);
    final likeCountAsync = ref.watch(likeCountProvider(imageId));
    final commentCountAsync = ref.watch(commentCountProvider(imageId));

    final isLiked = likeStatus.maybeWhen(
      data: (likeStatus) => likeStatus[imageId] ?? false,
      orElse: () => false,
    );

    final isSaved = saveStatus.maybeWhen(
      data: (saveStatus) => saveStatus[imageId] ?? false,
      orElse: () => false,
    );

    final likeCount = likeCountAsync.maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );

    final commentCount = commentCountAsync.maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _LikeButton(
                imageId: imageId,
                isLiked: isLiked,
                likeCount: likeCount,
                theme: theme,
              ),
              const SizedBox(width: 12),
              _CommentButton(
                imageId: imageId,
                commentCount: commentCount,
                theme: theme,
                image: image,
                context: context,
                ref: ref,
              ),
              const Spacer(),
              _SaveButton(
                imageId: imageId,
                isSaved: isSaved,
                theme: theme,
              ),
            ],
          ),
          if (likeCount > 0) ...[
            const SizedBox(height: 12),
            _LikeCountText(likeCount: likeCount, theme: theme),
          ],
        ],
      ),
    );
  }
}

class _LikeButton extends ConsumerWidget {
  final String imageId;
  final bool isLiked;
  final int likeCount;
  final ThemeData theme;

  const _LikeButton({
    required this.imageId,
    required this.isLiked,
    required this.likeCount,
    required this.theme,
  });

  void _toggleLike(WidgetRef ref) async {
    try {
      await ref.read(likeProvider(imageId).notifier).toggleLike();
      AnalyticsService.instance.logButtonClick(buttonName: 'Like button(Community Post Page)');
      final analyticsService = ref.read(analyticsServiceProvider);
      analyticsService.logCustomEvent(
          eventName: 'like_button_clicked(Community Post Page)',
          parameters: {
            'screen': 'screen_after_result',
          });
      ref.invalidate(likeCountProvider(imageId));
    } catch (e) {
      appSnackBar('Error', 'Failed to update like: $e', backgroundColor: AppColors.red);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ActionButton(
      onTap: () => _toggleLike(ref),
      isActive: isLiked,
      activeColor: theme.colorScheme.error,
      icon: isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
      count: likeCount,
      theme: theme,
    );
  }
}

class _CommentButton extends ConsumerWidget {
  final String imageId;
  final int commentCount;
  final ThemeData theme;
  final BuildContext context;
  final dynamic image;
  final WidgetRef ref;

  const _CommentButton({
    required this.imageId,
    required this.commentCount,
    required this.theme,
    required this.context,
    required this.image,
    required this.ref,
  });

  void _showComments() {
    AnalyticsService.instance.logButtonClick(buttonName: 'Comment button(Community Post Page)');
    final analyticsService = ref.read(analyticsServiceProvider);
    analyticsService.logCustomEvent(
        eventName: 'comment_button_clicked(Community Post Page)',
        parameters: {
          'screen': 'community_post_page',
        });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(
        imageId: image.id?.toString() ?? '${image.hashCode}',
        postImage: image,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ActionButton(
      onTap: _showComments,
      isActive: false,
      activeColor: theme.colorScheme.primary,
      icon: Icons.mode_comment_outlined,
      count: commentCount,
      theme: theme,
    );
  }
}

class _SaveButton extends ConsumerWidget {
  final String imageId;
  final bool isSaved;
  final ThemeData theme;

  const _SaveButton({
    required this.imageId,
    required this.isSaved,
    required this.theme,
  });

  void _toggleSave(WidgetRef ref) async {
    try {
      await ref.read(saveProvider.notifier).toggleSave(imageId);
      AnalyticsService.instance.logButtonClick(buttonName: 'Save button(Community Post Page)');
      final analyticsService = ref.read(analyticsServiceProvider);
      analyticsService.logCustomEvent(
          eventName: 'saved_image_button_clicked(Community Post Page)',
          parameters: {
            'screen': 'community_post_page',
          });
      appSnackBar('Alert', "${isSaved ? 'Removed from saved collection' : 'Saved to your collection'}");
    } catch (e) {
      appSnackBar('Error', "Failed to update save: $e");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _toggleSave(ref),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSaved
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.9),
              theme.colorScheme.primary.withOpacity(0.7),
            ],
          )
              : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surfaceContainerHighest.withOpacity(0.9),
              theme.colorScheme.surfaceVariant.withOpacity(0.7),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isSaved ? theme.colorScheme.primary : theme.colorScheme.onSurface).withOpacity(0.3),
              blurRadius: isSaved ? 10 : 8,
              offset: Offset(0, isSaved ? 3 : 2),
            ),
          ],
        ),
        child: Icon(
          isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
          color: isSaved ? Colors.white : theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;
  final IconData icon;
  final int count;
  final ThemeData theme;

  const _ActionButton({
    required this.onTap,
    required this.isActive,
    required this.activeColor,
    required this.icon,
    required this.count,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              activeColor.withOpacity(0.9),
              activeColor.withOpacity(0.7),
            ],
          )
              : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surfaceContainerHighest.withOpacity(0.9),
              theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (isActive ? activeColor : theme.colorScheme.onSurface).withOpacity(0.3),
              blurRadius: isActive ? 10 : 8,
              offset: Offset(0, isActive ? 3 : 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              _formatCount(count),
              style: AppTextstyle.interMedium(
                fontSize: 13,
                color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}

class _LikeCountText extends StatelessWidget {
  final int likeCount;
  final ThemeData theme;

  const _LikeCountText({required this.likeCount, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_rounded,
            color: theme.colorScheme.error.withOpacity(0.8),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            '$likeCount ${likeCount == 1 ? 'like' : 'likes'}',
            style: AppTextstyle.interMedium(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}