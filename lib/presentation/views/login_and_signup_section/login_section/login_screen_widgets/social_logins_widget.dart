import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io';
import 'package:Artleap.ai/shared/route_export.dart';

class SocialLoginsWidget extends ConsumerWidget {
  const SocialLoginsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final analyticsService = ref.read(analyticsServiceProvider);
    return Container(
      width: 285,
      child: Row(
        mainAxisAlignment: Platform.isIOS
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.center,
        children: [
          ref.watch(authprovider).isLoading(LoginMethod.google)
              ? Container(
                  width: 100,
                  child: Center(
                    child: CircularProgressIndicator(
                      backgroundColor: AppColors.indigo,
                    ),
                  ),
                )
              : InkWell(
                  onTap: () {
                    ref.read(authprovider).signInWithGoogle();
                    AnalyticsService.instance.logButtonClick(buttonName: 'google Login Button');

                    analyticsService.logCustomEvent(
                      eventName: 'google_button_clicked',
                      parameters: {
                        'screen': 'login_screen',
                      },
                    );
                  },
                  child: Container(
                    height: 45,
                    width: 139,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      AppAssets.googlelogin,
                      scale: 2.1,
                    ),
                  ),
                ),
          if (Platform.isIOS)
            Container(
              height: 45,
              width: 139,
              child: SignInWithAppleButton(
                style: SignInWithAppleButtonStyle.white,
                text: "",
                onPressed: () async {
                  AnalyticsService.instance.logButtonClick(buttonName: 'Apple Login Button');
                  ref.read(authprovider).signInWithApple();

                  analyticsService.logCustomEvent(
                    eventName: 'apple_button_clicked',
                    parameters: {
                      'screen': 'login_screen',
                    },
                  );
                },
              ),
            )
        ],
      ),
    );
  }
}
