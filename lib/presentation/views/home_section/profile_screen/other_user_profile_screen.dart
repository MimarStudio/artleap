import 'package:Artleap.ai/shared/route_export.dart';
import 'other_userprofile_widgets/profile_info_widget.dart';
import 'profile_screen_widgets/my_creations_widget.dart';

class OtherUserProfileScreen extends ConsumerStatefulWidget {
  static const String routeName = 'other_profile_screen';
  final OtherUserProfileParams? params;

  const OtherUserProfileScreen({super.key, this.params});

  @override
  ConsumerState<OtherUserProfileScreen> createState() =>
      _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState
    extends ConsumerState<OtherUserProfileScreen> {

  late final String userId;

  @override
  void initState() {
    super.initState();
    userId = widget.params!.userId!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(screenName: 'others profile screen');
      ref.read(userProfileProvider.notifier).getOtherUserProfileData(userId);
    });

    AnalyticsService.instance
        .logScreenView(screenName: 'others profile screen');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileState = ref.watch(userProfileProvider);
    final otherProfile = profileState.value?.otherUserProfile;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: profileState.when(
        data: (userProfileState) {
          final otherProfile = userProfileState.otherUserProfile;

          return Column(
            children: [
              _buildAppBar(theme),
              20.spaceY,
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      ProfileInfoWidget(
                        profileName: widget.params!.profileName,
                        userId: userId,
                      ),
                      24.spaceY,
                      otherProfile == null
                          ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            "Profile not found",
                            style: AppTextstyle.interMedium(
                              color: theme.colorScheme.onSurface,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                          : MyCreationsWidget(
                        userName: widget.params!.profileName,
                        listofCreations: otherProfile.user.images ?? [],
                        userId: userId,
                      ),
                      20.spaceY,
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Text(
            "Failed to load profile",
            style: AppTextstyle.interRegular(
              color: theme.colorScheme.error,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.colorScheme.primary,
                size: 18,
              ),
            ),
          ),
          12.spaceX,
          Text(
            "Artist Profile",
            style: AppTextstyle.interMedium(
              color: theme.colorScheme.onSurface,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
