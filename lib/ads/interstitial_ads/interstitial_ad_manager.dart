import 'package:Artleap.ai/ads/interstitial_ads/interstitial_ad_provider.dart';
import 'package:Artleap.ai/shared/route_export.dart';
import 'package:flutter/services.dart';

class InterstitialAdManager extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onAdShown;
  final VoidCallback? onAdDismissed;
  final bool autoLoadOnInit;

  const InterstitialAdManager({
    super.key,
    required this.child,
    this.onAdShown,
    this.onAdDismissed,
    this.autoLoadOnInit = true,
  });

  @override
  ConsumerState<InterstitialAdManager> createState() => _InterstitialAdManagerState();
}

class _InterstitialAdManagerState extends ConsumerState<InterstitialAdManager> {
  @override
  void initState() {
    super.initState();
    if (widget.autoLoadOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(interstitialAdStateProvider.notifier).loadInterstitialAd();
      });
    }
  }

  Future<bool> showInterstitialAd() async {
    final result = await ref.read(interstitialAdStateProvider.notifier).showInterstitialAd();
    if (result && widget.onAdShown != null) {
      widget.onAdShown!();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(interstitialAdStateProvider, (previous, next) {
      if (previous?.isShowing == true && next.isShowing == false && widget.onAdDismissed != null) {
        widget.onAdDismissed!();
      }
    });

    return widget.child;
  }

  @override
  void dispose() {
    super.dispose();
  }
}