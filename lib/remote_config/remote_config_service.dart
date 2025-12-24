import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  late FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;
  bool _isFreeUser = true;

  /// 🔥 CALLED when profile loads
  // void updateUserPlan({required bool isFreeUser}) {
  //   _isFreeUser = isFreeUser;
  //   debugPrint('🔐 RemoteConfig: User isFreeUser=$_isFreeUser');
  // }
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(minutes: 5),
        ),
      );

      final defaults = {
        // General parameters
        'force_update_required': false,
        'update_message': 'A new version is available. Please update to continue using the app.',

        // Android app version (set to current version)
        'android_latest_version': '1.0.0',
        'android_min_supported_version': '1.0.0',
        'android_update_url': 'https://play.google.com/store/apps/details?id=your.package.name',

        // iOS app version (set to current version)
        'ios_latest_version': '1.0.0',
        'ios_min_supported_version': '1.0.0',
        'ios_update_url': 'https://apps.apple.com/app/idYOUR_APP_ID',

        // General ad settings
        'ads_enabled': true,
        'max_ad_retry_count': 3,
        'interstitial_interval_seconds': 120,

        // Android Ad Units
        'android_banner_ad_unit': 'ca-app-pub-9762893813732933/8062172478',
        'android_interstitial_ad_unit': 'ca-app-pub-9762893813732933/1706315987',
        'android_rewarded_ad_unit': 'ca-app-pub-9762893813732933/8800431270',
        'android_native_ad_unit': 'ca-app-pub-9762893813732933/6386855079',
        'android_app_open_ad_unit': 'ca-app-pub-3940256099942544/3419835294',

        // Android Ad Toggles
        'android_show_banner_ads': true,
        'android_show_interstitial_ads': true,
        'android_show_rewarded_ads': true,
        'android_show_native_ads': true,
        'android_show_app_open_ads': true,

        // iOS Ad Units
        'ios_banner_ad_unit': 'ca-app-pub-9762893813732933/7884426110',
        'ios_interstitial_ad_unit': 'ca-app-pub-3940256099942544/4411468910',
        'ios_rewarded_ad_unit': 'ca-app-pub-3940256099942544/1712485313',
        'ios_native_ad_unit': 'ca-app-pub-3940256099942544/3986624511',
        'ios_app_open_ad_unit': '/21775744923/example/app-open',

        // iOS Ad Toggles
        'ios_show_banner_ads': true,
        'ios_show_interstitial_ads': true,
        'ios_show_rewarded_ads': true,
        'ios_show_native_ads': true,
        'ios_show_app_open_ads': true,
      };

      await _remoteConfig.setDefaults(defaults);
      await _remoteConfig.fetchAndActivate();
      _initialized = true;

      _logCurrentConfig();
    } catch (e) {
      print('RemoteConfig init error: $e');
    }
  }

  void _logCurrentConfig() {
    print('=== Remote Config Status ===');
    print('Initialized: $_initialized');
    print('Platform: ${defaultTargetPlatform == TargetPlatform.iOS ? 'iOS' : 'Android'}');
    print('Ads Enabled: ${_remoteConfig.getBool('ads_enabled')}');
    print('Force Update Required: ${_remoteConfig.getBool('force_update_required')}');
    print('Latest Version: $latestVersion');
    print('Min Supported Version: $minSupportedVersion');
    print('============================');
  }

  Future<bool> fetchAndActivate() async {
    if (!_initialized) await initialize();
    try {
      print('RemoteConfig: Fetching and activating...');
      final updated = await _remoteConfig.fetchAndActivate();
      if (updated) {
        print('RemoteConfig: Fetch and activate successful - new data applied');
        _logCurrentConfig();
      } else {
        print('RemoteConfig: No new data fetched or already activated');
      }
      return updated;
    } catch (e) {
      print('RemoteConfig fetch error: $e');
      return false;
    }
  }

  bool get adsEnabled => _remoteConfig.getBool('ads_enabled');
  int get interstitialInterval => _remoteConfig.getInt('interstitial_interval_seconds');
  int get maxAdRetryCount => _remoteConfig.getInt('max_ad_retry_count');

  bool get showBannerAds => adsEnabled && (defaultTargetPlatform == TargetPlatform.iOS
      ? _remoteConfig.getBool('ios_show_banner_ads')
      : _remoteConfig.getBool('android_show_banner_ads'));

  bool get showInterstitialAds => adsEnabled && (defaultTargetPlatform == TargetPlatform.iOS
      ? _remoteConfig.getBool('ios_show_interstitial_ads')
      : _remoteConfig.getBool('android_show_interstitial_ads'));

  bool get showRewardedAds => adsEnabled && (defaultTargetPlatform == TargetPlatform.iOS
      ? _remoteConfig.getBool('ios_show_rewarded_ads')
      : _remoteConfig.getBool('android_show_rewarded_ads'));

  bool get showNativeAds => adsEnabled && (defaultTargetPlatform == TargetPlatform.iOS
      ? _remoteConfig.getBool('ios_show_native_ads')
      : _remoteConfig.getBool('android_show_native_ads'));

  bool get showAppOpenAds => adsEnabled && (defaultTargetPlatform == TargetPlatform.iOS
      ? _remoteConfig.getBool('ios_show_app_open_ads')
      : _remoteConfig.getBool('android_show_app_open_ads'));

  String get bannerAdUnit => defaultTargetPlatform == TargetPlatform.iOS
      ? _remoteConfig.getString('ios_banner_ad_unit')
      : _remoteConfig.getString('android_banner_ad_unit');

  String get interstitialAdUnit => defaultTargetPlatform == TargetPlatform.iOS
      ? _remoteConfig.getString('ios_interstitial_ad_unit')
      : _remoteConfig.getString('android_interstitial_ad_unit');

  String get rewardedAdUnit => defaultTargetPlatform == TargetPlatform.iOS
      ? _remoteConfig.getString('ios_rewarded_ad_unit')
      : _remoteConfig.getString('android_rewarded_ad_unit');

  String get nativeAdUnit => defaultTargetPlatform == TargetPlatform.iOS
      ? _remoteConfig.getString('ios_native_ad_unit')
      : _remoteConfig.getString('android_native_ad_unit');

  String get appOpenAdUnit => defaultTargetPlatform == TargetPlatform.iOS
      ? _remoteConfig.getString('ios_app_open_ad_unit')
      : _remoteConfig.getString('android_app_open_ad_unit');

  bool get forceUpdateRequired => _remoteConfig.getBool('force_update_required');
  String get updateMessage => _remoteConfig.getString('update_message');

  String get latestVersion => defaultTargetPlatform == TargetPlatform.iOS
      ? _remoteConfig.getString('ios_latest_version')
      : _remoteConfig.getString('android_latest_version');

  String get minSupportedVersion => defaultTargetPlatform == TargetPlatform.iOS
      ? _remoteConfig.getString('ios_min_supported_version')
      : _remoteConfig.getString('android_min_supported_version');

  String get updateUrl => defaultTargetPlatform == TargetPlatform.iOS
      ? _remoteConfig.getString('ios_update_url')
      : _remoteConfig.getString('android_update_url');

  bool isUpdateRequired(String currentVersion) {
    final minVersion = minSupportedVersion;
    final latestVersion = this.latestVersion;

    print('Update Check: Current=$currentVersion, Min=$minVersion, Latest=$latestVersion');

    int parseVersion(String version) {
      final parts = version.split('.');
      int value = 0;
      for (int i = 0; i < parts.length; i++) {
        final part = int.tryParse(parts[i]) ?? 0;
        value = value * 1000 + part;
      }
      return value;
    }

    final current = parseVersion(currentVersion);
    final min = parseVersion(minVersion);

    if (current < min) {
      print('Force update required: Current version ($currentVersion) is below minimum ($minVersion)');
      return true;
    }

    return forceUpdateRequired;
  }

  Map<String, bool> get platformAdToggles => {
    'android_banner': _remoteConfig.getBool('android_show_banner_ads'),
    'android_interstitial': _remoteConfig.getBool('android_show_interstitial_ads'),
    'android_rewarded': _remoteConfig.getBool('android_show_rewarded_ads'),
    'android_native': _remoteConfig.getBool('android_show_native_ads'),
    'android_app_open': _remoteConfig.getBool('android_show_app_open_ads'),
    'ios_banner': _remoteConfig.getBool('ios_show_banner_ads'),
    'ios_interstitial': _remoteConfig.getBool('ios_show_interstitial_ads'),
    'ios_rewarded': _remoteConfig.getBool('ios_show_rewarded_ads'),
    'ios_native': _remoteConfig.getBool('ios_show_native_ads'),
    'ios_app_open': _remoteConfig.getBool('ios_show_app_open_ads'),
  };

  Map<String, String> get platformAdUnits => {
    'android_banner': _remoteConfig.getString('android_banner_ad_unit'),
    'android_interstitial': _remoteConfig.getString('android_interstitial_ad_unit'),
    'android_rewarded': _remoteConfig.getString('android_rewarded_ad_unit'),
    'android_native': _remoteConfig.getString('android_native_ad_unit'),
    'android_app_open': _remoteConfig.getString('android_app_open_ad_unit'),
    'ios_banner': _remoteConfig.getString('ios_banner_ad_unit'),
    'ios_interstitial': _remoteConfig.getString('ios_interstitial_ad_unit'),
    'ios_rewarded': _remoteConfig.getString('ios_rewarded_ad_unit'),
    'ios_native': _remoteConfig.getString('ios_native_ad_unit'),
    'ios_app_open': _remoteConfig.getString('ios_app_open_ad_unit'),
  };
}