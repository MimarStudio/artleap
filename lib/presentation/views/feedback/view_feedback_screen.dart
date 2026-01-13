import 'package:Artleap.ai/domain/feedback/feedback_model.dart';
import 'package:Artleap.ai/domain/feedback/feedback_provider.dart';
import 'package:Artleap.ai/providers/user_profile_provider.dart';
import 'package:Artleap.ai/widgets/custom_text/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'feedback_detail_screen.dart';
import 'feedback_submission_screen.dart';

class UserFeedbackListScreen extends ConsumerWidget {
  const UserFeedbackListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const _UserFeedbackListContent(),
    );
  }
}

class _UserFeedbackListContent extends ConsumerWidget {
  const _UserFeedbackListContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileProvider = ref.watch(userProfileProvider);
    final user = profileProvider.value?.userProfile?.user;
    final theme = Theme.of(context);

    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            AppText.bodyMedium(
              'Please login to view your feedback',
              color: theme.disabledColor,
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          floating: false,
          pinned: true,
          snap: false,
          stretch: true,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          flexibleSpace: FlexibleSpaceBar(
            title: AppText.headingSmall(
              'My Feedback',
              color: theme.colorScheme.onPrimary,
            ),
            centerTitle: true,
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Icon(
                    Icons.feedback_outlined,
                    size: 64,
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded,
                color: theme.colorScheme.onPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.add_comment_outlined,
                  color: theme.colorScheme.onPrimary),
              onPressed: () => _navigateToSubmitFeedback(context),
            ),
          ],
        ),

        // Main Content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: _buildFeedbackStats(ref, user.id, theme,context),
          ),
        ),

        // Feedback List
        _buildFeedbackList(ref, user.id, theme,context),
      ],
    );
  }

  Widget _buildFeedbackStats(WidgetRef ref, String userId, ThemeData theme,BuildContext context) {
    final feedbackAsync = ref.watch(userFeedbackListProvider(userId));

    return feedbackAsync.when(
      data: (data) {
        final feedbacks = data['feedbacks'] as List<FeedbackModel>;
        final total = data['pagination']['total'] as int;

        if (total == 0) {
          return _buildEmptyState(theme,context);
        }

        // Calculate statistics
        final resolvedCount =
            feedbacks.where((f) => f.status == FeedbackStatus.resolved).length;
        final inProgressCount = feedbacks
            .where((f) => f.status == FeedbackStatus.in_progress)
            .length;
        final pendingCount =
            feedbacks.where((f) => f.status == FeedbackStatus.pending).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Cards
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatCard(
                    icon: Icons.check_circle_outline,
                    value: resolvedCount.toString(),
                    label: 'Resolved',
                    color: Colors.green,
                    theme: theme,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.build_outlined,
                    value: inProgressCount.toString(),
                    label: 'In Progress',
                    color: Colors.orange,
                    theme: theme,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.access_time_outlined,
                    value: pendingCount.toString(),
                    label: 'Pending',
                    color: Colors.blue,
                    theme: theme,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.format_list_bulleted_outlined,
                    value: total.toString(),
                    label: 'Total',
                    color: theme.colorScheme.primary,
                    theme: theme,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _buildFilterChips(ref, theme),
            const SizedBox(height: 16),
            Row(
              children: [
                AppText.headingSmall(
                  'Your Feedback ($total)',
                  color: theme.textTheme.titleLarge?.color,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () =>
                      ref.refresh(userFeedbackListProvider(userId)),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (error, stackTrace) => const SizedBox(),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.headingSmall(
                value,
                color: theme.textTheme.titleLarge?.color,
              ),
              const SizedBox(height: 2),
              AppText.caption(
                label,
                color: theme.disabledColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(WidgetRef ref, ThemeData theme) {
    return Wrap(
      spacing: 8,
      children: FeedbackStatus.values.map((status) {
        return FilterChip(
          label: AppText.caption(status.displayName),
          selected: false,
          onSelected: (_) {
            // Implement filtering logic
          },
          selectedColor: status.color.withOpacity(0.2),
          backgroundColor: theme.colorScheme.surface,
          labelStyle: TextStyle(
            color: status.color,
          ),
          avatar: Icon(status.icon, size: 16, color: status.color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: status.color.withOpacity(0.3)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeedbackList(WidgetRef ref, String userId, ThemeData theme,BuildContext context) {
    final feedbackAsync = ref.watch(userFeedbackListProvider(userId));

    return feedbackAsync.when(
      data: (data) {
        final feedbacks = data['feedbacks'] as List<FeedbackModel>;

        if (feedbacks.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(theme,context),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final feedback = feedbacks[index];
              return _buildFeedbackItem(feedback, theme, context);
            },
            childCount: feedbacks.length,
          ),
        );
      },
      loading: () => SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      error: (error, stackTrace) => SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              AppText.bodyMedium(
                'Failed to load feedback',
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 8),
              AppText.caption(
                error.toString(),
                color: theme.disabledColor,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userFeedbackListProvider(userId)),
                child: AppText('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackItem(
      FeedbackModel feedback, ThemeData theme, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _navigateToFeedbackDetail(context, feedback),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      // Feedback Type
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: feedback.type.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(feedback.type.icon,
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 6),
                            AppText(
                              feedback.type.displayName,
                              size: 12,
                              weight: FontWeight.w600,
                              color: feedback.type.color,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: feedback.status.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(feedback.status.icon,
                                size: 12, color: feedback.status.color),
                            const SizedBox(width: 6),
                            AppText(
                              feedback.status.displayName,
                              size: 12,
                              weight: FontWeight.w600,
                              color: feedback.status.color,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  AppText.bodyMedium(
                    feedback.title,
                    color: theme.textTheme.titleMedium?.color,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  AppText.bodySmall(
                    feedback.description,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Date
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: theme.disabledColor,
                          ),
                          const SizedBox(width: 4),
                          AppText.caption(
                            DateFormat('MMM dd, yyyy').format(feedback.createdAt),
                            color: theme.disabledColor,
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (feedback.priority != FeedbackPriority.medium)
                        Row(
                          children: [
                            Icon(
                              Icons.priority_high,
                              size: 14,
                              color: feedback.priority.color,
                            ),
                            const SizedBox(width: 4),
                            AppText.caption(
                              feedback.priority.displayName,
                              color: feedback.priority.color,
                            ),
                          ],
                        ),
                      const SizedBox(width: 16),
                      if (feedback.rating != null)
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            AppText.caption(
                              '${feedback.rating}/5',
                              color: Colors.amber,
                            ),
                          ],
                        ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.thumb_up_outlined,
                            size: 14,
                            color: theme.disabledColor,
                          ),
                          const SizedBox(width: 4),
                          AppText.caption(
                            feedback.upvotes.toString(),
                            color: theme.disabledColor,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Admin Response Indicator
                  if (feedback.adminResponse != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          AppText.caption(
                            'Admin Responded',
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme,BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
            child: Icon(
              Icons.feedback_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          AppText.headingMedium(
            'No Feedback Yet',
            color: theme.textTheme.titleLarge?.color,
            align: TextAlign.center,
          ),
          const SizedBox(height: 12),
          AppText.bodySmall(
            'You haven\'t submitted any feedback yet. Share your thoughts to help us improve Artleap.ai!',
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            align: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToSubmitFeedback(context),
            icon: Icon(Icons.add_comment_outlined, size: 20),
            label: AppText('Submit Your First Feedback'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSubmitFeedback(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => FeedbackSubmissionScreen(
                  pageUrl: '/feeback',
                  featurePath: 'view_feedback',
                )
        )
    );
  }

  void _navigateToFeedbackDetail(BuildContext context, FeedbackModel feedback) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FeedbackDetailScreen(feedbackId: feedback.id),
        ));
  }
}
