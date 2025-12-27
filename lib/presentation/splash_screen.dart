import 'package:Artleap.ai/domain/notifications_repo/notification_repository.dart';
import 'package:Artleap.ai/shared/route_export.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SplashScreen extends ConsumerStatefulWidget {
  static const String routeName = "splash_screen";
  const SplashScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasNavigated = false;
  bool _initialized = false;
  bool _deviceTokenRegistered = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _startTime = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final tutorialStorage = ref.read(tutorialStorageServiceProvider);
      await tutorialStorage.init();

      await ref.read(remoteConfigProvider).initialize();
      await ref.read(remoteConfigProvider).fetchAndActivate();

      await ref.read(splashStateProvider.notifier).initializeApp();
    } catch (e) {
      print('SplashScreen: Error in _initializeApp: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(splashStateProvider);

    ref.listen<SplashState>(splashStateProvider, (previous, current) {
      if (current == SplashState.readyToNavigate && !_hasNavigated) {
        _hasNavigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToNextScreen();
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.darkIndigo,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Lottie.asset(
            'assets/json/splashscreen.json',
            fit: BoxFit.cover,
            controller: _controller,
            onLoaded: (composition) {
              _controller
                ..duration = composition.duration
                ..forward();
            },
          ),
          Center(
            child: Lottie.asset(
              'assets/json/logo.json',
              fit: BoxFit.cover,
            ),
          ),
          if (state == SplashState.noInternet ||
              state == SplashState.firebaseError)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    state == SplashState.noInternet
                        ? 'No internet connection'
                        : 'Service unavailable. Please try again',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _startTime = DateTime.now();
                      ref
                          .read(splashStateProvider.notifier)
                          .retryInitialization();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _navigateToNextScreen() async {
    try {
      final elapsedTime = DateTime.now().difference(_startTime!);
      final remainingTime = Duration(seconds: 3) - elapsedTime;

      if (remainingTime > Duration.zero) {
        await Future.delayed(remainingTime);
      }

      if (!mounted) return;

      await ref.read(remoteConfigProvider).fetchAndActivate();

      await _registerDeviceTokenIfNeeded();

      final showAppOpenAds = ref.read(appOpenAdsEnabledProvider);

      if (showAppOpenAds) {
        final appOpenAdManager = ref.read(appOpenAdProvider);

        await Future.delayed(const Duration(seconds: 1));

        final adShown = await appOpenAdManager.showAppOpenAd(ref);

        if (adShown) {
          await Future.delayed(const Duration(seconds: 1));
        } else {
          print('SplashScreen: App open ad not shown, continuing navigation');
        }
      }

      final hasSeenTutorial =
      await ArtleapNavigationManager.getTutorialStatus(ref);
      final userData = ArtleapNavigationManager.getUserDataFromStorage();

      await ArtleapNavigationManager.navigateBasedOnUserStatus(
        context: context,
        ref: ref,
        userId: userData['userId'],
        userName: userData['userName'],
        userProfilePicture: userData['userProfilePicture'],
        userEmail: userData['userEmail'],
        hasSeenTutorial: hasSeenTutorial,
      );
    } catch (e) {
      print('SplashScreen: Error in navigation: $e');
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginScreen.routeName,
              (Route<dynamic> route) => false,
        );
      }
    }
  }

  Future<void> _registerDeviceTokenIfNeeded() async {
    try {
      if (_deviceTokenRegistered) {
        debugPrint('Device token already registered in this session');
        return;
      }
      String? userId;

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        userId = firebaseUser.uid;
        debugPrint('Found Firebase user: $userId');
      }

      if (userId == null || userId.isEmpty) {
        userId = AppLocal.ins.getUSerData(Hivekey.userId);
        if (userId != null && userId.isNotEmpty) {
          debugPrint('Found user in local storage: $userId');
        }
      }

      if ((userId == null || userId.isEmpty) &&
          UserData.ins.userId != null &&
          UserData.ins.userId!.isNotEmpty) {
        userId = UserData.ins.userId;
        debugPrint('Found user in UserData: $userId');
      }

      if (userId == null || userId.isEmpty) {
        debugPrint('No user logged in, skipping device token registration');
        return;
      }

      debugPrint('Attempting to register device token for user: $userId');

      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();

      if (token != null && token.isNotEmpty) {
        final repo = ref.read(notificationRepositoryProvider);
        await repo.registerDeviceToken(userId, token);
        AppLocal.ins.setUserData(Hivekey.deviceToken, token);
        _deviceTokenRegistered = true;

        debugPrint('✅ Device token registered successfully for user: $userId');
      } else {
        debugPrint('⚠️ No Firebase token available to register');
      }

      messaging.onTokenRefresh.listen((newToken) async {
        if (userId != null && newToken.isNotEmpty) {
          final repo = ref.read(notificationRepositoryProvider);
          await repo.registerDeviceToken(userId, newToken);
          debugPrint('🔄 Device token refreshed for user: $userId');

          AppLocal.ins.setUserData(Hivekey.deviceToken, newToken);
        }
      });

    } catch (e, stack) {
      debugPrint('❌ Error registering device token in SplashScreen: $e\n$stack');
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
    }
  }
}