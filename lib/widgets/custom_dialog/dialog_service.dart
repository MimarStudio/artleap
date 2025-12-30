import 'package:Artleap.ai/shared/utilities/privacy_settings_content.dart';
import 'base_dialog.dart';

import 'package:Artleap.ai/shared/route_export.dart';

enum DialogType {
  confirmDelete,
  cancelSubscription,
  success,
  warning,
  info,
  premium,
  privacy,
  logout,
  custom
}

class DialogService {
  static Future<T?> showAppDialog<T>({
    required BuildContext context,
    required DialogType type,
    String title = '',
    String message = '',
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData? icon,
    Color? iconColor,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    Widget? customContent,
    Map<String, dynamic>? extraData,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: type != DialogType.privacy,
      builder: (context) => BaseDialog(
        type: type,
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: icon,
        iconColor: iconColor,
        onConfirm: onConfirm,
        onCancel: onCancel,
        customContent: customContent,
        extraData: extraData,
      ),
    );
  }

  static Future<bool?> confirmDelete({
    required BuildContext context,
    required String itemName,
    VoidCallback? onDelete,
  }) {
    return showAppDialog<bool>(
      context: context,
      type: DialogType.confirmDelete,
      title: 'Delete $itemName?',
      message: 'This action cannot be undone.',
      confirmText: 'Delete',
      onConfirm: onDelete,
      icon: Icons.delete_outline,
      iconColor: Theme.of(context).colorScheme.error,
    );
  }

  static void showSuccess({
    required BuildContext context,
    required String message,
    String title = 'Success!',
    VoidCallback? onConfirm,
  }) {
    showAppDialog(
      context: context,
      type: DialogType.success,
      title: title,
      message: message,
      confirmText: 'OK',
      icon: Icons.check_circle,
      iconColor: Colors.green,
      onConfirm: onConfirm,
    );
  }

  static void showWarning({
    required BuildContext context,
    required String message,
    String title = 'Warning',
  }) {
    showAppDialog(
      context: context,
      type: DialogType.warning,
      title: title,
      message: message,
      confirmText: 'OK',
      icon: Icons.warning,
      iconColor: Colors.orange,
    );
  }

  static void showPremiumUpgrade({
    required BuildContext context,
    String? featureName,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    Widget? widget,
  }) {
    showAppDialog(
      context: context,
      type: DialogType.premium,
      title: 'Premium Feature',
      message: featureName ?? 'Upgrade to unlock this feature',
      confirmText: 'Upgrade',
      cancelText: 'Not Now',
      icon: Icons.workspace_premium,
      iconColor: Colors.amber,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  static Future<ImagePrivacy?> showPrivacyDialog({
    required BuildContext context,
    required String imageId,
    required String userId,
    required ImagePrivacy initialPrivacy,
  }) {
    return showDialog<ImagePrivacy>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: AppText(
          'Privacy Settings',
          size: 18,
          weight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        content: PrivacySettingsContent(
          imageId: imageId,
          userId: userId,
          initialPrivacy: initialPrivacy,
        ),
      ),
    );
  }
}