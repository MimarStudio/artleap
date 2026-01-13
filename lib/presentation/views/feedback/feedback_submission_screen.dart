import 'package:Artleap.ai/domain/api_services/api_response.dart';
import 'package:Artleap.ai/domain/feedback/feedback_model.dart';
import 'package:Artleap.ai/domain/feedback/feedback_provider.dart';
import 'package:Artleap.ai/domain/feedback/feedback_state_provider.dart';
import 'package:Artleap.ai/providers/user_profile_provider.dart';
import 'package:Artleap.ai/widgets/common/app_snack_bar.dart';
import 'package:Artleap.ai/widgets/custom_text/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';


class FeedbackSubmissionScreen extends ConsumerWidget {
  final FeedbackType? initialType;
  final int? initialRating;
  final String? initialComment;
  final String? pageUrl;
  final String? featurePath;

  const FeedbackSubmissionScreen({
    Key? key,
    this.initialType,
    this.initialRating,
    this.initialComment,
    this.pageUrl,
    this.featurePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _FeedbackSubmissionScreenContent(
      initialType: initialType,
      initialRating: initialRating,
      initialComment: initialComment,
      pageUrl: pageUrl,
      featurePath: featurePath,
    );
  }
}

class _FeedbackSubmissionScreenContent extends ConsumerStatefulWidget {
  final FeedbackType? initialType;
  final int? initialRating;
  final String? initialComment;
  final String? pageUrl;
  final String? featurePath;

  const _FeedbackSubmissionScreenContent({
    Key? key,
    this.initialType,
    this.initialRating,
    this.initialComment,
    this.pageUrl,
    this.featurePath,
  }) : super(key: key);

  @override
  ConsumerState<_FeedbackSubmissionScreenContent> createState() =>
      _FeedbackSubmissionScreenContentState();
}

class _FeedbackSubmissionScreenContentState
    extends ConsumerState<_FeedbackSubmissionScreenContent> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();


  @override
  void initState() {
    super.initState();

    final formNotifier = ref.read(feedbackFormProvider.notifier);

    if (widget.initialType != null) {
      formNotifier.updateType(widget.initialType!);
    }
    if (widget.initialRating != null) {
      formNotifier.updateRating(widget.initialRating);
    }
    if (widget.initialComment != null && widget.initialComment!.isNotEmpty) {
      formNotifier.updateDescription(widget.initialComment!);
    }

    _scrollController.addListener(_onScroll);

  }

  void _onScroll() {
    if (_titleFocusNode.hasFocus) {
      _titleFocusNode.unfocus();
    }
    if (_descriptionFocusNode.hasFocus) {
      _descriptionFocusNode.unfocus();
    }
  }

  Future<void> _submitFeedback() async {
    final info = await PackageInfo.fromPlatform();
    final current = info.version;
    if (!_formKey.currentState!.validate()) return;

    final formState = ref.read(feedbackFormProvider);
    final formNotifier = ref.read(feedbackFormProvider.notifier);

    if (formState.isLoading) return;

    formNotifier.setLoading(true);

    try {
      final profileProvider = ref.read(userProfileProvider);
      final user = profileProvider.value?.userProfile?.user;

      if (user == null) {
        appErrorSnackBar('Error', 'Please login to submit feedback.');
        return;
      }

      // Prepare metadata
      final metadata = FeedbackMetadata(
        pageUrl: widget.pageUrl,
        featurePath: widget.featurePath,
        interactionFlow: 'feedback_screen',
        timeSpent: 120,
      );

      // Generate tags
      final tags = <String>[
        formState.type.name,
        formState.category.name,
        current,
      ];

      if (widget.pageUrl != null) tags.add(widget.pageUrl!);
      if (widget.featurePath != null) tags.add(widget.featurePath!);

      // Create submit params
      final submitParams = SubmitFeedbackParams(
        userId: user.id,
        userName: formState.isAnonymous ? 'Anonymous' : user.username,
        userEmail: user.email,
        type: formState.type,
        category: formState.category,
        title: 'Feedback',
        description: formState.description.trim(),
        priority: formState.priority,
        appVersion: current,
        deviceInfo: DeviceInfo.getCurrentDeviceInfo(),
        rating: formState.rating,
        tags: tags,
        metadata: metadata,
        isAnonymous: formState.isAnonymous,
        allowContact: formState.allowContact,
      );

      final response = await ref.read(submitFeedbackProvider(submitParams).future);

      if (response.status == Status.completed) {
        if (mounted) {
          formNotifier.reset();
          Navigator.pop(context);
          appSuccessSnackBar(
            'Thank You!',
            'Your feedback has been submitted successfully.',
          );
        }
      } else {
        appErrorSnackBar(
          'Submission Failed',
          response.message ?? 'Please try again later.',
        );
      }

    } catch (e) {
      appErrorSnackBar(
        'Error',
        'Failed to submit feedback. Please try again.',
      );
    } finally {
      if (mounted) {
        formNotifier.setLoading(false);
      }
    }
  }

  Widget _buildTypeChip(FeedbackType type, FeedbackFormState state) {
    final formNotifier = ref.read(feedbackFormProvider.notifier);
    final isSelected = state.type == type;

    return GestureDetector(
      onTap: () => formNotifier.updateType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.15)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(type.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            AppText(
              type.displayName,
              weight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(FeedbackCategory category, FeedbackFormState state) {
    final formNotifier = ref.read(feedbackFormProvider.notifier);
    final isSelected = state.category == category;

    return ChoiceChip(
      label: Text(category.displayName),
      selected: isSelected,
      onSelected: (_) => formNotifier.updateCategory(category),
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).primaryColor
            : Theme.of(context).textTheme.bodyMedium?.color,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).dividerColor,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(FeedbackPriority priority, FeedbackFormState state) {
    final formNotifier = ref.read(feedbackFormProvider.notifier);
    final isSelected = state.priority == priority;

    return FilterChip(
      label: Text(priority.displayName),
      selected: isSelected,
      onSelected: (_) => formNotifier.updatePriority(priority),
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: priority.color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected
            ? priority.color
            : Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      avatar: isSelected
          ? Icon(Icons.check, size: 16, color: priority.color)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? priority.color : Theme.of(context).dividerColor,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(feedbackFormProvider);
    final formNotifier = ref.read(feedbackFormProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: AppText.headingSmall('Submit Feedback'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () {
            if (formState.isLoading) return;

            // Check if there's content to save
            if (formState.description.isNotEmpty) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: AppText.bodyMedium('Discard Feedback?'),
                  content: AppText.bodySmall(
                    'You have unsaved feedback. Are you sure you want to discard?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: AppText('Cancel', color: theme.primaryColor),
                    ),
                    TextButton(
                      onPressed: () {
                        formNotifier.reset();
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: AppText('Discard', color: theme.colorScheme.error),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (formState.isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.primaryColor,
                ),
              ),
            ),
        ],
      ),

      body: Form(
        key: _formKey,
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Feedback Type
                AppText.bodyMedium(
                  'Type of Feedback',
                  color: theme.textTheme.titleMedium?.color,
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FeedbackType.values
                      .map((type) => _buildTypeChip(type, formState))
                      .toList(),
                ),

                const SizedBox(height: 24),

                // Feedback Category
                AppText.bodyMedium(
                  'Category',
                  color: theme.textTheme.titleMedium?.color,
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FeedbackCategory.values
                      .map((category) => _buildCategoryChip(category, formState))
                      .toList(),
                ),

                const SizedBox(height: 24),
                //
                // // Title Field
                // TextFormField(
                //   initialValue: formState.title,
                //   focusNode: _titleFocusNode,
                //   decoration: InputDecoration(
                //     labelText: 'Title*',
                //     hintText: 'Brief summary of your feedback',
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     prefixIcon: Icon(Icons.title, color: theme.primaryColor),
                //   ),
                //   maxLength: 200,
                //   validator: (value) {
                //     if (value == null || value.trim().isEmpty) {
                //       return 'Please enter a title';
                //     }
                //     if (value.trim().length < 5) {
                //       return 'Title should be at least 5 characters';
                //     }
                //     return null;
                //   },
                //   textInputAction: TextInputAction.next,
                //   onChanged: (value) => formNotifier.updateTitle(value),
                // ),
                //
                // const SizedBox(height: 20),
                //
                // // Description Field
                TextFormField(
                  initialValue: formState.description,
                  focusNode: _descriptionFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Feedback Description*',
                    hintText: 'Detailed explanation of your feedback',
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.9),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
                  minLines: 4,
                  maxLength: 2000,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    if (value.trim().length < 20) {
                      return 'Description should be at least 20 characters';
                    }
                    return null;
                  },
                  onChanged: (value) => formNotifier.updateDescription(value),
                ),

                const SizedBox(height: 20),
                AppText.bodyMedium(
                  'Priority',
                  color: theme.textTheme.titleMedium?.color,
                ),

                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FeedbackPriority.values
                      .map((priority) => _buildPriorityChip(priority, formState))
                      .toList(),
                ),

                const SizedBox(height: 24),
                AppText.bodyMedium(
                  'Rating (Optional)',
                  color: theme.textTheme.titleMedium?.color,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final rating = index + 1;
                    final isSelected = formState.rating == rating;
                    return GestureDetector(
                      onTap: () => formNotifier.updateRating(isSelected ? null : rating),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            rating <= (formState.rating ?? 0)
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            key: ValueKey('star_${rating}_${isSelected}'),
                            size: 48,
                            color: rating <= (formState.rating ?? 0)
                                ? Colors.amber
                                : theme.disabledColor,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AppText.bodyMedium(
                        //   'Privacy Options',
                        //   color: theme.textTheme.titleMedium?.color,
                        // ),
                        //
                        // const SizedBox(height: 16),

                        // SwitchListTile(
                        //   title: AppText.bodySmall('Submit Anonymously'),
                        //   subtitle: AppText.caption(
                        //       'Your name and email will not be visible'),
                        //   value: formState.isAnonymous,
                        //   onChanged: (_) => formNotifier.toggleAnonymous(),
                        //   contentPadding: EdgeInsets.zero,
                        //   activeColor: theme.primaryColor,
                        // ),

                        SwitchListTile(
                          title: AppText.bodySmall('Allow Contact'),
                          subtitle: AppText.caption(
                              'We may contact you for follow-up'),
                          value: formState.allowContact,
                          onChanged: formState.isAnonymous
                              ? null
                              : (_) => formNotifier.toggleAllowContact(),
                          contentPadding: EdgeInsets.zero,
                          activeColor: theme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (!formState.isValid || formState.isLoading)
                        ? null
                        : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: formState.isLoading
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        AppText(
                          'Submitting...',
                          color: theme.colorScheme.onPrimary,
                          weight: FontWeight.w600,
                        ),
                      ],
                    )
                        : AppText(
                      'Submit Feedback',
                      color: theme.colorScheme.onPrimary,
                      weight: FontWeight.w600,
                      size: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Center(
                  child: AppText.caption(
                    'Your feedback helps us improve Artleap.ai for everyone',
                    color: theme.disabledColor,
                  ),
                ),

                const SizedBox(height: 62),
              ],
            ),
          ),
        ),
      ),
    );
  }
}