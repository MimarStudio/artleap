import 'package:dio/dio.dart';
import 'package:Artleap.ai/domain/api_repos_abstract/auth_repo.dart';
import '../../shared/constants/app_api_paths.dart';
import '../../shared/constants/user_data.dart';
import '../api_services/api_response.dart';
import '../api_services/handling_response.dart';

class AuthRepoImpl extends AuthRepo {
  @override
  Future<ApiResponse> login({required Map<String, dynamic> body}) async {
    try {
      Response res = await artleapApiService.postJson(AppApiPaths.login, body);
      ApiResponse result = HandlingResponse.returnResponse(res);
      if (result.status == Status.completed) {
        final userData = res.data['user'];
        UserData.ins.setUserData(
          id: userData['userId'] ?? '',
          name: userData['username'] ?? '',
          userprofilePicture: userData['profilePic'] ?? '',
          email: userData['email'] ?? '',
        );
        return ApiResponse.completed(res.data);
      } else {
        return result;
      }
    } on DioException catch (w) {
      return HandlingResponse.returnException(w);
    }
  }

  @override
  Future<ApiResponse> signup({required Map<String, dynamic> body}) async {
    try {
      Response res = await artleapApiService.postJson(AppApiPaths.signup, body);
      ApiResponse result = HandlingResponse.returnResponse(res);
      if (result.status == Status.completed) {
        return ApiResponse.completed(res.data);
      } else {
        return result;
      }
    } on DioException catch (w) {
      return HandlingResponse.returnException(w);
    }
  }

  @override
  Future<ApiResponse> googleLogin({required Map<String, dynamic> body}) async {
    try {
      Response res = await artleapApiService.postJson(AppApiPaths.googleLogin, body);
      ApiResponse result = HandlingResponse.returnResponse(res);
      if (result.status == Status.completed) {
        return ApiResponse.completed(res.data);
      } else {
        return result;
      }
    } on DioException catch (w) {
      print('Google Login Failed ${w}');
      return HandlingResponse.returnException(w);
    }
  }

  @override
  Future<ApiResponse> appleLogin({required Map<String, dynamic> body}) async {
    try {
      Response res = await artleapApiService.postJson(AppApiPaths.appleLogin, body);
      ApiResponse result = HandlingResponse.returnResponse(res);
      if (result.status == Status.completed) {
        return ApiResponse.completed(res.data);
      } else {
        return result;
      }
    } on DioException catch (w) {
      return HandlingResponse.returnException(w);
    }
  }

  @override
  Future<ApiResponse> forgotPassword({required Map<String, dynamic> body}) async {
    try {
      Response res = await artleapApiService.postJson(AppApiPaths.forgotPassword, body);
      ApiResponse result = HandlingResponse.returnResponse(res);
      if (result.status == Status.completed) {
        return ApiResponse.completed('Success');
      } else {
        return result;
      }
    } on DioException catch (w) {
      return HandlingResponse.returnException(w);
    }
  }
}