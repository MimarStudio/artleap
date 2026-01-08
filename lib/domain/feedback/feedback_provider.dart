import 'package:Artleap.ai/domain/feedback/feedback_model.dart';
import 'package:Artleap.ai/domain/feedback/feedback_repo_impl.dart';
import 'package:Artleap.ai/domain/feedback/feedback_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Artleap.ai/domain/api_services/api_response.dart';

final feedbackRepoProvider = Provider<FeedbackRepoImpl>((ref) => FeedbackRepoImpl());

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  final repo = ref.read(feedbackRepoProvider);
  return FeedbackService(repo);
});

final feedbackListProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, filters) async {
  final service = ref.read(feedbackServiceProvider);
  final response = await service.getFeedbackList(
    page: filters['page'] ?? 1,
    limit: filters['limit'] ?? 20,
    type: filters['type'] != null ? FeedbackType.values.byName(filters['type']) : null,
    category: filters['category'] != null ? FeedbackCategory.values.byName(filters['category']) : null,
    status: filters['status'] != null ? FeedbackStatus.values.byName(filters['status']) : null,
    priority: filters['priority'] != null ? FeedbackPriority.values.byName(filters['priority']) : null,
    search: filters['search'],
    userId: filters['userId'],
    sortBy: filters['sortBy'] ?? 'createdAt',
    sortOrder: filters['sortOrder'] ?? 'desc',
  );

  if (response.status == Status.completed && response.data != null) {
    return response.data as Map<String, dynamic>;
  }
  throw Exception(response.message ?? 'Failed to fetch feedback list');
});

final userFeedbackProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final service = ref.read(feedbackServiceProvider);
  final response = await service.getUserFeedback(
    params['userId']!,
  );

  if (response.status == Status.completed && response.data != null) {
    return response.data as Map<String, dynamic>;
  }
  throw Exception(response.message ?? 'Failed to fetch user feedback');
});

final feedbackStatsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, filters) async {
  final service = ref.read(feedbackServiceProvider);
  final response = await service.getFeedbackStats(
    startDate: filters['startDate'] != null ? DateTime.parse(filters['startDate']!) : null,
    endDate: filters['endDate'] != null ? DateTime.parse(filters['endDate']!) : null,
  );

  if (response.status == Status.completed && response.data != null) {
    return response.data as Map<String, dynamic>;
  }
  throw Exception(response.message ?? 'Failed to fetch feedback statistics');
});

final submitFeedbackProvider = FutureProvider.family<ApiResponse, SubmitFeedbackParams>((ref, params) async {
  final service = ref.read(feedbackServiceProvider);
  return await service.submitFeedback(
    userId: params.userId,
    userName: params.userName,
    userEmail: params.userEmail,
    type: params.type,
    category: params.category,
    title: params.title,
    description: params.description,
    priority: params.priority,
    appVersion: params.appVersion,
    deviceInfo: params.deviceInfo,
    rating: params.rating,
    tags: params.tags,
    metadata: params.metadata,
    isAnonymous: params.isAnonymous,
    allowContact: params.allowContact,
  );
});

class SubmitFeedbackParams {
  final String userId;
  final String userName;
  final String userEmail;
  final FeedbackType type;
  final FeedbackCategory category;
  final String title;
  final String description;
  final FeedbackPriority priority;
  final String appVersion;
  final DeviceInfo? deviceInfo;
  final int? rating;
  final List<String> tags;
  final FeedbackMetadata? metadata;
  final bool isAnonymous;
  final bool allowContact;

  SubmitFeedbackParams({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    this.priority = FeedbackPriority.medium,
    required this.appVersion,
    this.deviceInfo,
    this.rating,
    this.tags = const [],
    this.metadata,
    this.isAnonymous = false,
    this.allowContact = true,
  });
}

final upvoteFeedbackProvider = FutureProvider.family<ApiResponse, String>((ref, feedbackId) async {
  final service = ref.read(feedbackServiceProvider);
  return await service.addUpvote(feedbackId);
});

final feedbackDetailProvider = FutureProvider.family<FeedbackModel?, String>((ref, feedbackId) async {
  final service = ref.read(feedbackServiceProvider);
  final response = await service.getFeedbackById(feedbackId);

  if (response.status == Status.completed && response.data != null) {
    return response.data as FeedbackModel;
  }
  return null;
});

final userFeedbackListProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final service = ref.read(feedbackServiceProvider);
  final response = await service.getUserFeedback(userId);

  if (response.status == Status.completed && response.data != null) {
    return response.data as Map<String, dynamic>;
  }
  throw Exception('Failed to fetch feedback');
});