import 'dart:async';
import 'package:Artleap.ai/domain/notification_services/firebase_notification_service.dart';
import 'package:Artleap.ai/domain/notifications_repo/notification_repository.dart';
import 'package:Artleap.ai/shared/route_export.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Artleap.ai/firebase_options.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../di/di.dart';

class AppInitialization {
  static Future<bool> checkNetworkConnectivity() async {
    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Network connectivity check failed: $e');
      return false;
    }
  }

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    final isConnected = await checkNetworkConnectivity();
    if (!isConnected) {
      throw Exception('No internet connection available');
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await RemoteConfigService.instance.initialize();
    await RemoteConfigService.instance.fetchAndActivate();

    await AppLocal.ins.initStorage();
    await DI.initDI();

    await dotenv.load(fileName: ".env");
    Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
    try {
      await Stripe.instance.applySettings();
    } catch (e) {
      print("Stripe initialization failed: $e");
    }

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ));
  }

  static Future<bool> shouldShowTutorial(WidgetRef ref) async {
    try {
      final storageService = ref.read(tutorialStorageServiceProvider);
      await storageService.init();
      return !storageService.hasSeenTutorial();
    } catch (e) {
      debugPrint('Error checking tutorial status: $e');
      return true;
    }
  }

  static Future<String?> initializeAuthAndNotifications(WidgetRef ref) async {
    final isConnected = await checkNetworkConnectivity();
    if (!isConnected) {
      debugPrint('Skipping auth initialization: No network connection');
      return null;
    }

    final token = await ref.read(authprovider).ensureValidFirebaseToken();

    await ref.read(firebaseNotificationServiceProvider).initialize();
    final userId = UserData.ins.userId;
    if (userId != null) {
      ref.read(notificationProvider(userId).notifier).loadNotifications();
    }

    return token;
  }

  static Future<void> registerUserDeviceToken(Ref ref) async {
    try {
      dynamic userId = UserData.ins.userId;
      if (userId == null || userId.isEmpty) {
        final storedUserId = AppLocal.ins.getUSerData(Hivekey.userId);
        if (storedUserId == null || storedUserId.isEmpty) {
          debugPrint('No user ID available for device token registration');
          return;
        }
        userId = storedUserId;
      }

      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final token = await messaging.getToken();
      debugPrint('FCM Token: $token');

      if (token != null && token.isNotEmpty) {
        final repo = ref.read(notificationRepositoryProvider);
        try {
          await repo.registerDeviceToken(userId.toString(), token);
          debugPrint('Device token registered successfully for user: $userId');
        } catch (e) {
          debugPrint('Failed to register device token: $e');
        }
      } else {
        debugPrint('No FCM token available');
      }

      messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM Token refreshed: $newToken');
        if (userId != null && userId.toString().isNotEmpty) {
          final repo = ref.read(notificationRepositoryProvider);
          try {
            await repo.registerDeviceToken(userId.toString(), newToken);
            debugPrint('Refreshed token registered for user: $userId');
          } catch (e) {
            debugPrint('Failed to register refreshed token: $e');
          }
        }
      });
    } catch (e, stack) {
      debugPrint('Error registering device token: $e');
      debugPrint(stack.toString());
    }
  }

  static Future<void> registerUserDeviceTokenWidgetRef(WidgetRef ref) async {
    try {
      dynamic userId = UserData.ins.userId;
      if (userId == null || userId.isEmpty) {
        final storedUserId = AppLocal.ins.getUSerData(Hivekey.userId);
        if (storedUserId == null || storedUserId.isEmpty) {
          return;
        }
        userId = storedUserId;
      }

      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();

      if (token != null && token.isNotEmpty) {
        final repo = ref.read(notificationRepositoryProvider);
        try {
          await repo.registerDeviceToken(userId.toString(), token);
          debugPrint('Device token registered successfully for user: $userId');
        } catch (e) {
          debugPrint('Failed to register device token: $e');
        }
      }

      messaging.onTokenRefresh.listen((newToken) async {
        if (userId != null && userId.toString().isNotEmpty) {
          final repo = ref.read(notificationRepositoryProvider);
          try {
            await repo.registerDeviceToken(userId.toString(), newToken);
          } catch (e) {
            debugPrint('Failed to register refreshed token: $e');
          }
        }
      });
    } catch (e, stack) {
      debugPrint(stack.toString());
    }
  }

  static Future<void> ensureDeviceTokenOnAppStart(Ref ref) async {
    try {
      final userId = AppLocal.ins.getUSerData(Hivekey.userId);
      if (userId != null && userId.isNotEmpty) {
        await Future.delayed(Duration(seconds: 2));
        await registerUserDeviceToken(ref);
      }
    } catch (e) {
      debugPrint('Error ensuring device token on app start: $e');
    }
  }

  static Future<void> ensureDeviceTokenOnAppStartWidgetRef(WidgetRef ref) async {
    try {
      final userId = AppLocal.ins.getUSerData(Hivekey.userId);
      if (userId != null && userId.isNotEmpty) {
        await Future.delayed(Duration(seconds: 2));
        await registerUserDeviceTokenWidgetRef(ref);
      }
    } catch (e) {
      debugPrint('Error ensuring device token on app start: $e');
    }
  }
}