import 'dart:async';
import 'package:Artleap.ai/ads/ad_services/ad_wrappers.dart';
import 'package:Artleap.ai/shared/theme/app_theme.dart';
import 'package:Artleap.ai/shared/route_export.dart';
import 'remote_config/force_update/force_update_wrapper.dart';

void main() {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await AppInitialization.initialize();

    runApp(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWith((ref) => NotificationService(ref)),
        ],
        child: AppKeyboardListener(child: const AdAppWrapper(child: MyApp()),),
      ),
    );
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  Timer? _refreshTokenTimer;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  late PurchaseHandler _purchaseHandler;

  @override
  void initState() {
    super.initState();
    _purchaseHandler = PurchaseHandler(ref);

    final Stream<List<PurchaseDetails>> purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _purchaseHandler.handlePurchaseUpdates(purchaseDetailsList);
    }, onError: (error) {
      appSnackBar('Error', 'Failed to process purchase stream',backgroundColor: Colors.red);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeProvider.notifier).loadTheme();
    });
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }

    Future.microtask(() async {
      final token = await AppInitialization.initializeAuthAndNotifications(ref);

      if (token == null) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          SplashScreen.routeName,
              (Route<dynamic> route) => false,
        );
        return;
      }

      _refreshTokenTimer = Timer.periodic(const Duration(hours: 1), (_) async {
        final refreshedToken = await ref.read(authprovider).ensureValidFirebaseToken();
        if (refreshedToken == null) {
          debugPrint('Token refresh skipped: No user signed in.');
        }
      });
    });
  }

  @override
  void dispose() {
    _refreshTokenTimer?.cancel();
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(systemThemeMonitorProvider);
    final effectiveThemeMode = ref.watch(effectiveThemeModeProvider);

    final mainApp = MaterialApp(
      title: 'Artleap.ai',
      debugShowCheckedModeBanner: false,
      supportedLocales: AppLocalization.supportedLocales,
      locale: ref.watch(localizationProvider),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: effectiveThemeMode,
      localizationsDelegates: const [
        AppLocalization.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorKey: navigatorKey,
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: SplashScreen.routeName,
      builder: (context, child) {
        return ConnectivityOverlay(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    return ForceUpdateWrapper(child: mainApp);
  }
}