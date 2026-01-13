import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {

  AnalyticsService._privateConstructor();
  static final AnalyticsService _instance =
      AnalyticsService._privateConstructor();

  static AnalyticsService get instance => _instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  FirebaseAnalytics get analytics => _analytics;

  Future<void> logScreenView({required String screenName}) async {
    await _analytics.logEvent(
      name: 'screen_view',
      parameters: {'screen_name': screenName},
    );
  }

  Future<void> logButtonClick({required String buttonName}) async {
    await _analytics.logEvent(
      name: 'button_clicks',
      parameters: {'button_name': buttonName},
    );
  }
}
