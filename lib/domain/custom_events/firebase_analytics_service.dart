import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

class FirebaseAnalyticsService {
  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsService(this._analytics);

  Future<void> logCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
      print('✅ Custom Event Logged: $eventName');
      if (parameters != null) {
        print('📊 Parameters: $parameters');
      }
    } catch (e) {
      print('❌ Error logging event: $e');
    }
  }
}

final analyticsServiceProvider = Provider<FirebaseAnalyticsService>((ref) {
  final analytics = ref.watch(firebaseAnalyticsProvider);
  return FirebaseAnalyticsService(analytics);
});