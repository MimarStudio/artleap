import 'dart:convert';

import 'package:Artleap.ai/shared/route_export.dart';

class HomeScreenTopBar extends ConsumerWidget {
  final VoidCallback? onMenuTap;
  const HomeScreenTopBar({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    final subscriptionAsync =
    ref.watch(currentSubscriptionProvider(UserData.ins.userId!));
    final profileAsync = ref.watch(userProfileProvider);

    UserSubscriptionModel? userSubscription;
    bool isFreePlan = true;
    String planName = 'Free';
    int totalCredits = 0;

    subscriptionAsync.when(
      data: (sub) {
        userSubscription = sub;
        isFreePlan =  sub?.planSnapshot?.type == 'free' && sub?.cancelledAt != null;
      },
      loading: () {
        isFreePlan = true;
      },
      error: (_, __) {
        isFreePlan = true;
      },
    );

    profileAsync.when(
      data: (state) {
        planName = state.userProfile?.user.planName ?? 'Free';
        totalCredits = state.userProfile?.user.totalCredits ?? 0;
      },
      loading: () {},
      error: (_, __) {},
    );

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: 16,
            left: screenWidth * 0.04,
            right: screenWidth * 0.03,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onMenuTap,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primaryContainer
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color:
                            theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 14,
                              height: 1.5,
                              color: theme.colorScheme.onPrimary,
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: 14,
                              height: 1.5,
                              color: theme.colorScheme.onPrimary,
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: 14,
                              height: 1.5,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.025),
                  InkWell(
                    onTap: () {
                      if (!isFreePlan) {
                        Navigator.of(context)
                            .pushNamed("/subscription-status");
                      } else {
                        Navigator.of(context)
                            .pushNamed("choose_plan_screen");
                      }
                    },
                    child: Container(
                      height: 36,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.orange,
                          width: 1.2,
                        ),
                        color: theme.colorScheme.surface,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            AppAssets.stackofcoins,
                            height: 16,
                            color: Colors.orange,
                          ),
                          SizedBox(width: screenWidth * 0.012),
                          Text(
                            '$totalCredits',
                            style: AppTextstyle.interMedium(
                              color: Colors.orange,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ), isFreePlan ? _buildProfessionalProButton(screenWidth, context, theme) : _buildPlanBadge(planName, screenWidth, theme),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }


  Widget _buildProfessionalProButton(
      double screenWidth, BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context)
                .pushNamed("choose_plan_screen");
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFD700),
                        Color(0xFFFFA500),
                        Color(0xFFFF8C00),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    FeatherIcons.award,
                    color: theme.colorScheme.onPrimary,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "PRO",
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.onPrimary.withOpacity(0.9),
                  size: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanBadge(
      String planName, double screenWidth, ThemeData theme) {
    Color textColor;
    Color borderColor;
    IconData icon;
    LinearGradient gradient;

    switch (planName.toLowerCase()) {
      case 'basic':
        gradient = LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerHighest
          ],
        );
        textColor = theme.colorScheme.primary;
        borderColor = theme.colorScheme.primary.withOpacity(0.5);
        icon = Icons.star_outline;
        break;

      case 'standard':
        gradient = LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerHighest
          ],
        );
        textColor = theme.colorScheme.primary;
        borderColor = theme.colorScheme.primary.withOpacity(0.5);
        icon = Icons.star_half;
        break;

      case 'premium':
        gradient = LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer
          ],
        );
        textColor = theme.colorScheme.onPrimary;
        borderColor = theme.colorScheme.primary;
        icon = Icons.star;
        break;

      default:
        gradient = LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerHighest
          ],
        );
        textColor = theme.colorScheme.primary;
        borderColor = theme.colorScheme.primary.withOpacity(0.5);
        icon = Icons.verified;
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 4),
          Text(
            planName.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
