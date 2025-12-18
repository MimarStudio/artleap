import 'package:Artleap.ai/domain/api_models/user_profile_model.dart';
import 'package:Artleap.ai/domain/api_services/api_response.dart';
import 'package:Artleap.ai/domain/base_repo/base_repo.dart';
import 'package:Artleap.ai/shared/route_export.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfileState {
  final bool isLoading;

  final UserProfileModel? userProfile;
  final UserProfileModel? otherUserProfile;

  final List<SubscriptionPlanModel>? subscriptionPlans;
  final UserSubscriptionModel? currentSubscription;

  final int remainingImageCredits;
  final int remainingPromptCredits;
  final int dailyCredits;

  final Map<String, UserProfileModel> profilesCache;

  const UserProfileState({
    this.isLoading = false,
    this.userProfile,
    this.otherUserProfile,
    this.subscriptionPlans,
    this.currentSubscription,
    this.remainingImageCredits = 0,
    this.remainingPromptCredits = 0,
    this.dailyCredits = 0,
    this.profilesCache = const {},
  });

  UserProfileState copyWith({
    bool? isLoading,
    UserProfileModel? userProfile,
    UserProfileModel? otherUserProfile,
    List<SubscriptionPlanModel>? subscriptionPlans,
    UserSubscriptionModel? currentSubscription,
    int? remainingImageCredits,
    int? remainingPromptCredits,
    int? dailyCredits,
    Map<String, UserProfileModel>? profilesCache,
  }) {
    return UserProfileState(
      isLoading: isLoading ?? this.isLoading,
      userProfile: userProfile ?? this.userProfile,
      otherUserProfile: otherUserProfile ?? this.otherUserProfile,
      subscriptionPlans: subscriptionPlans ?? this.subscriptionPlans,
      currentSubscription: currentSubscription ?? this.currentSubscription,
      remainingImageCredits: remainingImageCredits ?? this.remainingImageCredits,
      remainingPromptCredits: remainingPromptCredits ?? this.remainingPromptCredits,
      dailyCredits: dailyCredits ?? this.dailyCredits,
      profilesCache: profilesCache ?? this.profilesCache,
    );
  }
  bool get isFreeUser {
    final planName = userProfile?.user.planName;
    if (planName == null) return true;
    return planName.toLowerCase() == 'free';
  }
}

class UserProfileNotifier extends AsyncNotifier<UserProfileState>
    with BaseRepo {
  @override
  Future<UserProfileState> build() async {
    return const UserProfileState();
  }

  UserProfileState get _current =>
      state.valueOrNull ?? const UserProfileState();

  void _setLoading(bool value) {
    state = AsyncData(_current.copyWith(isLoading: value));
  }


  Future<void> followUnfollowUser(String uid, String followId) async {
    _setLoading(true);

    final data = {"userId": uid, "followId": followId};
    final response = await userFollowingRepo.followUnFollowUser(data);

    if (response.status == Status.completed) {
      await getUserProfileData(uid);
    } else {
      appSnackBar(
        "Error",
        response.message ?? "Failed to follow/unfollow user",
        backgroundColor: AppColors.redColor,
      );
      _setLoading(false);
    }
  }

  Future<void> getUserProfileData(String uid) async {
    final id = uid.trim();
    if (id.isEmpty) {
      appSnackBar(
        "Error",
        "User ID is empty",
        backgroundColor: AppColors.redColor,
      );
      return;
    }

    _setLoading(true);

    final response = await userFollowingRepo.getUserProfileData(id);

    if (response.status == Status.completed) {
      final profile = response.data;
      state = AsyncData(
        _current.copyWith(
          isLoading: false,
          userProfile: profile,
          dailyCredits: profile?.user.totalCredits ?? 0,
        ),
      );
    } else {
      appSnackBar(
        "Error",
        response.message ?? "Failed to fetch user profile",
        backgroundColor: AppColors.redColor,
      );
      debugPrint('❌ Profile failed for "$id": ${response.message}');
      _setLoading(false);
    }
  }

  Future<void> getProfilesForUserIds(List<String> ids) async {
    final cache = Map<String, UserProfileModel>.from(_current.profilesCache);

    for (final id in ids) {
      if (cache.containsKey(id)) continue;

      final response = await userFollowingRepo.getOtherUserProfileData(id);

      if (response.status == Status.completed && response.data != null) {
        cache[id] = response.data!;
      }
    }

    state = AsyncData(_current.copyWith(profilesCache: cache));
  }

  Future<void> getOtherUserProfileData(String uid) async {
    _setLoading(true);

    final response = await userFollowingRepo.getOtherUserProfileData(uid);

    if (response.status == Status.completed) {
      state = AsyncData(
        _current.copyWith(
          isLoading: false,
          otherUserProfile: response.data,
        ),
      );
    } else {
      appSnackBar(
        "Error",
        response.message ?? "Failed to fetch other user profile",
        backgroundColor: AppColors.redColor,
      );
      _setLoading(false);
    }
  }

  Future<void> updateUserCredits() async {
    _setLoading(true);

    final data = {"userId": UserData.ins.userId};
    final response = await userFollowingRepo.updateUserCredits(data);

    if (response.status == Status.completed) {
      await getUserProfileData(UserData.ins.userId ?? "");
    } else {
      debugPrint("Failed to update credits: ${response.message}");
      _setLoading(false);
    }
  }

  Future<void> deActivateAccount(String uid) async {
    _setLoading(true);

    final response = await userFollowingRepo.deleteAccount(uid);

    if (response.status == Status.completed) {
      // clear local data and navigate
      AppLocal.ins.clearUSerData(Hivekey.userId);
      Navigation.pushNamedAndRemoveUntil(LoginScreen.routeName);

      appSnackBar(
        "Success",
        "Your account has been deleted successfully",
        backgroundColor: AppColors.green,
      );

      // Don't modify state after navigation to avoid weird edge cases.
      return;
    } else {
      appSnackBar(
        "Error",
        response.message ?? "Something went wrong, please try again",
        backgroundColor: AppColors.redColor,
      );
      _setLoading(false);
    }
  }

  Future<void> launchAnyUrl(String? url) async {
    if (url == null) return;

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      appSnackBar(
        "Error",
        "Could not launch $url",
        backgroundColor: AppColors.redColor,
      );
    }
  }
}

final userProfileProvider =
AsyncNotifierProvider<UserProfileNotifier, UserProfileState>(
  UserProfileNotifier.new,
);
