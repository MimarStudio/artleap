import '../../shared/route_export.dart';

class UpgradeToProBanner extends ConsumerWidget {
  const UpgradeToProBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          AnalyticsService.instance.logButtonClick(buttonName: 'Upgrade to Pro Button(Drawer)');
          final analyticsService = ref.read(analyticsServiceProvider);
          analyticsService.logCustomEvent(
              eventName: 'Upgrade_to_Pro_Button(Drawer)',
              parameters: {
                'screen': 'drawer',
              });
          Navigator.of(context).pushNamed("choose_plan_screen");
        },
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFCB87FF),
                Color(0xFF9814FF),
                Color(0xFF4822A7),
              ],
              stops: [
                0,
                0.4,
                1,
              ]
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Crown icon
                SizedBox(
                  height: 38,
                  width: 38,
                  child: Center(
                    child: Transform.scale(
                      scale: 1.3,
                      child: Image.asset(
                        AppAssets.upgrade,
                        height: 40,
                        width: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Text content
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Upgrade to Pro",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Unlock all premium features",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow indicator
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}