# Android Emulator Setup for Testing

## Prerequisites
✅ Debug SHA-1 already configured in `android/app/google-services.json`

## Steps to Test Google Sign-In

### 1. Start Android Emulator
- Open Android Studio
- Go to Device Manager
- Start your virtual device (Pixel, etc.)

### 2. Run Flutter App
```bash
cd speech_world
flutter run
```

### 3. Test Google Sign-In
- Tap "Sign in with Google" button
- Select Google account in the popup
- Wait for authentication to complete

### 4. Verify in Firestore Console
Go to: https://console.firebase.google.com/project/speech-world-003/firestore/data

Check for new document in `users` collection:
```json
{
  "uid": "user_uid_here",
  "email": "user@example.com",
  "credits": 50,
  "subscription": {
    "planId": "free",
    "status": "active"
  },
  "createdAt": "timestamp"
}
```

## Troubleshooting

### If Google Sign-In fails with "Developer Error":
You may need to add the emulator's SHA-1 fingerprint to Firebase.

**Get SHA-1 from emulator:**
```bash
cd speech_world/android
./gradlew signingReport
```

Look for `SHA1` under `debug` configuration.

**Add to Firebase Console:**
1. Go to: https://console.firebase.google.com/project/speech-world-003/settings/general
2. Scroll to "Your apps" → Android app
3. Click "Add fingerprint"
4. Paste the SHA-1 from signingReport
5. Download new `google-services.json`
6. Replace in `android/app/`

## Expected User Data
After successful login, user document should have:
- `credits: 50` (starter credits)
- `subscription.planId: "free"`
- `subscription.status: "active"`

## Next Steps After Testing
Once Google Sign-In works and creates user with 50 credits:
1. ✅ Authentication complete
2. Deploy backend to Cloud Run
3. Implement Translation API (Speech-to-Text, Translation, TTS)
4. Build translation UI screens
