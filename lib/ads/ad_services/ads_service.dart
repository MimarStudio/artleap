import 'dart:io';

import 'package:Artleap.ai/shared/route_export.dart';

class AdService {
  static final AdService instance = AdService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  AdService._internal();

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await RemoteConfigService.instance.initialize();

      await MobileAds.instance.initialize();

      if (Platform.isIOS) {
        await Future.delayed(const Duration(seconds: 2));
      }

      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: ['b05362e554dfd858c25d109f946944ba'],
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
        ),
      );

      _initialized = true;
    } catch (e) {
      print('AdMob initialization error: $e');
    }
  }

  Future<void> dispose() async {
    _initialized = false;
  }
}
