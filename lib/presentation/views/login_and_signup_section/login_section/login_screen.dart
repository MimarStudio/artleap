import 'package:Artleap.ai/shared/route_export.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const String routeName = "login_screen";
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authprovider).clearError();
      AnalyticsService.instance.logScreenView(screenName: 'login screen');
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authprovider);
    final isLoading = authState.isLoading(LoginMethod.email);
    final authError = authState.authError;
    final analyticsService = ref.read(analyticsServiceProvider);


    return RegistrationBackgroundWidget(
      widget: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          130.spaceY,
          const LoginScreenText(),
          20.spaceY,
          const Padding(
            padding: EdgeInsets.only(left: 36, right: 36),
            child: LoginScreenTextfieldsSection(),
          ),
          15.spaceY,
          const RememberMeForgotPassWidget(),
          20.spaceY,
          if (authError != null)
            CompactErrorState(
              message: authError.message ?? 'Authentication failed',
              onRetry: () {
                ref.read(authprovider).clearError();
                ref.read(authprovider).signInWithEmail();
              },
              icon: Icons.error_outline,
            ),
          if (isLoading)
            const LoadingState(
              message: 'Signing in...',
            )
          else
            CommonButton(
              title: "Log In",
              color: AppColors.indigo,
              onpress: () {
                ref.read(authprovider).signInWithEmail();

                AnalyticsService.instance.logButtonClick(buttonName: 'Login Button');

                analyticsService.logCustomEvent(
                  eventName: 'login_button_clicked',
                  parameters: {
                    'screen': 'login_screen',
                  },
                );
              },
            ),
          20.spaceY,
          const ORwidget(),
          20.spaceY,
          const SocialLoginsWidget(),
          20.spaceY,
          const NotHaveAccountText(),
        ],
      ),
    );
  }
}