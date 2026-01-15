import 'package:Artleap.ai/shared/route_export.dart';

class NativeAdPostWidget extends ConsumerWidget {
  final int adIndex;
  final bool isMediumAd;
  final VoidCallback onAdDisposed;

  const NativeAdPostWidget({
    super.key,
    required this.adIndex,
    required this.isMediumAd,
    required this.onAdDisposed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adState = ref.watch(nativeAdProvider);
    final theme = Theme.of(context);

    if (!adState.showAds) {
      return const SizedBox.shrink();
    }

    final List<NativeAd> targetAds = isMediumAd ? adState.mediumNativeAds : adState.smallNativeAds;
    final bool isLoading = isMediumAd ? adState.isLoadingMedium : adState.isLoadingSmall;
    final bool isLoaded = isMediumAd ? adState.isMediumLoaded : adState.isSmallLoaded;

    if (isLoading && targetAds.isEmpty) {
      return _buildAdPlaceholder(context, theme);
    }

    if (adIndex >= targetAds.length || targetAds.isEmpty) {
      return const SizedBox.shrink();
    }

    final isAdReady = isMediumAd
        ? ref.read(nativeAdProvider.notifier).isMediumAdReady(adIndex)
        : ref.read(nativeAdProvider.notifier).isSmallAdReady(adIndex);

    if (!isAdReady) {
      return _buildAdPlaceholder(context, theme);
    }

    final nativeAd = targetAds[adIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(isMediumAd ? 16 : 8),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isMediumAd ? 16 : 8),
                topRight: Radius.circular(isMediumAd ? 16 : 8),
              ),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
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
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    if (isMediumAd) {
                      onAdDisposed();
                    } else {
                      ref.read(nativeAdProvider.notifier).disposeSmallAds();
                    }
                    onAdDisposed();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Container(
            height: isMediumAd ? 400 : 200, // Adjust height based on ad type
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: AdWidget(ad: nativeAd),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Advertisement',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  'Ad • ${DateTime.now().year}',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
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
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(isMediumAd ? 16 : 8), // Adjust based on ad type
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      height: isMediumAd ? 400 : 200, // Adjust height based on ad type
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.ads_click,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading advertisement...',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
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