// Google Meet Service
//
// This service handles the creation of Google Meet links via the
// Google Calendar API. It requires the user to sign in with Google
// and grant calendar event creation permissions.

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;

/// Authenticated HTTP client that injects Google auth headers.
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

class GoogleMeetService {
  GoogleMeetService._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/calendar.events',
    ],
  );

  /// Cached sign-in account for re-use within the session.
  static GoogleSignInAccount? _currentUser;

  /// Creates a Google Calendar event with an auto-generated Meet link.
  ///
  /// Returns the Meet link URL, or null if creation failed.
  static Future<String?> createMeetLink({
    required String topic,
    required int durationMinutes,
    List<String> attendeeEmails = const [],
    DateTime? scheduledTime,
  }) async {
    try {
      // 1. Sign in with Google (or use cached account)
      _currentUser ??= await _googleSignIn.signIn();
      if (_currentUser == null) {
        // User cancelled sign-in
        return null;
      }

      // 2. Get authenticated HTTP client
      final authHeaders = await _currentUser!.authHeaders;
      final client = _GoogleAuthClient(authHeaders);

      // 3. Create the Calendar API instance
      final calendarApi = calendar.CalendarApi(client);

      // 4. Build the event with conference data
      final startTime =
          scheduledTime ?? DateTime.now().add(const Duration(minutes: 2));
      final endTime = startTime.add(Duration(minutes: durationMinutes));

      final event = calendar.Event(
        summary: 'Benkyo: $topic',
        description:
            'Study session created via Benkyo – the peer-to-peer study platform.',
        start: calendar.EventDateTime(
          dateTime: startTime,
          timeZone: 'Asia/Kolkata',
        ),
        end: calendar.EventDateTime(
          dateTime: endTime,
          timeZone: 'Asia/Kolkata',
        ),
        attendees: attendeeEmails
            .map((email) => calendar.EventAttendee(email: email))
            .toList(),
        conferenceData: calendar.ConferenceData(
          createRequest: calendar.CreateConferenceRequest(
            requestId: 'benkyo-${DateTime.now().millisecondsSinceEpoch}',
            conferenceSolutionKey:
                calendar.ConferenceSolutionKey(type: 'hangoutsMeet'),
          ),
        ),
      );

      // 5. Insert the event (conferenceDataVersion: 1 triggers Meet creation)
      final createdEvent = await calendarApi.events.insert(
        event,
        'primary',
        conferenceDataVersion: 1,
      );

      // 6. Extract the Meet video link from the response
      final meetLink = createdEvent.conferenceData?.entryPoints
          ?.firstWhere(
            (ep) => ep.entryPointType == 'video',
            orElse: () => calendar.EntryPoint(),
          )
          .uri;

      client.close();
      return meetLink;
    } catch (e) {
      // If auth is stale, sign out so the next attempt gets a fresh token
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        await _googleSignIn.signOut();
        _currentUser = null;
      }
      rethrow;
    }
  }

  /// Sign out and clear the cached user.
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  /// Check whether the user is already signed in with Google.
  static bool get isSignedIn => _currentUser != null;
}
