import 'package:Artleap.ai/domain/api_models/user_profile_model.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class ProfileInfoWidget extends ConsumerWidget {
  final String? profileName;
  final String? userId;
  const ProfileInfoWidget({super.key, this.profileName, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userProfileAsync = ref.watch(userProfileProvider);

    // Handle loading/error states
    return userProfileAsync.when(
      data: (userProfileState) {
        final otherUserProfile = userProfileState.otherUserProfile;

        if (otherUserProfile == null) {
          return Center(
            child: Text(
              "Profile not found",
              style: AppTextstyle.interRegular(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
          );
        }

        final otherUser = otherUserProfile.user;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildProfileAvatar(otherUserProfile, theme),
                  16.spaceX,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileName ?? "User Name",
                          style: AppTextstyle.interMedium(
                            color: theme.colorScheme.onSurface,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                        6.spaceY,
                        Text(
                          "AI Artist",
                          style: AppTextstyle.interRegular(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              20.spaceY,
              _buildStatsRow(otherUser, theme),
              20.spaceY,
              _buildFollowButton(userProfileState, ref, theme),
            ],
          ),
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
    );
  }

  Widget _buildProfileAvatar(UserProfileModel userProfile, ThemeData theme) {
    final hasProfilePic = userProfile.user.profilePic.isNotEmpty;

    return Container(
      height: 70,
      width: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3), width: 2),
      ),
      child: ClipOval(
        child: hasProfilePic
            ? Image.network(
          userProfile.user.profilePic,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.person_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              size: 32,
            ),
          ),
        )
            : Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.person_rounded,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(dynamic otherUser, ThemeData theme) {
    final creations = otherUser?.images?.length ?? 0;
    final followers = otherUser?.followers?.length ?? 0;
    final following = otherUser?.following?.length ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Creations", creations.toString(), theme),
          Container(height: 30, width: 1, color: theme.colorScheme.outline.withOpacity(0.3)),
          _buildStatItem("Followers", followers.toString(), theme),
          Container(height: 30, width: 1, color: theme.colorScheme.outline.withOpacity(0.3)),
          _buildStatItem("Following", following.toString(), theme),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextstyle.interMedium(
            fontSize: 16,
            color: theme.colorScheme.onSurface,
          ),
        ),
        4.spaceY,
        Text(
          label,
          style: AppTextstyle.interRegular(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton(UserProfileState userProfileState, WidgetRef ref, ThemeData theme) {
    final isLoading = userProfileState.isLoading;
    final currentUserId = UserData.ins.userId;

    // Check if current user is following this user
    final isFollowing = userProfileState.userProfile?.user.following
        .any((user) => user.id == userId) ?? false;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: currentUserId == null ? null : () {
            ref.read(userProfileProvider.notifier).followUnfollowUser(currentUserId, userId!);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isFollowing ? theme.colorScheme.surface : theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFollowing ? theme.colorScheme.outline : theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            child: Center(
              child: isLoading
                  ? CircularProgressIndicator(
                color: isFollowing ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
                strokeWidth: 2,
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFollowing ? Icons.check_rounded : Icons.add_rounded,
                    color: isFollowing ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
                    size: 18,
                  ),
                  8.spaceX,
                  Text(
                    isFollowing ? "Following" : "Follow",
                    style: AppTextstyle.interMedium(
                      color: isFollowing ? theme.colorScheme.primary : theme.colorScheme.onPrimary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}