import 'package:Artleap.ai/ads/ad_services/ad_provider.dart';
import 'package:Artleap.ai/domain/api_models/user_profile_model.dart';
import 'package:Artleap.ai/domain/tutorial/tutorial_provider.dart';
import 'package:Artleap.ai/presentation/views/common/privacy_policy_accept.dart';
import 'package:Artleap.ai/presentation/views/common/tutorial_screen.dart';
import 'package:Artleap.ai/presentation/views/home_section/bottom_nav_bar.dart';
import 'package:Artleap.ai/presentation/views/login_and_signup_section/login_section/login_screen.dart';
import 'package:Artleap.ai/providers/user_profile_provider.dart';
import 'package:Artleap.ai/shared/app_persistance/app_local.dart';
import 'package:Artleap.ai/shared/constants/app_assets.dart';
import 'package:Artleap.ai/shared/constants/user_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArtleapNavigationManager {
  static Future<void> navigateBasedOnUserStatus({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required String userName,
    required String userProfilePicture,
    required String userEmail,
    required bool hasSeenTutorial,
  }) async {
    final appOpenAdManager = ref.read(appOpenAdProvider);
    appOpenAdManager.disableForSession();

    await _navigateBasedOnUserStatusImpl(
      context: context,
      userId: userId,
      userName: userName,
      userProfilePicture: userProfilePicture,
      userEmail: userEmail,
      hasSeenTutorial: hasSeenTutorial,
      getUserProfile: () => ref.read(userProfileProvider.notifier).getUserProfileData(userId),
      getUserProfileData: () => ref.read(userProfileProvider).value!.userProfile,
    );

    Future.delayed(const Duration(seconds: 2), () {
      appOpenAdManager.enableForSession();
    });
  }

  static Future<void> navigateBasedOnUserStatusWithRef({
    required BuildContext context,
    required Ref ref,
    required String userId,
    required String userName,
    required String userProfilePicture,
    required String userEmail,
    required bool hasSeenTutorial,
  }) async {
    final appOpenAdManager = ref.read(appOpenAdProvider);
    appOpenAdManager.disableForSession();

    await _navigateBasedOnUserStatusImpl(
      context: context,
      userId: userId,
      userName: userName,
      userProfilePicture: userProfilePicture,
      userEmail: userEmail,
      hasSeenTutorial: hasSeenTutorial,
      getUserProfile: () => ref.read(userProfileProvider.notifier).getUserProfileData(userId),
      getUserProfileData: () => ref.read(userProfileProvider).value?.userProfile,
    );

    Future.delayed(const Duration(seconds: 2), () {
      appOpenAdManager.enableForSession();
    });
  }

  static Future<void> _navigateBasedOnUserStatusImpl({
    required BuildContext context,
    required String userId,
    required String userName,
    required String userProfilePicture,
    required String userEmail,
    required bool hasSeenTutorial,
    required Future<void> Function() getUserProfile,
    required UserProfileModel? Function() getUserProfileData,
  }) async {
    if (userId.isNotEmpty) {
      UserData.ins.setUserData(
        id: userId,
        name: userName,
        userprofilePicture: userProfilePicture,
        email: userEmail,
      );

      await getUserProfile();
      if (!context.mounted) return;

      final userProfile = getUserProfileData();

      if (userProfile != null && userProfile.user.id.isNotEmpty) {

        final needsPrivacyPolicy = _checkPrivacyPolicyStatus(userProfile);

        if (!hasSeenTutorial) {
          _navigateToTutorialScreen(context);
        } else if (needsPrivacyPolicy) {
          _navigateToPrivacyPolicyScreen(context);
        } else {

          _navigateToHomeScreen(context);
        }
      } else {
        _handleNoUserProfile(context, hasSeenTutorial);
      }
    } else {
      _handleNoUserId(context, hasSeenTutorial);
    }
  }

  static Future<bool> getTutorialStatus(WidgetRef ref) async {
    final tutorialStorage = ref.read(tutorialStorageServiceProvider);
    await tutorialStorage.init();
    return tutorialStorage.hasSeenTutorial();
  }

  static Future<bool> getTutorialStatusWithRef(Ref ref) async {
    final tutorialStorage = ref.read(tutorialStorageServiceProvider);
    await tutorialStorage.init();
    return tutorialStorage.hasSeenTutorial();
  }

  static bool _checkPrivacyPolicyStatus(UserProfileModel userProfile) {
    final privacyPolicy = userProfile.user.privacyPolicyAccepted;
    if (privacyPolicy == null) return true;
    return !privacyPolicy.accepted;
  }

  static void _navigateToTutorialScreen(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      TutorialScreen.routeName,
          (route) => false,
    );
  }

  static void _navigateToPrivacyPolicyScreen(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AcceptPrivacyPolicyScreen.routeName,
          (route) => false,
    );
  }

  static void _navigateToHomeScreen(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      BottomNavBar.routeName,
          (route) => false,
    );
  }

  static void _navigateToLoginScreen(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginScreen.routeName,
          (route) => false,
    );
  }

  static void _handleNoUserProfile(BuildContext context, bool hasSeenTutorial) {
    if (!hasSeenTutorial) {
      _navigateToTutorialScreen(context);
    } else {
      _navigateToLoginScreen(context);
    }
  }

  static void _handleNoUserId(BuildContext context, bool hasSeenTutorial) {
    if (!hasSeenTutorial) {
      _navigateToTutorialScreen(context);
    } else {
      _navigateToLoginScreen(context);
    }
  }

  static Map<String, dynamic> getUserDataFromStorage() {
    return {
      'userId': AppLocal.ins.getUSerData(Hivekey.userId) ?? "",
      'userName': AppLocal.ins.getUSerData(Hivekey.userName) ?? "",
      'userProfilePicture': AppLocal.ins.getUSerData(Hivekey.userProfielPic) ?? AppAssets.artstyle1,
      'userEmail': AppLocal.ins.getUSerData(Hivekey.userEmail) ?? "",
    };
  }
}