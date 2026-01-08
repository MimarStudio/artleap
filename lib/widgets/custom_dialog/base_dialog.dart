import 'package:flutter/material.dart';
import 'dialog_service.dart';

class BaseDialog extends StatelessWidget {
  final DialogType type;
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Widget? customContent;
  final Map<String, dynamic>? extraData;

  const BaseDialog({
    required this.type,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    this.icon,
    this.iconColor,
    this.onConfirm,
    this.onCancel,
    this.customContent,
    this.extraData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
              colorScheme.surfaceContainerHigh,
              colorScheme.surfaceContainer,
            ]
                : [
              colorScheme.surface,
              colorScheme.surfaceContainerLow,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: -8,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getHeaderGradientColors(theme),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  _buildIcon(theme),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _getHeaderTextColor(theme),
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (customContent != null)
                    customContent!
                  else if (message.isNotEmpty)
                    Text(
                      message,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 28),
                  _buildActionButtons(theme, context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    final defaultIcon = _getDefaultIcon();
    final defaultColor = _getDefaultColor(theme);

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (iconColor ?? defaultColor).withOpacity(0.2),
            (iconColor ?? defaultColor).withOpacity(0.1),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (iconColor ?? defaultColor).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon ?? defaultIcon,
        size: 36,
        color: _getHeaderTextColor(theme),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, BuildContext context) {
    final hasCancel = type != DialogType.success && type != DialogType.info;

    if (!hasCancel) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: Material(
          borderRadius: BorderRadius.circular(16),
          child: ElevatedButton(
            onPressed: () {
              onConfirm?.call();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getButtonColor(theme),
              foregroundColor: _getButtonTextColor(theme),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: _getButtonColor(theme).withOpacity(0.3),
            ),
            child: Text(
              confirmText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed: () {
                onCancel?.call();
                Navigator.of(context).pop(false);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                cancelText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 54,
            child: Material(
              borderRadius: BorderRadius.circular(16),
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getButtonColor(theme),
                  foregroundColor: _getButtonTextColor(theme),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: _getButtonColor(theme).withOpacity(0.3),
                ),
                child: Text(
                  confirmText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Color> _getHeaderGradientColors(ThemeData theme) {
    switch (type) {
      case DialogType.confirmDelete:
      case DialogType.logout:
        return [
          theme.colorScheme.errorContainer,
          theme.colorScheme.error.withOpacity(0.1),
        ];
      case DialogType.success:
        return [
          Colors.green.shade100,
          Colors.green.shade50,
        ];
      case DialogType.warning:
        return [
          Colors.orange.shade100,
          Colors.orange.shade50,
        ];
      case DialogType.premium:
        return [
          Colors.amber.shade100,
          Colors.amber.shade50,
        ];
      default:
        return [
          theme.colorScheme.primaryContainer,
          theme.colorScheme.primary.withOpacity(0.1),
        ];
    }
  }

  Color _getHeaderTextColor(ThemeData theme) {
    switch (type) {
      case DialogType.confirmDelete:
      case DialogType.logout:
        return theme.colorScheme.onErrorContainer;
      case DialogType.success:
        return Colors.green.shade800;
      case DialogType.warning:
        return Colors.orange.shade800;
      case DialogType.premium:
        return Colors.amber.shade800;
      default:
        return theme.colorScheme.onPrimaryContainer;
    }
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case DialogType.confirmDelete:
        return Icons.delete_forever_rounded;
      case DialogType.success:
        return Icons.check_circle_rounded;
      case DialogType.warning:
        return Icons.warning_amber_rounded;
      case DialogType.premium:
        return Icons.workspace_premium_rounded;
      case DialogType.logout:
        return Icons.logout_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getDefaultColor(ThemeData theme) {
    switch (type) {
      case DialogType.confirmDelete:
      case DialogType.logout:
        return theme.colorScheme.error;
      case DialogType.success:
        return Colors.green;
      case DialogType.warning:
        return Colors.orange;
      case DialogType.premium:
        return Colors.amber;
      default:
        return theme.colorScheme.primary;
    }
  }

  Color _getButtonColor(ThemeData theme) {
    switch (type) {
      case DialogType.confirmDelete:
      case DialogType.logout:
        return theme.colorScheme.error;
      case DialogType.premium:
        return Colors.amber;
      default:
        return theme.colorScheme.primary;
    }
  }

  Color _getButtonTextColor(ThemeData theme) {
    switch (type) {
      case DialogType.confirmDelete:
      case DialogType.logout:
        return theme.colorScheme.onError;
      case DialogType.premium:
        return Colors.black;
      default:
        return theme.colorScheme.onPrimary;
    }
  }
}