import 'package:intl/intl.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class NotificationDetailScreen extends ConsumerWidget {
  static const routeName = '/notification-details';
  final AppNotification notification;

  const NotificationDetailScreen({
    Key? key,
    required this.notification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Notification',
          style: AppTextstyle.interBold(
            fontSize: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            onPressed: () => _handleDelete(context, ref, notification.id),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(theme),
              const SizedBox(height: 24),
              _buildContentSection(theme),
              if (notification.data?.isNotEmpty ?? false) ...[
                const SizedBox(height: 24),
                _buildDataSection(theme),
              ],
              const SizedBox(height: 32),
              if (_hasAction()) _buildActionButton(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: theme.colorScheme.onPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: AppTextstyle.interBold(
                    fontSize: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMM d, y • h:mm a').format(notification.timestamp),
                      style: AppTextstyle.interRegular(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Message',
            style: AppTextstyle.interBold(
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            notification.body,
            style: AppTextstyle.interRegular(
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: AppTextstyle.interBold(
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...notification.data!.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.key,
                      style: AppTextstyle.interMedium(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value.toString(),
                      style: AppTextstyle.interRegular(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, ThemeData theme) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primaryContainer,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CommonButton(
          title: _getActionText(notification.type),
          onpress: () => _handleNotificationAction(context),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primaryContainer,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, String notificationId) async {
    DialogService.confirmDelete(
      context: context,
      itemName: 'notification',
      onDelete: () async {
        try {
          await ref.read(notificationProvider(UserData.ins.userId!).notifier)
              .deleteNotification(notification.id, UserData.ins.userId!);
          if (context.mounted) {
            Navigator.pop(context, true);
          }
        } catch (e) {
          if (context.mounted) {
            appSnackBar('Error', 'Failed to delete Notification',backgroundColor: AppColors.red);
          }
        }
      },
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'system':
        return Icons.info_rounded;
      case 'message':
        return Icons.chat_rounded;
      case 'alert':
        return Icons.warning_rounded;
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.comment_rounded;
      case 'follow':
        return Icons.person_add_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  bool _hasAction() {
    return notification.type == 'message' ||
        notification.data?['action'] != null;
  }

  String _getActionText(String type) {
    switch (type) {
      case 'message':
        return 'Reply to Message';
      case 'alert':
        return 'View Alert Details';
      case 'like':
        return 'View Post';
      case 'comment':
        return 'View Comments';
      case 'follow':
        return 'View Profile';
      default:
        return 'View More';
    }
  }

  void _handleNotificationAction(BuildContext context) {
    switch (notification.type) {
      case 'message':
      // Navigate to chat screen
        break;
      case 'alert':
      // Handle alert action
        break;
      default:
        if (notification.data?['url'] != null) {
          // Open URL
        }
    }
  }
}