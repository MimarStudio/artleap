import 'package:Artleap.ai/shared/route_export.dart';

class NativeAdPostWidget extends ConsumerWidget {
  final int adIndex;
  final VoidCallback onAdDisposed;

  const NativeAdPostWidget({
    super.key,
    required this.adIndex,
    required this.onAdDisposed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adState = ref.watch(nativeAdProvider);
    final theme = Theme.of(context);

    if (!adState.showAds) {
      return const SizedBox.shrink();
    }

    if (adState.isLoading && adState.nativeAds.isEmpty) {
      return _buildAdPlaceholder(context, theme);
    }

    if (adIndex >= adState.nativeAds.length || adState.nativeAds.isEmpty) {
      return const SizedBox.shrink();
    }

    final isAdReady = ref.read(nativeAdProvider.notifier).isAdReady(adIndex);
    if (!isAdReady) {
      return _buildAdPlaceholder(context, theme);
    }

    final nativeAd = adState.nativeAds[adIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.ads_click,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Sponsored',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  onPressed: () {
                    ref.read(nativeAdProvider.notifier).safeDisposeAds();
                    onAdDisposed();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Container(
            height: 400,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: AdWidget(ad: nativeAd),
          ),

          // Optional footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 10,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  'Advertisement',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const Spacer(),
                Text(
                  'Ad • ${DateTime.now().year}',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdPlaceholder(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.ads_click,
                size: 20,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading advertisement...',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: theme.colorScheme.surface,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}