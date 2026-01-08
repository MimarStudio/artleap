import 'package:Artleap.ai/domain/feedback/feedback_model.dart';
import 'package:Artleap.ai/domain/feedback/feedback_provider.dart';
import 'package:Artleap.ai/widgets/custom_text/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackDetailScreen extends ConsumerWidget {
  final String feedbackId;

  const FeedbackDetailScreen({
    Key? key,
    required this.feedbackId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _FeedbackDetailContent(feedbackId: feedbackId),
    );
  }
}

class _FeedbackDetailContent extends ConsumerWidget {
  final String feedbackId;

  const _FeedbackDetailContent({
    Key? key,
    required this.feedbackId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(feedbackDetailProvider(feedbackId));
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          snap: false,
          stretch: true,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          flexibleSpace: FlexibleSpaceBar(
            title: AppText.headingSmall(
              'Feedback Details',
              color: theme.colorScheme.onPrimary,
            ),
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
              child: Center(
                child: Icon(
                  Icons.feedback_outlined,
                  size: 64,
                  color: theme.colorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.share_outlined, color: theme.colorScheme.onPrimary),
              onPressed: () => _shareFeedback(context, ref),
            ),
          ],
        ),

        // Main Content
        feedbackAsync.when(
          data: (feedback) {
            if (feedback == null) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.disabledColor,
                      ),
                      const SizedBox(height: 16),
                      AppText.bodyMedium(
                        'Feedback not found',
                        color: theme.disabledColor,
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildFeedbackOverview(feedback, theme),
                  const SizedBox(height: 24),
                  _buildStatusTimeline(feedback, theme),
                  const SizedBox(height: 24),
                  _buildFeedbackDetails(feedback, theme),
                  if (feedback.adminResponse != null) ...[
                    const SizedBox(height: 24),
                    _buildAdminResponse(feedback.adminResponse!, theme),
                  ],
                  if (feedback.attachments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildAttachments(feedback, theme),
                  ],
                  const SizedBox(height: 24),
                  _buildDeviceInfo(feedback, theme),
                  const SizedBox(height: 40),
                ]),
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
                    'Please try again later',
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(feedbackDetailProvider(feedbackId)),
                    child: AppText('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackOverview(FeedbackModel feedback, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type and Status Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(feedback.type.icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      AppText(
                        feedback.type.displayName,
                        size: 12,
                        weight: FontWeight.w600,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: feedback.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(feedback.status.icon, size: 14, color: feedback.status.color),
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

            // Title
            AppText.headingMedium(
              feedback.title,
              color: theme.textTheme.titleLarge?.color,
            ),

            const SizedBox(height: 12),

            // Description
            AppText.bodySmall(
              feedback.description,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),

            const SizedBox(height: 20),

            // Meta Information
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildMetaItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Created',
                  value: DateFormat('MMM dd, yyyy').format(feedback.createdAt),
                  theme: theme,
                ),
                if (feedback.resolvedAt != null)
                  _buildMetaItem(
                    icon: Icons.check_circle_outline,
                    label: 'Resolved',
                    value: DateFormat('MMM dd, yyyy').format(feedback.resolvedAt!),
                    theme: theme,
                  ),
                _buildMetaItem(
                  icon: Icons.priority_high,
                  label: 'Priority',
                  value: feedback.priority.displayName,
                  color: feedback.priority.color,
                  theme: theme,
                ),
                if (feedback.rating != null)
                  _buildMetaItem(
                    icon: Icons.star_rounded,
                    label: 'Rating',
                    value: '${feedback.rating}/5',
                    color: Colors.amber,
                    theme: theme,
                  ),
                _buildMetaItem(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  value: feedback.category.displayName,
                  theme: theme,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tags
            if (feedback.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: feedback.tags.map((tag) {
                  return Chip(
                    label: AppText.caption(tag),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    labelStyle: TextStyle(color: theme.colorScheme.primary),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? theme.disabledColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.caption(
              label,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 2),
            AppText(
              value,
              size: 12,
              weight: FontWeight.w600,
              color: color ?? theme.textTheme.bodyMedium?.color,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusTimeline(FeedbackModel feedback, ThemeData theme) {
    final statuses = [
      if (feedback.status == FeedbackStatus.resolved) FeedbackStatus.resolved,
      FeedbackStatus.in_progress,
      FeedbackStatus.in_review,
      FeedbackStatus.pending,
    ];

    final currentStatusIndex = statuses.indexOf(feedback.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyMedium(
              'Status Timeline',
              color: theme.textTheme.titleMedium?.color,
            ),
            const SizedBox(height: 16),
            Column(
              children: statuses.asMap().entries.map((entry) {
                final index = entry.key;
                final status = entry.value;
                final isActive = index <= currentStatusIndex;
                final isLast = index == statuses.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? status.color
                            : theme.disabledColor.withOpacity(0.2),
                        border: Border.all(
                          color: isActive
                              ? status.color
                              : theme.disabledColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          isActive ? Icons.check : status.icon,
                          size: 16,
                          color: isActive
                              ? Colors.white
                              : theme.disabledColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Timeline and Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            status.displayName,
                            weight: FontWeight.w600,
                            color: isActive
                                ? theme.textTheme.bodyMedium?.color
                                : theme.disabledColor,
                          ),
                          const SizedBox(height: 4),
                          AppText.caption(
                            _getStatusDescription(status),
                            color: theme.disabledColor,
                          ),
                          if (!isLast) ...[
                            const SizedBox(height: 12),
                            Container(
                              height: 24,
                              width: 2,
                              margin: const EdgeInsets.only(left: 14),
                              color: theme.dividerColor,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusDescription(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.pending:
        return 'Your feedback is waiting for review';
      case FeedbackStatus.in_review:
        return 'Our team is reviewing your feedback';
      case FeedbackStatus.in_progress:
        return 'Working on implementing your suggestion';
      case FeedbackStatus.resolved:
        return 'Your feedback has been addressed';
      case FeedbackStatus.wont_fix:
        return 'This feedback won\'t be implemented';
      case FeedbackStatus.duplicate:
        return 'Similar feedback already exists';
    }
  }

  Widget _buildFeedbackDetails(FeedbackModel feedback, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyMedium(
              'Additional Details',
              color: theme.textTheme.titleMedium?.color,
            ),
            const SizedBox(height: 16),

            // App Version
            _buildDetailRow(
              icon: Icons.apps_outlined,
              label: 'App Version',
              value: feedback.appVersion,
              theme: theme,
            ),

            const SizedBox(height: 12),

            // Submitted By
            _buildDetailRow(
              icon: Icons.person_outline,
              label: 'Submitted By',
              value: feedback.isAnonymous ? 'Anonymous' : feedback.userName,
              theme: theme,
            ),

            const SizedBox(height: 12),

            // Allow Contact
            if (!feedback.isAnonymous)
              _buildDetailRow(
                icon: Icons.contact_mail_outlined,
                label: 'Contact Allowed',
                value: feedback.allowContact ? 'Yes' : 'No',
                theme: theme,
              ),

            const SizedBox(height: 12),

            // Upvotes
            _buildDetailRow(
              icon: Icons.thumb_up_outlined,
              label: 'Upvotes',
              value: feedback.upvotes.toString(),
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.disabledColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.caption(
                label,
                color: theme.disabledColor,
              ),
              const SizedBox(height: 2),
              AppText.bodySmall(
                value,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminResponse(AdminResponse response, ThemeData theme) {
    return Card(
      elevation: 2,
      color: theme.colorScheme.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                AppText.bodyMedium(
                  'Admin Response',
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppText.bodySmall(
                response.message,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: theme.disabledColor,
                ),
                const SizedBox(width: 4),
                AppText.caption(
                  response.respondedBy ?? 'Admin Team',
                  color: theme.disabledColor,
                ),
                const Spacer(),
                Icon(
                  Icons.access_time_outlined,
                  size: 14,
                  color: theme.disabledColor,
                ),
                const SizedBox(width: 4),
                AppText.caption(
                  DateFormat('MMM dd, yyyy • HH:mm').format(response.respondedAt),
                  color: theme.disabledColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachments(FeedbackModel feedback, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.attach_file_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                AppText.bodyMedium(
                  'Attachments (${feedback.attachments.length})',
                  color: theme.textTheme.titleMedium?.color,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: feedback.attachments.map((attachment) {
                return _buildAttachmentItem(attachment, theme);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(FeedbackAttachment attachment, ThemeData theme) {
    final isImage = attachment.fileType == 'image';

    return GestureDetector(
      onTap: () => _openAttachment(attachment),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          children: [
            // Thumbnail
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              child: isImage && attachment.thumbnailUrl != null
                  ? ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  attachment.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: theme.disabledColor,
                      ),
                    );
                  },
                ),
              )
                  : Center(
                child: Icon(
                  _getFileIcon(attachment.fileType),
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
              ),
            ),

            // File Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.caption(
                    attachment.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(height: 2),
                  AppText.caption(
                    attachment.fileType.toUpperCase(),
                    color: theme.disabledColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.videocam_outlined;
      case 'document':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Widget _buildDeviceInfo(FeedbackModel feedback, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.device_hub_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                AppText.bodyMedium(
                  'Device Information',
                  color: theme.textTheme.titleMedium?.color,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (feedback.deviceInfo.platform != null)
              _buildDeviceInfoRow(
                'Platform',
                feedback.deviceInfo.platform!,
                theme,
              ),

            if (feedback.deviceInfo.osVersion != null)
              _buildDeviceInfoRow(
                'OS Version',
                feedback.deviceInfo.osVersion!,
                theme,
              ),

            if (feedback.deviceInfo.deviceModel != null)
              _buildDeviceInfoRow(
                'Device Model',
                feedback.deviceInfo.deviceModel!,
                theme,
              ),

            if (feedback.deviceInfo.screenSize != null)
              _buildDeviceInfoRow(
                'Screen',
                feedback.deviceInfo.screenSize!,
                theme,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: AppText.caption(
              label,
              color: theme.disabledColor,
            ),
          ),
          Expanded(
            child: AppText.bodySmall(
              value,
              color: theme.textTheme.bodyMedium?.color,
              align: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAttachment(FeedbackAttachment attachment) async {
    try {
      if (await canLaunchUrl(Uri.parse(attachment.fileUrl))) {
        await launchUrl(Uri.parse(attachment.fileUrl));
      }
    } catch (e) {
      // Handle error
    }
  }

  void _shareFeedback(BuildContext context, WidgetRef ref) {
    final feedback = ref.read(feedbackDetailProvider(feedbackId)).value;
    if (feedback == null) return;

    final shareText = '''
🎯 Feedback: ${feedback.title}

📝 Type: ${feedback.type.displayName}
📊 Status: ${feedback.status.displayName}
⭐ Priority: ${feedback.priority.displayName}

💬 Description:
${feedback.description}

Submitted on ${DateFormat('MMM dd, yyyy').format(feedback.createdAt)}
''';

    // Implement sharing logic
    // Share.share(shareText);
  }
}