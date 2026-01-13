// ad_instance_manager.dart
import 'package:flutter/material.dart';

class AdInstanceManager {
  static final AdInstanceManager _instance = AdInstanceManager._internal();
  factory AdInstanceManager() => _instance;
  AdInstanceManager._internal();

  final Map<String, int> _instanceCounters = {};
  final Map<String, String> _adInstanceKeys = {};

  String getAdInstanceKey({
    required String screenKey,
    required String adType,
    int adIndex = 0,
    BuildContext? context,
  }) {
    final baseKey = '${screenKey}_${adType}_$adIndex';

    if (!_instanceCounters.containsKey(baseKey)) {
      _instanceCounters[baseKey] = 0;
    }

    _instanceCounters[baseKey] = _instanceCounters[baseKey]! + 1;
    final instanceKey = '${baseKey}_${_instanceCounters[baseKey]}';

    if (context != null) {
      final routeKey = ModalRoute.of(context)?.settings.name ?? '';
      if (routeKey.isNotEmpty) {
        _adInstanceKeys['${routeKey}_$instanceKey'] = instanceKey;
      }
    }

    return instanceKey;
  }

  void clearInstancesForScreen(String screenKey) {
    _instanceCounters.removeWhere((key, _) => key.startsWith(screenKey));
    _adInstanceKeys.removeWhere((key, _) => key.contains(screenKey));
  }

  void clearAllInstances() {
    _instanceCounters.clear();
    _adInstanceKeys.clear();
  }
}