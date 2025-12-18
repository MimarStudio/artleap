import 'package:Artleap.ai/shared/route_export.dart';

class AdAppWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AdAppWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AdAppWrapper> createState() => _AdAppWrapperState();
}

class _AdAppWrapperState extends ConsumerState<AdAppWrapper> with WidgetsBindingObserver {
  late AppOpenAdManager _appOpenAdManager;
  bool _initialized = false;
  DateTime? _appStartTime;
  bool _isFirstLaunch = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appStartTime = DateTime.now();
    _appOpenAdManager = ref.read(appOpenAdProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAds();
    });
  }

  Future<void> _initializeAds() async {
    if (_initialized) return;

    try {

      await ref.read(remoteConfigProvider).initialize();
      await ref.read(remoteConfigProvider).fetchAndActivate();

      await ref.read(adServiceProvider).initialize();

      await _appOpenAdManager.loadAppOpenAd(ref);

      _initialized = true;
    } catch (e) {
      print('AdAppWrapper: Error initializing ads: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      final appAge = now.difference(_appStartTime!).inSeconds;

      if (_isFirstLaunch) {
        _isFirstLaunch = false;
        return;
      }

      if (appAge > 30) {
        _showAppOpenAd();
      } else {
        print('AdAppWrapper: Skipping app open ad - app just started ($appAge seconds)');
      }
    }
  }

  Future<void> _showAppOpenAd() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      final adShown = await _appOpenAdManager.showAppOpenAd(ref);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appOpenAdManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}