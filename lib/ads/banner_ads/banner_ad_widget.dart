import 'package:Artleap.ai/shared/route_export.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bannerAdStateProvider.notifier).initializeBannerAd();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bannerAdStateProvider);
    final notifier = ref.read(bannerAdStateProvider.notifier);
    final bannerAd = notifier.bannerAd;

    if (bannerAd == null || !state.adLoaded) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        width: bannerAd.size.width.toDouble(),
        height: bannerAd.size.height.toDouble(),
        child: AdWidget(
          key: ValueKey(bannerAd),
          ad: bannerAd,
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
