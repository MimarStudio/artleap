import 'dart:io';
import 'plan_card.dart';
import 'package:Artleap.ai/shared/route_export.dart';

final selectedPlanProvider = StateProvider<SubscriptionPlanModel?>((ref) => null);

class PlanListContent extends ConsumerStatefulWidget {
  final List<SubscriptionPlanModel> plans;
  const PlanListContent({
    super.key,
    required this.plans,
  });

  @override
  ConsumerState<PlanListContent> createState() => _PlanListContentState();
}

class _PlanListContentState extends ConsumerState<PlanListContent> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (widget.plans.isNotEmpty) {
        ref.read(selectedPlanProvider.notifier).state = widget.plans.first;
      }
      ref.read(userProfileProvider.notifier).getUserProfileData(UserData.ins.userId ?? "");
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final selectedPlan = ref.watch(selectedPlanProvider);

    SubscriptionPlanModel? weekly;
    SubscriptionPlanModel? monthly;
    SubscriptionPlanModel? yearly;

    for (var p in widget.plans) {
      final lower = p.type.toLowerCase();
      if (weekly == null && lower.contains('basic')) weekly = p;
      if (monthly == null && lower.contains('standard')) monthly = p;
      if (yearly == null && lower.contains('premium')) yearly = p;
    }

    weekly ??= widget.plans.isNotEmpty ? widget.plans[0] : null;
    monthly ??= widget.plans.length > 1 ? widget.plans[1] : null;
    yearly ??= widget.plans.length > 2 ? widget.plans[2] : null;

    final plansToShow = [weekly, monthly, yearly].whereType<SubscriptionPlanModel>().toList();

    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < plansToShow.length; i++) ...[
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () {
                        ref.read(selectedPlanProvider.notifier).state = plansToShow[i];
                        AnalyticsService.instance.logButtonClick(buttonName: 'Plan Card Click ${plansToShow[i].name}');
                        final analyticsService = ref.read(analyticsServiceProvider);
                        analyticsService.logCustomEvent(
                            eventName: 'Plan_Card_Click_${plansToShow[i].name}_(Choose Plan Screen)',
                            parameters: {
                              'screen': 'choose_plan_screen',
                            });
                      },
                      child: PlanCard(
                        plan: plansToShow[i],
                        isCompact: true,
                        selected: selectedPlan?.id == plansToShow[i].id,
                        highlighted: plansToShow[i].type.toLowerCase().contains('standard'),
                      ),
                    ),
                    if (plansToShow[i].type.toLowerCase().contains('standard'))
                      Positioned(
                        top: -10,
                        right: -5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Popular",
                                style: AppTextstyle.interBold(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (i < plansToShow.length - 1)
                SizedBox(width: screenSize.width * 0.035),
            ]
          ],
        ),
        SizedBox(height: screenSize.height * 0.025),
        _subscribeButton(context),
        SizedBox(height: screenSize.height * 0.02),
        Text(
          "\$${(selectedPlan?.price ?? monthly?.price ?? 0).toStringAsFixed(2)} billed annually. Cancel anytime.",
          style: AppTextstyle.interMedium(
            fontSize: 12,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: screenSize.height * 0.03),
      ],
    );
  }

  Widget _subscribeButton(BuildContext context) {
    final selectedPlan = ref.watch(selectedPlanProvider);
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          if (selectedPlan == null) return;
          final route = Platform.isIOS ? ApplePaymentScreen.routeName : GooglePaymentScreen.routeName;
          Navigator.pushNamed(context, route, arguments: selectedPlan);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFAF8B47),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 6,
          shadowColor: Colors.black45,
        ),
        child: Text(
          "SUBSCRIBE NOW",
          style: AppTextstyle.interBold(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}