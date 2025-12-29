import 'dart:async';
import 'package:Artleap.ai/domain/api_services/api_response.dart';
import 'package:Artleap.ai/ads/rewarded_ads/rewarded_ad_repo_provider.dart';
import 'package:Artleap.ai/shared/route_export.dart';

enum AdLoadStatus { idle, loading, loaded, failed }

class RewardedAdState {
  final AdLoadStatus status;
  final int retryCount;
  final bool canShowAd;
  final String? errorMessage;

  const RewardedAdState({
    this.status = AdLoadStatus.idle,
    this.retryCount = 0,
    this.canShowAd = false,
    this.errorMessage,
  });

  RewardedAdState copyWith({
    AdLoadStatus? status,
    int? retryCount,
    bool? canShowAd,
    String? errorMessage,
  }) {
    return RewardedAdState(
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      canShowAd: canShowAd ?? this.canShowAd,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final rewardedAdNotifierProvider =
StateNotifierProvider<RewardedAdNotifier, RewardedAdState>(
      (ref) => RewardedAdNotifier(ref),
);


class RewardedAdNotifier extends StateNotifier<RewardedAdState> {
  final Ref ref;
  RewardedAdManager? _manager;
  bool _isDisposed = false;
  Timer? _retryTimer;
  bool _isProcessingReward = false;

  RewardedAdNotifier(this.ref) : super(const RewardedAdState()) {
    _init();

    ref.listen<AppLifecycleState>(
      appLifecycleStateProvider,
          (previous, current) {
        if (!_isDisposed) {
          _handleLifecycleChange(current);
        }
      },
    );
  }

  void _handleLifecycleChange(AppLifecycleState state) {
    if (_isProcessingReward &&
        (state == AppLifecycleState.hidden ||
            state == AppLifecycleState.inactive)) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isDisposed && this.state.status != AdLoadStatus.loaded) {
          loadAd();
        }
      });
    }
  }

  void _checkIfDisposed() {
    if (_isDisposed) {
      throw StateError('RewardedAdNotifier has been disposed');
    }
  }

  Future<void> _init() async {
    if (_isDisposed) return;
    _manager = RewardedAdManager();

    final appLifecycleState = ref.read(appLifecycleStateProvider);
    if (appLifecycleState == AppLifecycleState.resumed) {
      await _safeLoadAd();
    }
  }

  Future<void> _safeLoadAd() async {
    if (_isDisposed) return;
    await loadAd();
  }

  Future<void> loadAd() async {
    if (_isDisposed) return;

    if (state.status == AdLoadStatus.loading) {
      return;
    }

    _checkIfDisposed();
    state = state.copyWith(
      status: AdLoadStatus.loading,
      canShowAd: false,
    );

    try {
      final remoteConfig = ref.read(remoteConfigProvider);
      final enabled = ref.read(rewardedAdsEnabledProvider);

      final loaded = await _manager!.loadRewardedAd(
        rewardedAdsEnabled: enabled,
        adUnitId: remoteConfig.rewardedAdUnit,
        maxRetryCount: remoteConfig.maxAdRetryCount,
        initializeAds: AdService.instance.initialize,
        isAdsInitialized: AdService.instance.isInitialized,
      );

      if (_isDisposed) return;

      if (loaded) {
        _checkIfDisposed();
        state = state.copyWith(
          status: AdLoadStatus.loaded,
          canShowAd: true,
          retryCount: 0,
          errorMessage: null,
        );
      } else {
        _handleLoadFailure('Failed to load ad');
      }
    } catch (e) {
      if (_isDisposed) return;
      _handleLoadFailure(e.toString());
    }
  }

  void _handleLoadFailure(String error) {
    if (_isDisposed) return;

    _retryTimer?.cancel();

    _checkIfDisposed();
    state = state.copyWith(
      status: AdLoadStatus.failed,
      canShowAd: false,
      retryCount: state.retryCount + 1,
      errorMessage: error,
    );

    final remoteConfig = ref.read(remoteConfigProvider);
    if (state.retryCount < remoteConfig.maxAdRetryCount) {
      final retryDelay = Duration(seconds: 5 + (state.retryCount * 2));
      _retryTimer = Timer(retryDelay, () {
        if (!_isDisposed) {
          loadAd();
        }
      });
    }
  }

  Future<bool> showAd({
    required void Function(int coins) onRewardEarned,
    void Function()? onAdDismissed,
    void Function()? onAdFailedToShow,
    bool isSimpleAd = false,
  }) async {
    if (_isDisposed) {
      return false;
    }

    if (!state.canShowAd || _manager == null) {
      await loadAd();
      if (!state.canShowAd) {
        return false;
      }
    }

    _checkIfDisposed();
    state = state.copyWith(
      status: AdLoadStatus.loading,
      canShowAd: false,
    );

    final success = await _manager!.showRewardedAd(
      onUserEarnedReward: (coins) async {
        _isProcessingReward = true;
        onRewardEarned(coins);

        try {
          final repo = ref.read(rewardedAdRepoProvider);
          final userId = UserData.ins.userId;

          if (userId == null) {
            _isProcessingReward = false;
            return;
          }

          if(isSimpleAd){
            _refreshUserProfile();
            _isProcessingReward = false;
            return;
          }

          final response = await repo.sendRewardToBackend({
            'userId': userId,
            'timestamp': DateTime.now().toIso8601String(),
            'adCoins': coins,
          }).timeout(const Duration(seconds: 10), onTimeout: () {
            return ApiResponse.error('Request timeout');
          });

          if (response.status == Status.completed) {
            _refreshUserProfile();
          }
        } catch (e) {
        } finally {
          _isProcessingReward = false;
        }
      },
      onAdDismissed: () {
        if (_isDisposed || _isProcessingReward) {
          return;
        }

        _checkIfDisposed();
        state = state.copyWith(
          status: AdLoadStatus.idle,
          canShowAd: false,
        );

        onAdDismissed?.call();

        Future.delayed(const Duration(seconds: 2), () {
          if (!_isDisposed && !_isProcessingReward) {
            loadAd();
          }
        });
      },
      onAdFailedToShow: (error) {
        if (_isDisposed) return;

        _checkIfDisposed();
        state = state.copyWith(
          status: AdLoadStatus.failed,
          canShowAd: false,
          errorMessage: error,
        );
        onAdFailedToShow?.call();

        Future.delayed(const Duration(seconds: 3), () {
          if (!_isDisposed) {
            loadAd();
          }
        });
      },
    );

    return success;
  }

  void _refreshUserProfile() {
    final userId = UserData.ins.userId;
    if (userId != null && !_isDisposed) {
      Future.microtask(() {
        ref.read(userProfileProvider.notifier).getUserProfileData(userId);
      });
    }
  }

  Future<void> forceReload() async {
    if (_isDisposed) return;

    _retryTimer?.cancel();
    _manager?.dispose();
    _manager = RewardedAdManager();
    await loadAd();
  }

  @override
  void dispose() {
    if (_manager?.isAdShowing == true) {
      return;
    }

    _isDisposed = true;
    _retryTimer?.cancel();
    _manager?.dispose();
    super.dispose();
  }
}

final appLifecycleStateProvider = StateProvider<AppLifecycleState>(
      (ref) => AppLifecycleState.resumed,
);