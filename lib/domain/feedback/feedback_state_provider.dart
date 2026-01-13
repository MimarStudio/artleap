import 'package:Artleap.ai/domain/feedback/feedback_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final feedbackFormProvider = StateNotifierProvider<FeedbackFormNotifier, FeedbackFormState>((ref) {
  return FeedbackFormNotifier();
});

class FeedbackFormState {
  final FeedbackType type;
  final FeedbackCategory category;
  final FeedbackPriority priority;
  final String title;
  final String description;
  final int? rating;
  final bool isAnonymous;
  final bool allowContact;
  final bool isLoading;
  final bool isValid;

  const FeedbackFormState({
    this.type = FeedbackType.general,
    this.category = FeedbackCategory.other,
    this.priority = FeedbackPriority.medium,
    this.title = 'Feedback',
    this.description = '',
    this.rating,
    this.isAnonymous = false,
    this.allowContact = true,
    this.isLoading = false,
    this.isValid = false,
  });

  FeedbackFormState copyWith({
    FeedbackType? type,
    FeedbackCategory? category,
    FeedbackPriority? priority,
    String? title,
    String? description,
    int? rating,
    bool? isAnonymous,
    bool? allowContact,
    bool? isLoading,
    bool? isValid,
  }) {
    return FeedbackFormState(
      type: type ?? this.type,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      allowContact: allowContact ?? this.allowContact,
      isLoading: isLoading ?? this.isLoading,
      isValid: isValid ?? this.isValid,
    );
  }
}

class FeedbackFormNotifier extends StateNotifier<FeedbackFormState> {
  FeedbackFormNotifier() : super(const FeedbackFormState());

  void updateType(FeedbackType type) {
    state = state.copyWith(type: type);
    _validateForm();
  }

  void updateCategory(FeedbackCategory category) {
    state = state.copyWith(category: category);
  }

  void updatePriority(FeedbackPriority priority) {
    state = state.copyWith(priority: priority);
  }

  void updateTitle(String title) {
    state = state.copyWith(title: title);
    _validateForm();
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
    _validateForm();
  }

  void updateRating(int? rating) {
    state = state.copyWith(rating: rating);
  }

  void toggleAnonymous() {
    state = state.copyWith(
      isAnonymous: !state.isAnonymous,
      allowContact: !state.isAnonymous ? state.allowContact : false,
    );
  }

  void toggleAllowContact() {
    if (!state.isAnonymous) {
      state = state.copyWith(allowContact: !state.allowContact);
    }
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void reset() {
    state = const FeedbackFormState();
  }

  void initialize({
    FeedbackType? type,
    int? rating,
    String? comment,
  }) {
    state = state.copyWith(
      type: type ?? FeedbackType.general,
      rating: rating,
      description: comment ?? '',
    );
    _validateForm();
  }

  void _validateForm() {
    final isValid =  state.description.trim().isNotEmpty;
    state = state.copyWith(isValid: isValid);
  }
}