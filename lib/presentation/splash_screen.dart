import 'dart:async';
import 'package:Artleap.ai/domain/notifications_repo/notification_repository.dart';
import 'package:Artleap.ai/shared/route_export.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SplashScreen extends ConsumerStatefulWidget {
  static const String routeName = "splash_screen";
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _initialized = false;
  bool _deviceTokenRegistered = false;
  bool _navigationTriggered = false;
  bool _splashTimeCompleted = false;
  bool _appInitialized = false;
  bool _adsReady = false;
  Timer? _splashTimer;
  Timer? _checkTimer;
  DateTime? _splashStartTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSplashFlow();
    });
  }

  void _startSplashFlow() {
    _splashStartTime = DateTime.now();
    _startSplashTimer();
    _initializeApp();
    _startNavigationCheck();
  }

  void _startSplashTimer() {
    _splashTimer = Timer(const Duration(seconds: 3), () {
      final elapsed = DateTime.now().difference(_splashStartTime!);
      _splashTimeCompleted = true;
      _checkIfReadyToNavigate();
    });
  }

  void _startNavigationCheck() {
    _checkTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _checkIfReadyToNavigate();
    });
  }

  Future<void> _initializeApp() async {
    if (_initialized) return;
    try {
      await Future.wait([
        _initTutorialStorage(),
        _initRemoteConfig(),
        _initSplashState(),
        _initializeAds(),
      ]);

      _appInitialized = true;
    } catch (e) {
      print('App initialization error: $e');
    } finally {
      _initialized = true;
    }
  }

  Future<void> _initTutorialStorage() async {
    final tutorialStorage = ref.read(tutorialStorageServiceProvider);
    await tutorialStorage.init();
  }

  Future<void> _initRemoteConfig() async {
    await ref.read(remoteConfigProvider).initialize();
    await ref.read(remoteConfigProvider).fetchAndActivate();
  }

  Future<void> _initSplashState() async {
    await ref.read(splashStateProvider.notifier).initializeApp();
  }

  Future<void> _initializeAds() async {
    final startTime = DateTime.now();
    const maxWaitTime = Duration(seconds: 10);

    int checkCount = 0;
    while (mounted) {
      checkCount++;
      final timeElapsed = DateTime.now().difference(startTime);
      if (timeElapsed > maxWaitTime) {
        break;
      }
      final adState = ref.read(centralAdManagementProvider);

      if (adState.isInitialized) {
        _adsReady = true;
        break;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _checkIfReadyToNavigate() {
    if (_navigationTriggered) return;
    final conditions = {
      'splashTimeCompleted': _splashTimeCompleted,
      'appInitialized': _appInitialized,
      'splashStateConnected': ref.watch(splashStateProvider) == SplashState.connected,
    };
    if (!conditions.values.every((condition) => condition)) return;
    _checkTimer?.cancel();
    _splashTimer?.cancel();
    _navigationTriggered = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  bool _adsCheckStarted = false;

  @override
  void dispose() {
    _splashTimer?.cancel();
    _checkTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(splashStateProvider);

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
                      _splashTimer?.cancel();
                      _checkTimer?.cancel();
                      _initialized = false;
                      _deviceTokenRegistered = false;
                      _navigationTriggered = false;
                      _splashTimeCompleted = false;
                      _appInitialized = false;
                      _adsReady = false;
                      _adsCheckStarted = false;

                      ref.read(splashStateProvider.notifier).retryInitialization();
                      _startSplashFlow();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
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
      if (!mounted) {
        return;
      }

      await _registerDeviceTokenIfNeeded();

      final adManager = ref.read(centralAdManagementProvider.notifier);
      final adShown = await adManager.showAppOpenAd();

      if (adShown) {
        await Future.delayed(const Duration(seconds: 2));
      }

      final hasSeenTutorial = await ArtleapNavigationManager.getTutorialStatus(ref);
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
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginScreen.routeName,
              (route) => false,
        );
      }
    }
  }

  Future<void> _registerDeviceTokenIfNeeded() async {
    try {
      if (_deviceTokenRegistered) {
        return;
      }

      String? userId;
      final userData = ArtleapNavigationManager.getUserDataFromStorage();
      userId = userData['userId'];

      if (userId == null || userId.isEmpty) {
        userId = AppLocal.ins.getUSerData(Hivekey.userId);
      }

      if ((userId == null || userId.isEmpty) &&
          UserData.ins.userId != null &&
          UserData.ins.userId!.isNotEmpty) {
        userId = UserData.ins.userId;
      }

      if (userId == null || userId.isEmpty) {
        return;
      }

      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();

      if (token != null && token.isNotEmpty) {
        final repo = ref.read(notificationRepositoryProvider);
        await repo.registerDeviceToken(userId, token);
        AppLocal.ins.setUserData(Hivekey.deviceToken, token);
        _deviceTokenRegistered = true;
      }

      messaging.onTokenRefresh.listen((newToken) async {
        if (newToken.isNotEmpty) {
          final repo = ref.read(notificationRepositoryProvider);
          await repo.registerDeviceToken(userId!, newToken);
          AppLocal.ins.setUserData(Hivekey.deviceToken, newToken);
        }
      });
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false);
    }
  }
}