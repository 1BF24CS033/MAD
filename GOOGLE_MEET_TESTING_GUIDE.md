# Google Meet Integration — Testing & Troubleshooting Guide

## 1. Prerequisites: Google Cloud Console Setup

Before the code can work, your Google Cloud project needs to be configured correctly.

### Checklist (at https://console.cloud.google.com/):

| Step | What to verify |
|------|---------------|
| **Calendar API** | Go to *APIs & Services → Enabled APIs* → confirm **Google Calendar API** is enabled |
| **OAuth Consent Screen** | *APIs & Services → OAuth consent screen* → must be configured (External, with test users added) |
| **Scopes** | The consent screen must include scope: `https://www.googleapis.com/auth/calendar.events` |
| **Test Users** | Your Google account email must be listed as a test user (while the app is in "Testing" status) |
| **Client ID** | Your OAuth Client ID in `web/index.html` line 37 must match the one from your Cloud Console |

### Platform-specific setup:

**If testing on Web (recommended):**
- Create an **OAuth 2.0 Client ID** of type **Web application**
- Add `http://localhost` as an authorized JavaScript origin
- The client ID in `web/index.html` should match

**If testing on Windows desktop:**
- Create a **Desktop application** type OAuth Client ID
- `google_sign_in` on Windows has limited support — **Web is the easiest platform to test on**

---

## 2. Running the Test

```powershell
# Run on Chrome (recommended for testing)
flutter run -d chrome
```

### Using the Test Button (Quick Smoke Test):
1. Log in to Benkyo
2. On the home dashboard, scroll down and tap **🧪 Test Google Meet Integration**
3. Tap **"Create Test Meet Link"**
4. A Google Sign-In popup should appear → sign in and grant calendar permissions
5. If successful, you'll see:
   - ✅ Status: "Success! Meet link generated."
   - The Meet link displayed in a green-bordered card
   - Buttons to **Copy** or **Join Meet**
6. Check your Google Calendar — an event named "Benkyo: Test Session — Benkyo" should appear with a Meet link

### Full End-to-End Test:
1. **Log in** to Benkyo as a learner
2. Go to **My Help Requests → New Request**
3. Select a topic, describe your doubt, and **toggle "Schedule Google Meet" ON**
4. Post the request
5. **Switch accounts** (or use a second browser) — log in as a mentor
6. Go to **Help Requests** (browse screen)
7. You should see the request with a 🎥 **Meet** badge
8. Tap **Accept & Help**
9. **Google Sign-In popup** should appear → sign in and grant calendar permissions
10. If successful, you'll see: **"Accepted! Meet link created ✓"** with a "Copy Link" button

### What to verify:
- ✅ Google Sign-In popup appears when accepting a Meet request
- ✅ A Calendar event named "Benkyo: [topic]" appears in the mentor's Google Calendar
- ✅ The snackbar shows the Meet confirmation message
- ✅ The learner sees the Meet link in **My Help Requests** → tap to open in browser

---

## 3. Troubleshooting Common Issues

| Problem | Possible Fix |
|---------|-------------|
| Sign-in popup doesn't appear | Check Client ID in `web/index.html` matches your Cloud Console |
| `403 access_denied` | Your email isn't listed as a test user in the OAuth consent screen |
| `403 insufficientPermissions` | The `calendar.events` scope wasn't approved — re-check consent screen scopes |
| Sign-in succeeds but Meet link is `null` | The Calendar API might not be enabled, or the event didn't get conference data |
| `popup_closed_by_user` | The user closed the Google sign-in window — try again |
| `PlatformException(sign_in_failed)` | OAuth client ID mismatch or not configured for your platform |
| `ClientException` / network errors | Check internet connection; Google APIs require HTTPS |

---

## 4. Implementation Architecture

### Flow when a mentor accepts a help request with `wantsMeet: true`:

```
Mentor taps "Accept & Help"
       │
       ▼
HelpRequestProvider.acceptRequest()
       │
       ├── HelpRequestService.acceptRequest()  →  updates DB status to 'accepted'
       │
       ├── (if wantsMeet == true)
       │       │
       │       ▼
       │   GoogleMeetService.createMeetLink()
       │       │
       │       ├── Google Sign-In (OAuth popup)
       │       ├── Calendar API: create event with conferenceData
       │       └── Extract Meet link from response
       │
       └── HelpRequestService.saveMeetLink()  →  stores link in DB
```

### Files involved:
| File | Role |
|------|------|
| `lib/services/google_meet_service.dart` | Core service — Google Sign-In + Calendar API |
| `lib/providers/help_request_provider.dart` | Orchestrates accept flow + auto Meet creation |
| `lib/screens/sessions/browse_requests_screen.dart` | Mentor UI — accept button + Meet snackbar |
| `lib/screens/sessions/my_requests_screen.dart` | Learner UI — view/open Meet link |
| `lib/screens/sessions/post_help_request_screen.dart` | Learner UI — "Schedule Google Meet" toggle |
| `lib/screens/sessions/meet_test_screen.dart` | **TEMPORARY** — standalone test screen |
| `lib/screens/home/home_screen.dart` | **TEMPORARY** — test button added to dashboard |

---

## 5. Cleanup After Testing

Once you've verified everything works, remove the temporary test code:

1. **Delete** `lib/screens/sessions/meet_test_screen.dart`
2. **In `lib/screens/home/home_screen.dart`:**
   - Remove the import: `import '../sessions/meet_test_screen.dart';`
   - Remove the block between `// ── TEMPORARY: Google Meet Test Button` and `// ── END TEMPORARY`
