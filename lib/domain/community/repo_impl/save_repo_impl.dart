import 'package:dio/dio.dart';
import '../../../shared/constants/app_api_paths.dart';
import '../../api_services/api_response.dart';
import '../../api_services/handling_response.dart';
import '../../base_repo/base.dart';
import '../models/save_model.dart';


abstract class SaveRepo extends Base {
  Future<ApiResponse> getSavedPosts({int page, int limit});
  Future<ApiResponse> savePost(String imageId);
  Future<ApiResponse> unsavePost(String imageId);
  Future<ApiResponse> isSaved(String imageId);
  Future<ApiResponse> getSavedCount();
}


class SaveRepoImpl extends SaveRepo {
  Future<ApiResponse> getSavedPosts({int page = 1, int limit = 20}) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
      };

      Response res = await artleapApiService.get(AppApiPaths.getUserSavedImages, queryParameters: queryParams);

      ApiResponse result = HandlingResponse.returnResponse(res);

      if (result.status == Status.completed) {
        final savedData = res.data['data'] as List<dynamic>;
        final savedPosts = savedData.map((json) => SaveModel.fromJson(json)).toList();
        return ApiResponse.completed(savedPosts);
      } else {
        return result;
      }
    } on DioException catch (e) {
      print(e.message);
      return HandlingResponse.returnException(e);
    }
  }

  Future<ApiResponse> savePost(String imageId) async {
    try {
      final path = AppApiPaths.saveImage.replaceFirst(':imageId', imageId);

      Response res = await artleapApiService.postJson(path, {});
      print(res);
      ApiResponse result = HandlingResponse.returnResponse(res);

      if (result.status == Status.completed) {
        final saveData = res.data['data'];
        final savedPost = SaveModel.fromJson(saveData);
        return ApiResponse.completed(savedPost);
      } else {
        return result;
      }
    } on DioException catch (e) {
      print(e.message);
      return HandlingResponse.returnException(e);
    }
  }

  Future<ApiResponse> unsavePost(String imageId) async {
    try {
      final path = AppApiPaths.unsaveImage.replaceFirst(':imageId', imageId);

      Response res = await artleapApiService.delete(path);
      ApiResponse result = HandlingResponse.returnResponse(res);

      if (result.status == Status.completed) {
        return ApiResponse.completed(true);
      } else {
        return result;
      }
    } on DioException catch (e) {
      return HandlingResponse.returnException(e);
    }
  }

  Future<ApiResponse> isSaved(String imageId) async {
    try {
      final path = AppApiPaths.checkUserSave.replaceFirst(':imageId', imageId);

      Response res = await artleapApiService.get(path);
      ApiResponse result = HandlingResponse.returnResponse(res);

      if (result.status == Status.completed) {
        final isSaved = res.data['data']['isSaved'] ?? false;
        return ApiResponse.completed(isSaved);
      } else {
        return result;
      }
    } on DioException catch (e) {
      return HandlingResponse.returnException(e);
    }
  }

  Future<ApiResponse> getSavedCount() async {
    try {
      Response res = await artleapApiService.get(AppApiPaths.getSavedCount);
      ApiResponse result = HandlingResponse.returnResponse(res);

      if (result.status == Status.completed) {
        final count = res.data['data']['savedCount'] ?? 0;
        return ApiResponse.completed(count);
      } else {
        return result;
      }
    } on DioException catch (e) {
      return HandlingResponse.returnException(e);
    }
  }
}