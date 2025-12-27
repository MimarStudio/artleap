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

    // Register device token on app startup if user is logged in
    await registerDeviceTokenOnStartup(ref);

    final userId = UserData.ins.userId;
    if (userId != null) {
      ref.read(notificationProvider(userId).notifier).loadNotifications();
    }

    return token;
  }

  // NEW: Register device token on app startup
  static Future<void> registerDeviceTokenOnStartup(WidgetRef ref) async {
    try {
      final userId = UserData.ins.userId;
      if (userId == null || userId.isEmpty) {
        debugPrint('No user ID found, skipping device token registration');
        return;
      }

      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();

      if (token != null) {
        final repo = ref.read(notificationRepositoryProvider);
        await repo.registerDeviceToken(userId, token);
        debugPrint('Device token registered on startup for user: $userId');
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) async {
        if (UserData.ins.userId != null) {
          final repo = ref.read(notificationRepositoryProvider);
          await repo.registerDeviceToken(UserData.ins.userId!, newToken);
          debugPrint('Device token refreshed for user: ${UserData.ins.userId}');
        }
      });
    } catch (e, stack) {
      debugPrint('Error registering device token on startup: $e\n$stack');
    }
  }

  // Existing method - keep for backward compatibility
  static Future<void> registerUserDeviceToken(Ref ref) async {
    try {
      final userId = UserData.ins.userId;
      if (userId == null || userId.isEmpty) {
        return;
      }

      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();

      if (token != null) {
        final repo = ref.read(notificationRepositoryProvider);
        await repo.registerDeviceToken(userId, token);
      }

      messaging.onTokenRefresh.listen((newToken) async {
        if (UserData.ins.userId != null) {
          final repo = ref.read(notificationRepositoryProvider);
          await repo.registerDeviceToken(UserData.ins.userId!, newToken);
        }
      });
    } catch (e, stack) {
      debugPrint(stack.toString());
    }
  }

  static Future<void> registerUserDeviceTokenRef(WidgetRef ref) async {
    try {
      final userId = UserData.ins.userId;
      if (userId == null || userId.isEmpty) {
        return;
      }

      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();

      if (token != null) {
        final repo = ref.read(notificationRepositoryProvider);
        await repo.registerDeviceToken(userId, token);
      }

      messaging.onTokenRefresh.listen((newToken) async {
        if (UserData.ins.userId != null) {
          final repo = ref.read(notificationRepositoryProvider);
          await repo.registerDeviceToken(UserData.ins.userId!, newToken);
        }
      });
    } catch (e, stack) {
      debugPrint(stack.toString());
    }
  }
}