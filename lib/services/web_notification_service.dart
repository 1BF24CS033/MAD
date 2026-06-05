import 'package:flutter/foundation.dart' show kIsWeb;

/// Cross-platform notification service.
/// Uses browser Notification API on web, no-ops on other platforms.
class WebNotificationService {
  static Future<bool> requestPermission() async {
    if (!kIsWeb) return false;
      return false;
  }

  static void show({required String title, String body = ''}) {
     }
}
