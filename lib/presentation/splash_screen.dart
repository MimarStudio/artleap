import 'package:Artleap.ai/shared/route_export.dart';

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
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginScreen.routeName,
              (Route<dynamic> route) => false,
        );
      }
    }
  }
}