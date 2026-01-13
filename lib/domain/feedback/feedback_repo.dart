import '../api_services/api_response.dart';
import '../base_repo/base.dart';

abstract class FeedbackRepo extends Base {
  Future<ApiResponse> submitFeedback(Map<String, dynamic> data, {bool enableLocalPersistence = false});
  Future<ApiResponse> getFeedbackList({Map<String, dynamic>? filters, bool enableLocalPersistence = false});
  Future<ApiResponse> getFeedbackById(String feedbackId, {bool enableLocalPersistence = false});
  Future<ApiResponse> updateFeedback(String feedbackId, Map<String, dynamic> data, {bool enableLocalPersistence = false});
  Future<ApiResponse> deleteFeedback(String feedbackId, {bool enableLocalPersistence = false});
  Future<ApiResponse> addUpvote(String feedbackId, {bool enableLocalPersistence = false});
  Future<ApiResponse> getUserFeedback(String userId, {bool enableLocalPersistence = false});
  Future<ApiResponse> getFeedbackStats({Map<String, dynamic>? filters, bool enableLocalPersistence = false});
}