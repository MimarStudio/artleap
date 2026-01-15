import 'package:Artleap.ai/shared/route_export.dart';

class CollapsibleBannerAdWidget extends ConsumerStatefulWidget {
  final String uniqueScreenKey;
  const CollapsibleBannerAdWidget({
    super.key,
    required this.uniqueScreenKey,
  });

  @override
  ConsumerState<CollapsibleBannerAdWidget> createState() =>
      _CollapsibleBannerAdWidgetState();
}

class _CollapsibleBannerAdWidgetState
    extends ConsumerState<CollapsibleBannerAdWidget> {
  bool _hasRequestedLoad = false;
  DateTime? _lastLoadAttempt;
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 3;
  static const Duration _loadCooldown = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
  }

  bool _canRequestLoad() {
    final now = DateTime.now();

    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      return false;
    }

    if (_lastLoadAttempt != null) {
      final timeSinceLastAttempt = now.difference(_lastLoadAttempt!);
      if (timeSinceLastAttempt < _loadCooldown) {
        return false;
      }
    }

    return true;
  }

  void _handleLoadSuccess() {
    _consecutiveFailures = 0;
  }

  void _handleLoadFailure() {
    _consecutiveFailures++;

    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      Future.delayed(Duration(minutes: 5), () {
        if (mounted) {
          _consecutiveFailures = 0;
          _hasRequestedLoad = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannerState = ref.watch(bannerAdStateProvider);
    final centralAdState = ref.watch(centralAdManagementProvider);

    final isCollapsibleBannerActive =
        centralAdState.adLoadStatus['collapsibleBanner'] == true;

    final isBannerLoaded = bannerState.isLoaded &&
        bannerState.bannerAd != null &&
        bannerState.adLoaded &&
        bannerState.isCollapsible;

    final now = DateTime.now();
    if (!isBannerLoaded && !_hasRequestedLoad) {
      if (_canRequestLoad()) {
        _hasRequestedLoad = true;
        _lastLoadAttempt = now;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(centralAdManagementProvider.notifier)
              .loadCollapsibleBannerAd();
        });
      }
    }

    if (isBannerLoaded && _hasRequestedLoad && _consecutiveFailures > 0) {
      _handleLoadSuccess();
    }

    final isStateMismatch = !isBannerLoaded &&
        isCollapsibleBannerActive &&
        _hasRequestedLoad &&
        _lastLoadAttempt != null &&
        now.difference(_lastLoadAttempt!).inSeconds > 3;

    if (isStateMismatch) {
      _handleLoadFailure();
    }

    if (!isBannerLoaded || !isCollapsibleBannerActive) {
      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        return SizedBox(
          height: 50,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.orange, size: 20),
                SizedBox(height: 4),
                Text(
                  'Ad temporarily unavailable',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (bannerState.isLoading) {
        return SizedBox(
          height: 50,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Loading ad...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return const SizedBox.shrink();
    }

    return SizedBox(
      width: bannerState.adSize.width.toDouble(),
      height: bannerState.adSize.height.toDouble(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdWidget(ad: bannerState.bannerAd!),
          SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  _hasRequestedLoad = false;
                  _consecutiveFailures = 0;
                  ref.read(centralAdManagementProvider.notifier)
                      .forceReloadBanner(isCollapsible: true);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 12, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}