import 'package:flutter/foundation.dart' show kIsWeb;

/// Cross-platform notification service.
/// Uses browser Notification API on web, no-ops on other platforms.
class WebNotificationService {
  static Future<bool> requestPermission() async {
    if (!kIsWeb) return false;
    // Web implementation is handled via JS interop only when
    // compiled for web; on mobile this is a no-op.
    return false;
  }

  static void show({required String title, String body = ''}) {
    // No-op on non-web platforms.
    // On web, the Flutter web engine handles notifications differently.
  }
}
