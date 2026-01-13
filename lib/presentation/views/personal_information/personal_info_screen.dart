import 'sections/profile_header.dart';
import 'sections/stats_card.dart';
import 'sections/subscription_card.dart';
import 'package:Artleap.ai/shared/route_export.dart';

class PersonalInformationScreen extends ConsumerStatefulWidget {
  static const String routeName = "personal_info_screen";

  const PersonalInformationScreen({super.key});

  @override
  ConsumerState<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends ConsumerState<PersonalInformationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(screenName: 'Personal Information Screen');
      ref.read(userProfileProvider.notifier).getUserProfileData(UserData.ins.userId ?? "");
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileProvider = ref.watch(userProfileProvider);
    final user = profileProvider.value!.userProfile!.user;
    final isLoading = profileProvider.isLoading;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                foregroundColor: Colors.white,
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                    background: ProfileHeader(
                      profilePic: user.profilePic,
                      username: user.username,
                      email: user.email,
                    )),
                actions: [
                  // IconButton(
                  //   icon: const Icon(Icons.edit, color: Colors.white),
                  //   onPressed: null,
                  //   tooltip: "Edit Profile",
                  // ),
                ],
              ),
            ];
          },
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (isLoading) _buildLoadingState(theme),
                if (!isLoading) ...[
                  StatsCard(
                    followers: user.followers.length,
                    following: user.following.length,
                    images: user.images.length,
                  ),
                  const SizedBox(height: 20),
                  SubscriptionCard(
                    status: user.subscriptionStatus,
                    planName: user.planName,
                    planType: user.planName,
                    currentSubscription: user.planName,
                    isSubscribed: user.isSubscribed,
                  ),
                  const SizedBox(height: 20),

                  // if (subscriptionAsync != null)
                  //   subscriptionAsync.when(
                  //     loading: () => const CircularProgressIndicator(),
                  //     error: (error, stack) => Text("Error loading subscription: $error"),
                  //     data: (subscription) {
                  //       return CreditsCard(
                  //         dailyCredits: user.dailyCredits,
                  //         totalCredits: subscription?.planSnapshot!.totalCredits ?? 0,
                  //         usedImageCredits: user.usedImageCredits,
                  //         imageGenerationCredits: subscription?.planSnapshot?.imageGenerationCredits ?? 0,
                  //         usedPromptCredits: user.usedPromptCredits,
                  //         promptGenerationCredits: subscription?.planSnapshot?.promptGenerationCredits ?? 0,
                  //         planName: subscription?.planSnapshot?.name ?? user.planName,
                  //         remainingCredits: (subscription?.planSnapshot!.totalCredits ?? 0) - user.totalCredits,
                  //       );
                  //     },
                  //   ),
                  //
                  // const SizedBox(height: 20),
                  // const AccountActionsCard(),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Column(
      children: List.generate(
        4,
            (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}