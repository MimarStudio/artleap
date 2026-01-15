import 'dart:async';
import 'package:Artleap.ai/widgets/custom_text/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'feedback_submission_screen.dart';


class FeedbackNavigationDialogHelper {
  static const String _lastFeedbackSubmissionKey = 'last_feedback_submission';
  static const String _feedbackSubmissionCountKey = 'feedback_submission_count';
  static const int _minDaysBetweenPrompts = 7;
  static const int _maxPromptsBeforeSkip = 3;
  static const String _feedbackDialogShownKey = 'feedback_dialog_shown';

  static Future<bool> shouldShowFeedbackNavigationDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dialogShown = prefs.getBool(_feedbackDialogShownKey) ?? false;
      if (dialogShown) {
        return false;
      }
      final lastFeedbackTime = prefs.getInt(_lastFeedbackSubmissionKey);
      final feedbackCount = prefs.getInt(_feedbackSubmissionCountKey) ?? 0;

      if (lastFeedbackTime != null) {
        final lastSubmissionDate = DateTime.fromMillisecondsSinceEpoch(lastFeedbackTime);
        final daysSinceLastSubmission = DateTime.now().difference(lastSubmissionDate).inDays;

        if (daysSinceLastSubmission < _minDaysBetweenPrompts) {
          return false;
        }
      }

      if (feedbackCount >= _maxPromptsBeforeSkip) {
        if (lastFeedbackTime != null) {
          final lastSubmissionDate = DateTime.fromMillisecondsSinceEpoch(lastFeedbackTime);
          final daysSinceLastSubmission = DateTime.now().difference(lastSubmissionDate).inDays;
          if (daysSinceLastSubmission < 30) {
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> recordFeedbackSubmission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_feedbackSubmissionCountKey) ?? 0;

      await prefs.setInt(_lastFeedbackSubmissionKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_feedbackSubmissionCountKey, currentCount + 1);
      await prefs.setBool(_feedbackDialogShownKey, true);
    } catch (e) {
      // Silently fail
    }
  }

  static Future<void> markDialogAsShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_feedbackDialogShownKey, true);
    } catch (e) {
      // Silently fail
    }
  }

  static Future<void> resetDialogShownState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_feedbackDialogShownKey, false);
    } catch (e) {
      // Silently fail
    }
  }

  static void showFeedbackNavigationDialog({
    required BuildContext context,
    required WidgetRef ref,
    String? pageUrl,
    String? featurePath,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => FeedbackNavigationDialog(
        ref: ref,
        pageUrl: pageUrl,
        featurePath: featurePath,
      ),
    );
  }

  static Future<void> checkAndShowFeedbackDialog({
    required BuildContext context,
    required WidgetRef ref,
    String? pageUrl,
    String? featurePath,
  }) async {
    final shouldShow = await shouldShowFeedbackNavigationDialog();

    if (shouldShow && context.mounted) {
      await Future.delayed(const Duration(seconds: 2));

      if (context.mounted) {
        showFeedbackNavigationDialog(
          context: context,
          ref: ref,
          pageUrl: pageUrl,
          featurePath: featurePath,
        );
        await markDialogAsShown();
      }
    }
  }
}


class FeedbackNavigationDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final String? pageUrl;
  final String? featurePath;

  const FeedbackNavigationDialog({
    Key? key,
    required this.ref,
    this.pageUrl,
    this.featurePath,
  }) : super(key: key);

  @override
  ConsumerState<FeedbackNavigationDialog> createState() => _FeedbackNavigationDialogState();
}

class _FeedbackNavigationDialogState extends ConsumerState<FeedbackNavigationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _closeDialog() async {
    if (_isClosing) return;

    _isClosing = true;
    await _controller.reverse();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _navigateToFeedbackScreen() async {
    await _closeDialog();
    if (mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => FeedbackSubmissionScreen(
            pageUrl: widget.pageUrl,
            featurePath: widget.featurePath,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  void _skipFeedback() async {
    await _closeDialog();
    // User chose to skip - no action needed
  }

  void _neverAskAgain() async {
    await FeedbackNavigationDialogHelper.recordFeedbackSubmission();
    await _closeDialog();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        await _closeDialog();
        return false;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              ),
            );
          },
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Material(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              elevation: 24,
              shadowColor: Colors.black.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withOpacity(0.7),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.feedback_outlined,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: AppText.headingSmall(
                        'Share Your Thoughts',
                        color: theme.textTheme.titleLarge?.color,
                        align: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Benefits List
                    _buildBenefitItem(
                      icon: Icons.star_outline,
                      title: 'Help Us Improve',
                      description: 'Your feedback directly impacts future updates',
                      theme: theme,
                    ),
                    const SizedBox(height: 32),

                    // Primary Action Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: _navigateToFeedbackScreen,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 22,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                AppText(
                                  'Share Feedback',
                                  color: Colors.white,
                                  weight: FontWeight.w600,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Secondary Action Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _skipFeedback,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                        child: AppText(
                          'Maybe Later',
                          color: theme.textTheme.bodyMedium?.color,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tertiary Action
                    Center(
                      child: TextButton(
                        onPressed: _neverAskAgain,
                        style: TextButton.styleFrom(
                          foregroundColor: theme.disabledColor,
                        ),
                        child: AppText.caption(
                          'Don\'t ask again',
                          color: theme.disabledColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Footer Note
                    Center(
                      child: AppText.caption(
                        'Your feedback is anonymous and helps everyone',
                        color: theme.disabledColor.withOpacity(0.7),
                        align: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withOpacity(0.1),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyMedium(
                title,
                color: theme.textTheme.titleMedium?.color,
                weight: FontWeight.w600,
              ),
              const SizedBox(height: 4),
              AppText.caption(
                description,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}