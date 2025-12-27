import 'package:intl/intl.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;
  final bool isSelected;
  final bool isSelectionMode;

  const NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onLongPress,
    required this.onMarkAsRead,
    required this.onDelete,
    this.isSelected = false,
    this.isSelectionMode = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_forever_rounded, color: theme.colorScheme.onError, size: 24),
      ),
      confirmDismiss: (direction) async {
        onDelete();
        return false;
      },
      child: Semantics(
        label: notification.isRead
            ? 'Read notification: ${notification.title}'
            : 'Unread notification: ${notification.title}',
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : notification.isRead
                    ? Colors.transparent
                    : theme.colorScheme.primary.withOpacity(0.3),
                width: isSelected ? 2 : notification.isRead ? 0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isSelectionMode) ...[
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: isSelected
                              ? Icon(Icons.check_rounded, size: 16, color: theme.colorScheme.onPrimary)
                              : null,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Container(
                        width: 48,
                        height: 48,
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
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              notification.title,
                              size: 16,
                              weight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            AppText(
                              notification.body,
                              size: 14,
                              weight: FontWeight.w400,
                              color: theme.colorScheme.onSurfaceVariant,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                AppText(
                                  DateFormat('MMM d • h:mm a').format(notification.timestamp),
                                  size: 12,
                                  weight: FontWeight.w400,
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                ),
                                const Spacer(),
                                if (!notification.isRead && !isSelectionMode)
                                  GestureDetector(
                                    onTap: onMarkAsRead,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: AppText(
                                        'Mark read',
                                        size: 12,
                                        weight: FontWeight.w500,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isSelectionMode) ...[
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(Icons.close_rounded, size: 18),
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                      onPressed: onDelete,
                      tooltip: 'Delete notification',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                  ),
                ],
                if (!notification.isRead && !isSelectionMode)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'system': return Icons.info_rounded;
      case 'message': return Icons.chat_rounded;
      case 'alert': return Icons.warning_rounded;
      case 'like': return Icons.favorite_rounded;
      case 'comment': return Icons.comment_rounded;
      case 'follow': return Icons.person_add_rounded;
      case 'success': return Icons.check_circle_rounded;
      case 'error': return Icons.error_rounded;
      case 'warning': return Icons.warning_amber_rounded;
      case 'info': return Icons.info_outline_rounded;
      default: return Icons.notifications_rounded;
    }
  }
}