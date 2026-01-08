import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/app_persistance/app_data.dart';

class DioCore {
  late final Dio _dio;
  Dio get dio => _dio;

  static Completer<String?>? _refreshCompleter;

  DioCore(String baseUrl) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        validateStatus: (status) => true,
        connectTimeout: const Duration(minutes: 3),
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(minutes: 3),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = AppData.instance.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          final uid = AppData.instance.userId;
          if (uid != null && uid.isNotEmpty) {
            options.headers['userId'] = uid;
            options.headers['userid'] = uid;
          }
          final fuid = AppData.instance.firebaseUid;
          if (fuid != null && fuid.isNotEmpty) {
            options.headers['firebaseUid'] = fuid;
            options.headers['firebaseuid'] = fuid;
          }

          handler.next(options);
        },

        onError: (e, handler) async {
          _debugLogIfUserIdRequired(e);

          final status = e.response?.statusCode;
          if (status == 401) {
            try {
              if (_refreshCompleter != null) {
                final fresh = await _refreshCompleter!.future;
                if (fresh != null && fresh.isNotEmpty) {
                  final retried = await _retryWithToken(_dio, e.requestOptions, fresh);
                  return handler.resolve(retried);
                }
                return handler.next(e);
              }

              _refreshCompleter = Completer<String?>();

              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await user.reload();
                final freshToken = await user.getIdToken(true);
                if (freshToken != null && freshToken.isNotEmpty) {
                  AppData.instance.setToken(freshToken);
                  _refreshCompleter!.complete(freshToken);

                  final retried = await _retryWithToken(_dio, e.requestOptions, freshToken);
                  _refreshCompleter = null;
                  return handler.resolve(retried);
                }
              }

              _refreshCompleter!.complete(null);
              _refreshCompleter = null;
              return handler.next(e);
            } catch (err) {
              if (_refreshCompleter != null && !(_refreshCompleter!.isCompleted)) {
                _refreshCompleter!.complete(null);
              }
              _refreshCompleter = null;
              return handler.next(e);
            }
          }

          return handler.next(e);
        },
      ),
    );
  }

  static Future<Response<dynamic>> _retryWithToken(
      Dio dio,
      RequestOptions req,
      String token,
      ) async {
    if (req.data is FormData) {
      return Future.error(DioException(
        requestOptions: req,
        error:
        'Cannot safely retry FormData request after 401 (stream not rewindable). Ensure token is valid before upload.',
        type: DioExceptionType.unknown,
      ));
    }

    final opts = Options(
      method: req.method,
      headers: {
        ...req.headers,
        'Authorization': 'Bearer $token',
      },
      responseType: req.responseType,
      contentType: req.contentType,
      sendTimeout: req.sendTimeout,
      receiveTimeout: req.receiveTimeout,
      followRedirects: req.followRedirects,
      validateStatus: req.validateStatus,
    );

    final pathOrUrl = req.path.startsWith('http')
        ? req.path
        : req.uri.toString().replaceFirst(req.baseUrl, '');

    return dio.request<dynamic>(
      pathOrUrl,
      data: req.data,
      queryParameters: req.queryParameters,
      options: opts,
      cancelToken: req.cancelToken,
      onReceiveProgress: req.onReceiveProgress,
      onSendProgress: req.onSendProgress,
    );
  }

  void _debugLogIfUserIdRequired(DioException e) {
    final res = e.response;
    final data = res?.data;
    final msg = _extractMessage(data)?.toLowerCase() ?? '';

    final mentionsUserIdRequired = msg.contains('user id is required') ||
        msg.contains('userid is required') ||
        msg.contains('userId is required'.toLowerCase()) ||
        msg.contains('user_id is required');

    if (mentionsUserIdRequired) {
      final r = e.requestOptions;
      final url = r.uri.toString();
      if (r.data != null) {
        print('   body   : ${r.data}');
      }
      print('   status : ${res?.statusCode}');
      print('   response: ${res?.data}');
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      if (data['message'] is String && (data['message'] as String).isNotEmpty) {
        return data['message'] as String;
      }
      if (data['error'] is String && (data['error'] as String).isNotEmpty) {
        return data['error'] as String;
      }
      if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        final first = (data['errors'] as List).first;
        if (first is String) return first;
        if (first is Map && first['message'] is String) return first['message'] as String;
      }
    } else if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    return null;
  }
}
