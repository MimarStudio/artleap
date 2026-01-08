import 'package:Artleap.ai/domain/api_services/api_response.dart';
import 'package:Artleap.ai/domain/feedback/feedback_repo.dart';
import 'feedback_model.dart';

class FeedbackService {
  final FeedbackRepo _feedbackRepo;

  FeedbackService(this._feedbackRepo);

  Future<ApiResponse> submitFeedback({
    required String userId,
    required String userName,
    required String userEmail,
    required FeedbackType type,
    required FeedbackCategory category,
    required String title,
    required String description,
    FeedbackPriority priority = FeedbackPriority.medium,
    required String appVersion,
    DeviceInfo? deviceInfo,
    List<FeedbackAttachment> attachments = const [],
    int? rating,
    List<String> tags = const [],
    FeedbackMetadata? metadata,
    bool isAnonymous = false,
    bool allowContact = true,
  }) async {
    final data = {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'type': type.name,
      'category': category.name,
      'title': title,
      'description': description,
      'priority': priority.name,
      'appVersion': appVersion,
      'deviceInfo': deviceInfo?.toJson() ?? DeviceInfo.getCurrentDeviceInfo().toJson(),
      'attachments': attachments.map((e) => e.toJson()).toList(),
      if (rating != null) 'rating': rating,
      'tags': tags,
      'metadata': metadata?.toJson() ?? {},
      'isAnonymous': isAnonymous,
      'allowContact': isAnonymous ? false : allowContact,
    };

    return await _feedbackRepo.submitFeedback(data);
  }

  Future<ApiResponse> getFeedbackList({
    int page = 1,
    int limit = 20,
    FeedbackType? type,
    FeedbackCategory? category,
    FeedbackStatus? status,
    FeedbackPriority? priority,
    String? search,
    String? userId,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final filters = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    if (type != null) filters['type'] = type.name;
    if (category != null) filters['category'] = category.name;
    if (status != null) filters['status'] = status.name;
    if (priority != null) filters['priority'] = priority.name;
    if (search != null && search.isNotEmpty) filters['search'] = search;
    if (userId != null) filters['userId'] = userId;

    return await _feedbackRepo.getFeedbackList(filters: filters);
  }

  Future<ApiResponse> getFeedbackById(String feedbackId) async {
    return await _feedbackRepo.getFeedbackById(feedbackId);
  }

  Future<ApiResponse> updateFeedback({
    required String feedbackId,
    FeedbackStatus? status,
    FeedbackPriority? priority,
    String? adminResponse,
    List<String>? tags,
    bool? markResolved,
  }) async {
    final data = <String, dynamic>{};

    if (status != null) data['status'] = status.name;
    if (priority != null) data['priority'] = priority.name;
    if (adminResponse != null) {
      data['adminResponse'] = {
        'message': adminResponse,
      };
    }
    if (tags != null) data['tags'] = tags;
    if (markResolved == true) {
      data['resolvedAt'] = DateTime.now().toIso8601String();
    }

    return await _feedbackRepo.updateFeedback(feedbackId, data);
  }

  Future<ApiResponse> deleteFeedback(String feedbackId) async {
    return await _feedbackRepo.deleteFeedback(feedbackId);
  }

  Future<ApiResponse> addUpvote(String feedbackId) async {
    return await _feedbackRepo.addUpvote(feedbackId);
  }

  Future<ApiResponse> getUserFeedback(String userId, {int page = 1, int limit = 20}) async {
    return await _feedbackRepo.getUserFeedback(userId);
  }

  Future<ApiResponse> getFeedbackStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final filters = <String, dynamic>{};

    if (startDate != null) {
      filters['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      filters['endDate'] = endDate.toIso8601String();
    }

    return await _feedbackRepo.getFeedbackStats(filters: filters);
  }
}