import 'dart:isolate';
import 'package:Artleap.ai/domain/feedback/feedback_model.dart';
import 'package:Artleap.ai/domain/feedback/feedback_repo.dart';
import 'package:dio/dio.dart';
import '../../shared/constants/app_api_paths.dart';
import '../api_services/api_response.dart';
import '../api_services/handling_response.dart';

class FeedbackRepoImpl extends FeedbackRepo {
  @override
  Future<ApiResponse> submitFeedback(Map<String, dynamic> data, {bool enableLocalPersistence = false}) async {
    try {
      final response = await artleapApiService.postJson(
        AppApiPaths.submitFeedback,
        data,
        enableLocalPersistence: enableLocalPersistence,
      );
      final result = HandlingResponse.returnResponse(response);
      if (result.status == Status.processing) {
        return ApiResponse.processing("Submitting feedback...");
      } else if (result.status == Status.completed) {
        final feedbackData = await Isolate.run(() => FeedbackModel.fromJson(response.data['data']));
        return ApiResponse.completed(feedbackData);
      } else {
        return result;
      }
    } on DioException catch (e) {
      return HandlingResponse.returnException(e);
    }
  }

  @override
  Future<ApiResponse> getFeedbackList({Map<String, dynamic>? filters, bool enableLocalPersistence = false}) async {
    try {
      String queryString = '';
      if (filters != null) {
        final queryParams = filters.entries
            .where((entry) => entry.value != null)
            .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value.toString())}')
            .join('&');
        if (queryParams.isNotEmpty) {
          queryString = '?$queryParams';
        }
      }

      final response = await artleapApiService.get(
        '${AppApiPaths.getFeedbackList}$queryString',
        enableLocalPersistence: enableLocalPersistence,
      );
      final result = HandlingResponse.returnResponse(response);
      if (result.status == Status.processing) {
        return ApiResponse.processing("Fetching feedback...");
      } else if (result.status == Status.completed) {
        final data = response.data['data'] as List;
        final pagination = response.data['pagination'];
        final feedbackList = await Isolate.run(() => data.map((e) => FeedbackModel.fromJson(e)).toList());
        return ApiResponse.completed({
          'feedbacks': feedbackList,
          'pagination': pagination,
        });
      } else {
        return result;
      }
    } on DioException catch (e) {
      return HandlingResponse.returnException(e);
    }
  }

  @override
  Future<ApiResponse> getFeedbackById(String feedbackId, {bool enableLocalPersistence = false}) async {
    try {
      final response = await artleapApiService.get(
        '${AppApiPaths.getFeedbackById}/$feedbackId',
        enableLocalPersistence: enableLocalPersistence,
      );
      final result = HandlingResponse.returnResponse(response);
      if (result.status == Status.processing) {
        return ApiResponse.processing("Fetching feedback details...");
      } else if (result.status == Status.completed) {
        final feedbackData = await Isolate.run(() => FeedbackModel.fromJson(response.data['data']));
        return ApiResponse.completed(feedbackData);
      } else {
        return result;
      }
    } on DioException catch (e) {
      return HandlingResponse.returnException(e);
    }
  }

  @override
  Future<ApiResponse> updateFeedback(String feedbackId, Map<String, dynamic> data, {bool enableLocalPersistence = false}) async {
    try {
      final response = await artleapApiService.putJson(
        '${AppApiPaths.updateFeedback}/$feedbackId',
        data,
        enableLocalPersistence: enableLocalPersistence,
      );
      final result = HandlingResponse.returnResponse(response);
      if (result.status == Status.processing) {
        return ApiResponse.processing("Updating feedback...");
      } else if (result.status == Status.completed) {
        final feedbackData = await Isolate.run(() => FeedbackModel.fromJson(response.data['data']));
        return ApiResponse.completed(feedbackData);
      } else {
        return result;
      }
    } on DioException catch (e) {
      return HandlingResponse.returnException(e);
    }
  }

  @override
  Future<ApiResponse> deleteFeedback(String feedbackId, {bool enableLocalPersistence = false}) async {
    try {
      final response = await artleapApiService.delete(
        '${AppApiPaths.deleteFeedback}/$feedbackId',
        enableLocalPersistence: enableLocalPersistence,
      );
      final result = HandlingResponse.returnResponse(response);
      if (result.status == Status.processing) {
        return ApiResponse.processing("Deleting feedback...");
      } else if (result.status == Status.completed) {
        return ApiResponse.completed(response.data['message'] ?? "Feedback deleted successfully");
      } else {
        return result;
      }
    } on DioException catch (e) {
      return HandlingResponse.returnException(e);
    }
  }

  @override
  Future<ApiResponse> addUpvote(String feedbackId, {bool enableLocalPersistence = false}) async {
    try {
      final response = await artleapApiService.postJson(
        '${AppApiPaths.addUpvote}/$feedbackId',
        {},
        enableLocalPersistence: enableLocalPersistence,
      );
      final result = HandlingResponse.returnResponse(response);
      if (result.status == Status.processing) {
        return ApiResponse.processing("Adding upvote...");
      } else if (result.status == Status.completed) {
        return ApiResponse.completed(response.data['data']);
      } else {
        return result;
      }
    } on DioException catch (e) {
      return HandlingResponse.returnException(e);
    }
  }

  @override
  Future<ApiResponse> getUserFeedback(String userId, {bool enableLocalPersistence = false}) async {
    try {
      final response = await artleapApiService.get(
        '${AppApiPaths.getUserFeedback}/$userId',
        enableLocalPersistence: enableLocalPersistence,
      );
      final result = HandlingResponse.returnResponse(response);
      if (result.status == Status.processing) {
        return ApiResponse.processing("Fetching user feedback...");
      } else if (result.status == Status.completed) {
        final data = response.data['data'] as List;
        final pagination = response.data['pagination'];
        final feedbackList = await Isolate.run(() => data.map((e) => FeedbackModel.fromJson(e)).toList());
        return ApiResponse.completed({
          'feedbacks': feedbackList,
          'pagination': pagination,
        });
      } else {
        return result;
      }
    } on DioException catch (e) {
      return HandlingResponse.returnException(e);
    }
  }

  @override
  Future<ApiResponse> getFeedbackStats({Map<String, dynamic>? filters, bool enableLocalPersistence = false}) async {
    try {
      String queryString = '';
      if (filters != null) {
        final queryParams = filters.entries
            .where((entry) => entry.value != null)
            .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value.toString())}')
            .join('&');
        if (queryParams.isNotEmpty) {
          queryString = '?$queryParams';
        }
      }

      final response = await artleapApiService.get(
        '${AppApiPaths.getFeedbackStats}$queryString',
        enableLocalPersistence: enableLocalPersistence,
      );
      final result = HandlingResponse.returnResponse(response);
      if (result.status == Status.processing) {
        return ApiResponse.processing("Fetching feedback statistics...");
      } else if (result.status == Status.completed) {
        return ApiResponse.completed(response.data['data']);
      } else {
        return result;
      }
    } on DioException catch (e) {
      return HandlingResponse.returnException(e);
    }
  }
}