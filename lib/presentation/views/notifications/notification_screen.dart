import 'notification_card.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class NotificationScreen extends ConsumerWidget {
  static const routeName = '/notifications_repo';
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = UserData.ins.userId;

    if (userId == null) {
      return ErrorState(
        message: 'Please login to view notifications',
        icon: Icons.login_rounded,
      );
    }

    final selectionState = ref.watch(notificationSelectionProvider);
    final notificationsAsync = ref.watch(notificationProvider(userId));
    final currentFilter = ref.watch(notificationFilterProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(ref, selectionState, notificationsAsync, theme),
      body: Column(
        children: [
          if (!selectionState.isSelectionMode)
            _buildFilterTabs(currentFilter, theme, ref),
          if (selectionState.isSelectionMode)
            _buildSelectionActions(ref, selectionState, userId, theme),
          Expanded(
            child: _buildNotificationList(ref, selectionState, notificationsAsync, currentFilter, userId, theme),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(
      WidgetRef ref,
      NotificationSelectionState selectionState,
      AsyncValue<List<AppNotification>> notificationsAsync,
      ThemeData theme,
      ) {
    final unreadCount = notificationsAsync.maybeWhen(
      data: (notifications) => notifications.where((n) => !n.isRead).length,
      orElse: () => 0,
    );

    return AppBar(
      title: selectionState.isSelectionMode
          ? AppText(
        '${selectionState.selectedIds.length} selected',
        size: 18,
        weight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      )
          : AppText(
        'Notifications${unreadCount > 0 ? ' ($unreadCount)' : ''}',
        size: 20,
        weight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
      centerTitle: true,
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      foregroundColor: theme.colorScheme.onSurface,
      leading: selectionState.isSelectionMode
          ? IconButton(
        icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurface),
        onPressed: () => ref.read(notificationSelectionProvider.notifier).clearSelection(),
      )
          : null,
      actions: _buildAppBarActions(ref, selectionState, notificationsAsync, theme),
    );
  }

  List<Widget> _buildAppBarActions(
      WidgetRef ref,
      NotificationSelectionState selectionState,
      AsyncValue<List<AppNotification>> notificationsAsync,
      ThemeData theme,
      ) {
    if (selectionState.isSelectionMode) {
      return [
        IconButton(
          icon: Icon(Icons.checklist_rounded, color: theme.colorScheme.primary),
          onPressed: () => _selectAll(ref, notificationsAsync),
          tooltip: 'Select all',
        ),
        IconButton(
          icon: Icon(Icons.mark_email_read_rounded, color: theme.colorScheme.primary),
          onPressed: () => _markSelectedAsRead(ref, selectionState),
          tooltip: 'Mark selected as read',
        ),
        IconButton(
          icon: Icon(Icons.delete_rounded, color: theme.colorScheme.error),
          onPressed: () => _deleteSelected(ref, selectionState),
          tooltip: 'Delete selected',
        ),
      ];
    }

    final filteredUnreadCount = notificationsAsync.maybeWhen(
      data: (notifications) => _filterNotifications(notifications, ref.read(notificationFilterProvider))
          .where((n) => !n.isRead)
          .length,
      orElse: () => 0,
    );

    return [
      if (filteredUnreadCount > 0)
        IconButton(
          icon: Icon(Icons.done_all_rounded, color: theme.colorScheme.primary),
          onPressed: () => _markAllAsRead(ref),
          tooltip: 'Mark all as read',
        ),
      IconButton(
        icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.primary),
        onPressed: () => _loadNotifications(ref),
        tooltip: 'Refresh notifications',
      ),
    ];
  }

  Widget _buildSelectionActions(
      WidgetRef ref,
      NotificationSelectionState selectionState,
      String userId,
      ThemeData theme,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton.icon(
            onPressed: () => _markSelectedAsRead(ref, selectionState),
            icon: Icon(Icons.mark_email_read_rounded, color: theme.colorScheme.primary),
            label: AppText(
              'Mark Read',
              size: 14,
              weight: FontWeight.w500,
              color: theme.colorScheme.primary,
            ),
          ),
          TextButton.icon(
            onPressed: () => _deleteSelected(ref, selectionState),
            icon: Icon(Icons.delete_rounded, color: theme.colorScheme.error),
            label: AppText(
              'Delete',
              size: 14,
              weight: FontWeight.w500,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(NotificationFilter currentFilter, ThemeData theme, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: NotificationFilter.values.map((filter) {
          final isSelected = currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: AppText(
                filter.displayName,
                size: 14,
                weight: FontWeight.w500,
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              ),
              selected: isSelected,
              onSelected: (selected) {
                ref.read(notificationFilterProvider.notifier).state = filter;
              },
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              selectedColor: theme.colorScheme.primary,
              checkmarkColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationList(
      WidgetRef ref,
      NotificationSelectionState selectionState,
      AsyncValue<List<AppNotification>> notificationsAsync,
      NotificationFilter currentFilter,
      String userId,
      ThemeData theme,
      ) {
    return notificationsAsync.when(
      loading: () => const LoadingState(useShimmer: true, shimmerItemCount: 5),
      error: (error, stack) => ErrorState(
        message: 'Failed to load notifications',
        onRetry: () => _loadNotifications(ref),
        icon: Icons.notifications_off_rounded,
      ),
      data: (allNotifications) {
        final filteredNotifications = _filterNotifications(allNotifications, currentFilter);

        if (filteredNotifications.isEmpty) {
          return EmptyState(
            icon: _getEmptyStateIcon(currentFilter),
            title: _getEmptyStateTitle(currentFilter),
            subtitle: _getEmptyStateSubtitle(currentFilter),
            iconColor: theme.colorScheme.primary,
          );
        }

        return RefreshIndicator(
          backgroundColor: theme.colorScheme.primary,
          color: theme.colorScheme.onPrimary,
          onRefresh: () => _loadNotifications(ref),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredNotifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notification = filteredNotifications[index];
              return NotificationCard(
                notification: notification,
                isSelected: selectionState.selectedIds.contains(notification.id),
                isSelectionMode: selectionState.isSelectionMode,
                onTap: () => _handleNotificationTap(ref, notification, userId,context),
                onLongPress: () => _toggleSelection(ref, notification.id),
                onMarkAsRead: () => _markAsRead(ref, notification.id, userId),
                onDelete: () => _deleteNotification(ref, notification.id, userId),
              );
            },
          ),
        );
      },
    );
  }

  List<AppNotification> _filterNotifications(List<AppNotification> notifications, NotificationFilter filter) {
    if (filter == NotificationFilter.all) return notifications;

    return notifications.where((notification) {
      final String? dataType = notification.data?['type']?.toString();
      final String mainType = notification.type;
      final String effectiveType = dataType ?? mainType;

      switch (filter) {
        case NotificationFilter.like: return effectiveType == 'like';
        case NotificationFilter.comment: return effectiveType == 'comment';
        case NotificationFilter.follow: return effectiveType == 'follow';
        case NotificationFilter.alert: return effectiveType == 'alert';
        default: return true;
      }
    }).toList();
  }

  Future<void> _loadNotifications(WidgetRef ref) async {
    final userId = UserData.ins.userId;
    if (userId != null) {
      await ref.read(notificationProvider(userId).notifier).loadNotifications();
    }
  }

  Future<void> _markAllAsRead(WidgetRef ref) async {
    final userId = UserData.ins.userId;
    if (userId != null) {
      await ref.read(notificationProvider(userId).notifier).markAllAsRead();
    }
  }

  void _selectAll(WidgetRef ref, AsyncValue<List<AppNotification>> notificationsAsync) {
    notificationsAsync.whenData((notifications) {
      final allIds = notifications.map((n) => n.id).toList();
      ref.read(notificationSelectionProvider.notifier).selectAll(allIds);
    });
  }

  Future<void> _markSelectedAsRead(WidgetRef ref, NotificationSelectionState selectionState) async {
    final userId = UserData.ins.userId;
    if (userId == null || selectionState.selectedIds.isEmpty) return;

    for (final id in selectionState.selectedIds) {
      await ref.read(notificationProvider(userId).notifier).markAsRead(id);
    }

    ref.read(notificationSelectionProvider.notifier).clearSelection();
  }

  Future<void> _deleteSelected(WidgetRef ref, NotificationSelectionState selectionState) async {
    final userId = UserData.ins.userId;
    if (userId == null || selectionState.selectedIds.isEmpty) return;

    for (final id in selectionState.selectedIds) {
      await _deleteNotification(ref, id, userId);
    }

    ref.read(notificationSelectionProvider.notifier).clearSelection();
  }

  Future<void> _deleteNotification(WidgetRef ref, String notificationId, String userId) async {
    try {
      await ref.read(notificationProvider(userId).notifier).deleteNotification(notificationId, userId);
    } catch (e) {
      appErrorSnackBar('Error', 'Failed to delete notification');
    }
  }

  void _toggleSelection(WidgetRef ref, String notificationId) {
    ref.read(notificationSelectionProvider.notifier).toggleSelection(notificationId);
  }

  void _handleNotificationTap(WidgetRef ref, AppNotification notification, String userId,BuildContext context) {
    final selectionState = ref.read(notificationSelectionProvider);

    if (selectionState.isSelectionMode) {
      _toggleSelection(ref, notification.id);
    } else {
      if (!notification.isRead) {
        _markAsRead(ref, notification.id, userId);
      }
      Navigator.pushNamed(
        context,
        NotificationDetailScreen.routeName,
        arguments: notification,
      );
    }
  }

  void _markAsRead(WidgetRef ref, String notificationId, String userId) {
    ref.read(notificationProvider(userId).notifier).markAsRead(notificationId);
  }

  IconData _getEmptyStateIcon(NotificationFilter filter) {
    switch (filter) {
      case NotificationFilter.like: return Icons.favorite_border_rounded;
      case NotificationFilter.comment: return Icons.chat_bubble_outline_rounded;
      case NotificationFilter.follow: return Icons.person_add_alt_1_rounded;
      case NotificationFilter.alert: return Icons.warning_amber_rounded;
      default: return Icons.notifications_none_rounded;
    }
  }

  String _getEmptyStateTitle(NotificationFilter filter) {
    switch (filter) {
      case NotificationFilter.like: return 'No Like Notifications';
      case NotificationFilter.comment: return 'No Comment Notifications';
      case NotificationFilter.follow: return 'No Follow Notifications';
      case NotificationFilter.alert: return 'No Alert Notifications';
      default: return 'No Notifications Yet';
    }
  }

  String _getEmptyStateSubtitle(NotificationFilter filter) {
    switch (filter) {
      case NotificationFilter.like: return 'When someone likes your content, it will appear here';
      case NotificationFilter.comment: return 'Comments on your posts will show up here';
      case NotificationFilter.follow: return 'New followers will be displayed here';
      case NotificationFilter.alert: return 'Important alerts and updates will appear here';
      default: return 'When you receive notifications, they will appear here';
    }
  }
}