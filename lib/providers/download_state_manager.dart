import 'package:Artleap.ai/shared/route_export.dart';

final downloadStateProvider = StateNotifierProvider<DownloadStateNotifier, DownloadState>((ref) {
  return DownloadStateNotifier(ref);
});

final adShowProvider = StateProvider<bool>((ref) => false);

class DownloadState {
  final bool isDownloading;
  final int downloadCount;
  final bool isProcessingAd;
  final bool isWaitingForAd;

  DownloadState({
    this.isDownloading = false,
    this.downloadCount = 0,
    this.isProcessingAd = false,
    this.isWaitingForAd = false,
  });

  DownloadState copyWith({
    bool? isDownloading,
    int? downloadCount,
    bool? isProcessingAd,
    bool? isWaitingForAd,
  }) {
    return DownloadState(
      isDownloading: isDownloading ?? this.isDownloading,
      downloadCount: downloadCount ?? this.downloadCount,
      isProcessingAd: isProcessingAd ?? this.isProcessingAd,
      isWaitingForAd: isWaitingForAd ?? this.isWaitingForAd,
    );
  }
}

// Notifier class for download state management
class DownloadStateNotifier extends StateNotifier<DownloadState> {
  final Ref _ref;
  ProviderSubscription<InterstitialAdState>? _interstitialListener;

  DownloadStateNotifier(this._ref) : super(DownloadState()) {
    _setupAdListener();
  }

  void _setupAdListener() {
    _interstitialListener = _ref.listen<InterstitialAdState>(
      interstitialAdStateProvider,
          (previous, next) {
        if (previous?.isShowing == true && next.isShowing == false && state.isWaitingForAd) {
          state = state.copyWith(isWaitingForAd: false);
          _ref.read(adShowProvider.notifier).state = false;
        }
      },
    );
  }
  void startDownload() {
    state = state.copyWith(isDownloading: true);
  }
  void finishDownload() {
    state = state.copyWith(isDownloading: false);
  }
  void incrementDownloadCount() {
    state = state.copyWith(downloadCount: state.downloadCount + 1);
  }
  void resetDownloadCount() {
    state = state.copyWith(downloadCount: 0);
  }
  void startAdProcessing() {
    state = state.copyWith(isProcessingAd: true, isWaitingForAd: true);
  }
  void finishAdProcessing() {
    state = state.copyWith(isProcessingAd: false);
  }
  bool shouldShowAd() {
    return state.downloadCount > 0 && state.downloadCount % 2 == 0;
  }

  int getDownloadCount() {
    return state.downloadCount;
  }

  int getRemainingDownloadsForNextAd() {
    return 2 - (state.downloadCount % 2);
  }

  @override
  void dispose() {
    _interstitialListener?.close();
    super.dispose();
  }
}

class DownloadAdHelper {
  static Future<bool> showInterstitialAdIfNeeded(WidgetRef ref) async {
    final downloadNotifier = ref.read(downloadStateProvider.notifier);
    if (downloadNotifier.shouldShowAd()) {
      print('[DOWNLOAD DEBUG] 🚀 3rd download reached - showing interstitial ad');

      final interstitialState = ref.read(interstitialAdStateProvider);

      if (interstitialState.isLoaded) {
        downloadNotifier.startAdProcessing();
        ref.read(adShowProvider.notifier).state = true;

        try {
          final didShow = await ref.read(interstitialAdStateProvider.notifier).showInterstitialAd();

          if (didShow) {
            await _waitForAdToClose(ref);

            downloadNotifier.finishAdProcessing();
            ref.read(adShowProvider.notifier).state = false;
            return true;
          } else {
            print('[DOWNLOAD DEBUG] ⚠️ Failed to show interstitial ad');
            downloadNotifier.finishAdProcessing();
            ref.read(adShowProvider.notifier).state = false;
          }
        } catch (e) {
          print('[DOWNLOAD DEBUG] ❌ Error showing interstitial ad: $e');
          downloadNotifier.finishAdProcessing();
          ref.read(adShowProvider.notifier).state = false;
        }

        // Load new ad for next time
        ref.read(interstitialAdStateProvider.notifier).loadInterstitialAd();
      } else {
        print('[DOWNLOAD DEBUG] ⚠️ Interstitial ad not loaded, loading now...');
        ref.read(interstitialAdStateProvider.notifier).loadInterstitialAd();
      }
    } else {
      final remaining = downloadNotifier.getRemainingDownloadsForNextAd();
      print('[DOWNLOAD DEBUG] ⏳ Not showing ad yet (${remaining} more downloads until next ad)');
    }

    return false;
  }

  // Wait for ad to close with timeout
  static Future<void> _waitForAdToClose(WidgetRef ref) async {
    const maxWaitTime = Duration(seconds: 30);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxWaitTime) {
      final currentAdState = ref.read(interstitialAdStateProvider);
      final adShowState = ref.read(adShowProvider);

      if (!currentAdState.isShowing && adShowState) {
        print('[DOWNLOAD DEBUG] ✅ Ad closed, continuing download');
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }

    print('[DOWNLOAD DEBUG] ⚠️ Ad close wait timeout, continuing anyway');
  }

  // Handle download process with ad logic
  static Future<void> handleDownload({
    required WidgetRef ref,
    required String imageUrl,
    Uint8List? uint8ListObject,
    required VoidCallback onDownloadComplete,
  }) async {
    final downloadNotifier = ref.read(downloadStateProvider.notifier);
    final favNotifier = ref.read(favProvider.notifier);

    downloadNotifier.startDownload();

    try {
      // Check if we should show ad
      await showInterstitialAdIfNeeded(ref);

      // Perform the actual download
      if (uint8ListObject != null) {
        await favNotifier.downloadImage(imageUrl, uint8ListObject: uint8ListObject);
      } else {
        await favNotifier.downloadImage(imageUrl);
      }

      // Increment download count after successful download
      downloadNotifier.incrementDownloadCount();

      onDownloadComplete();

    } catch (e) {
      print('[DOWNLOAD DEBUG] ❌ Download failed: $e');
      rethrow;
    } finally {
      downloadNotifier.finishDownload();
    }
  }
}