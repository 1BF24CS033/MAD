// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Wraps the browser Notification API for Flutter Web.
/// Falls back silently on non-web platforms.
class WebNotificationService {
  /// Request notification permission from the browser.
  /// Returns true if granted.
  static Future<bool> requestPermission() async {
    try {
      final result = await js.context.callMethod(
        'eval',
        ['Notification.requestPermission()'],
      );
      // result is a JS Promise — we use a simpler sync check below
      return _isGranted();
    } catch (_) {
      return false;
    }
  }

  /// Check if permission is already granted.
  static bool _isGranted() {
    try {
      final permission =
          js.context['Notification']['permission'] as String?;
      return permission == 'granted';
    } catch (_) {
      return false;
    }
  }

  /// Show a browser notification immediately.
  static void show({required String title, String body = ''}) {
    try {
      if (!_isGranted()) return;
      js.context.callMethod('eval', [
        '''
        new Notification(${_jsString(title)}, {
          body: ${_jsString(body)},
          icon: '/icons/Icon-192.png'
        });
        '''
      ]);
    } catch (_) {
      // Silently ignore — notification not critical
    }
  }

  static String _jsString(String s) {
    // Escape single quotes for safe JS string injection
    final escaped = s.replaceAll("'", "\\'");
    return "'$escaped'";
  }
}
