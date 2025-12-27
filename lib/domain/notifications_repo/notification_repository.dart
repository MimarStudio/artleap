import 'package:Artleap.ai/widgets/state_widgets/error_handler.dart';
import 'package:dio/dio.dart';
import '../api_services/dio_core.dart';
import '../../providers/dio_core_provider.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class NotificationRepository {
  final DioCore dioCore;
  final Ref ref;

  NotificationRepository({required this.dioCore, required this.ref});

  Future<void> registerDeviceToken(String userId, String token) async {
    try {
      final response = await dioCore.dio.post(
        '${AppConstants.artleapBaseUrl}${AppConstants.registerToken}',
        data: {
          "userId": userId,
          "fcmToken": token,
        },
      );
      print(response);
    } catch (e) {
      debugPrint("❌ Error sending FCM token: $e");
    }
  }

  Future<List<AppNotification>> getUserNotifications(String userId) async {
    try {
      final response = await dioCore.dio.get(
        '${AppConstants.artleapBaseUrl}${AppConstants.getUserNotificationsPath}$userId',
        options: Options(headers: _getAuthHeader()),
      );

      return _parseNotificationResponse(response);
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await dioCore.dio.patch(
        '${AppConstants.markAsReadPath}$notificationId/read',
        options: Options(headers: _getAuthHeader()),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<void> deleteNotification({
    required String notificationId,
    required String userId,
  }) async {
    try {
      await dioCore.dio.delete(
        '${AppConstants.deleteNotificationPath}$notificationId',
        data: {'userId': userId},
        options: Options(
          headers: _getAuthHeader(),
          contentType: Headers.jsonContentType,
        ),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<void> createNotification({
    required String title,
    required String body,
    required String type,
    String? userId,
    Map<String, dynamic>? data,
  }) async {
    try {
      await dioCore.dio.post(
        AppConstants.createNotificationPath,
        data: {
          'title': title,
          'body': body,
          'type': type,
          'userId': userId,
          'data': data,
        },
        options: Options(headers: _getAuthHeader()),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  List<AppNotification> _parseNotificationResponse(Response response) {
    if (response.statusCode == 200) {
      final List<dynamic> docs = response.data['data']['docs'];
      return docs.map((json) => AppNotification.fromJson(json)).toList();
    } else {
      throw ErrorHandler.handleResponseError(response);
    }
  }

  Map<String, String> _getAuthHeader() {
    return {
      'Authorization': 'Bearer ${AppData.instance.token}',
    };
  }

  Future<void> markAllAsRead(List<String> notificationIds) async {
    try {
      await dioCore.dio.patch(
        AppConstants.markAllAsReadPath,
        data: { 'notificationIds': notificationIds },
        options: Options(headers: _getAuthHeader()),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dioCore = ref.read(dioCoreProvider);
  return NotificationRepository(dioCore: dioCore, ref: ref);
});