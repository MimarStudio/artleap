
import 'package:Artleap.ai/shared/route_export.dart';

class RouteGenerator {
  static Route generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SplashScreen.routeName:
        return route(const SplashScreen());
      case InterestOnboardingScreen.routeName:
        return route(const InterestOnboardingScreen());
      case InterestOnboardingScreenWrapper.routeName:
        return route(const InterestOnboardingScreenWrapper());
      case TutorialScreen.routeName:
        return route(const TutorialScreen());
      case AcceptPrivacyPolicyScreen.routeName:
        return route(const AcceptPrivacyPolicyScreen());
      case ChoosePlanScreen.routeName:
        return route(const ChoosePlanScreen());
      case PersonalInformationScreen.routeName:
        return route(const PersonalInformationScreen());
      case AboutArtleapScreen.routeName:
        return route(const AboutArtleapScreen());
      case LoginScreen.routeName:
        return route(const LoginScreen());
      case SignUpScreen.routeName:
        return route(const SignUpScreen());
      case CurrentPlanScreen.routeName:
        return route(const CurrentPlanScreen());
      case FavouritesScreen.routeName:
        return route(const FavouritesScreen());
      case MyPostsScreen.routeName:
        return route(const MyPostsScreen());
      case SavedImagesScreen.routeName:
        return route(const SavedImagesScreen());
      case GooglePaymentScreen.routeName:
        final args = settings.arguments as SubscriptionPlanModel;
        return MaterialPageRoute(
          builder: (_) => GooglePaymentScreen(plan: args),
          settings: settings,
        );

      case ApplePaymentScreen.routeName:
        final args = settings.arguments as SubscriptionPlanModel;
        return MaterialPageRoute(builder: (_) => ApplePaymentScreen(plan: args));

      case BottomNavBar.routeName:
        return route(const BottomNavBar());
      case ResultScreenRedesign.routeName:
        return route(const ResultScreenRedesign());
      case SeePictureScreen.routeName:
        return route(SeePictureScreen(params: settings.arguments as SeePictureParams?));
      case OtherUserProfileScreen.routeName:
        return route(OtherUserProfileScreen(
          params: settings.arguments as OtherUserProfileParams?,
        ));
      case ForgotPasswordScreen.routeName:
        return route(const ForgotPasswordScreen());
      case FullImageViewerScreen.routeName:
        return route(
          FullImageViewerScreen(
            params: settings.arguments as FullImageScreenParams,
          ),
        );
      case PrivacyPolicyScreen.routeName:
        return route(const PrivacyPolicyScreen());
      case HelpScreen.routeName:
        return route(const HelpScreen());
      case NotificationScreen.routeName:
        return route(const NotificationScreen());
      case NotificationDetailScreen.routeName:
        final args = settings.arguments as AppNotification;
        return route(NotificationDetailScreen(notification: args));
      default:
        return route(const ErrorRoute());
    }
  }

  static Route route(Widget screen) => MaterialPageRoute(builder: (context) => screen);
}

class ErrorRoute extends StatelessWidget {
  const ErrorRoute({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('You should not be here...')));
}