import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalStorage {
  static const String _feedbackDraftKey = 'feedback_draft';

  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  static Future<String> getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    final current = info.version;
    return current;
  }

  static Future<Map<String, dynamic>?> getFeedbackDraft() async {
    try {
      final prefs = await _prefs;
      final draftJson = prefs.getString(_feedbackDraftKey);
      if (draftJson != null) {
        return json.decode(draftJson) as Map<String, dynamic>;
      }
    } catch (e) {
    }
    return null;
  }

  static Future<void> saveFeedbackDraft(Map<String, dynamic> draft) async {
    try {
      final prefs = await _prefs;
      final draftJson = json.encode(draft);
      await prefs.setString(_feedbackDraftKey, draftJson);
    } catch (e) {
    }
  }

  static Future<void> clearFeedbackDraft() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_feedbackDraftKey);
    } catch (e) {
    }
  }
}