# AdMob / UMP — Sakinah Android

## Configuration

- Package / namespace / activity: `com.roqaiaapps.sakinah`.
- Visible Android label remains `Sakinah`.
- App ID: `ca-app-pub-1088724215879441~9272828660` (always real, including test builds).
- Default banner: Google's test ID `ca-app-pub-3940256099942544/6300978111`.
- Only `--dart-define=ADMOB_USE_PRODUCTION=true` selects the real banner
  `ca-app-pub-1088724215879441/1634011792`. Release mode alone never does.
- `google_mobile_ads` 9.1.0 supports the installed Flutter 3.38.1 / Dart 3.10.0.
  The resolved Android SDK is Google Mobile Ads 25.4.0 with UMP 4.0.0.
- `AD_ID` is supplied by the SDK and merged once under `<manifest>`, before
  `<application>`. Do not add another declaration to the app manifest.
- Every banner uses the official `AdRequest(nonPersonalizedAds: true)` API.
  No keywords, app location, date of birth, age inference, or consent-sync ID
  is supplied. `RequestConfiguration` is applied before initialization with
  `MaxAdContentRating.g` and `AgeRestrictedTreatment.unspecified` (the 9.1 API
  replacing deprecated age flags; the app is not child-directed).
- Ads/UMP are registered only on Android. No Android ad IDs are used on iOS,
  desktop or web. iOS app/test bundle identifiers were also renamed to remove
  the old identifier throughout the source tree; no iOS ads integration is enabled.

## Behavior and tests

`AdsController` starts UMP after the first frame, requests fresh consent
information each launch, shows a form if required, and gates initialization and
loads with UMP's `canRequestAds()`. Errors do not block app usage; previous consent
is used only if UMP still permits requests. Opening privacy options removes ads
and checks consent again before loading a replacement. The localized privacy
button appears under the existing home language/theme settings only when UMP
requires it; errors offer a non-blocking message and the button can be retried.

There is one anchored adaptive banner, in the home Scaffold's bottom slot (not
an overlay), with a non-clickable buffer, an ad label and safe-area padding.
Loading/failure reserves no space. Navigation away, backgrounding, disposal,
width/orientation changes and active/loading/paused Quran recitation discard
the ad. No ad widgets are added to Quran or Qibla pages. Late callbacks cannot
restore invalidated banners. There are no manual refresh timers.

`AdsGateway` and `BannerHandle` are replaced by in-memory fakes in tests: tests
never initialize Google Mobile Ads, render a native ad, or contact ad services.
Coverage includes consent gates, errors, prior consent, withdrawal, duplicate
requests, late callbacks, disposal, navigation, audio, lifecycle and Arabic/dark
and English/light layouts.

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define=ADMOB_USE_PRODUCTION=false
flutter run -d <android-device-id> --dart-define=ADMOB_USE_PRODUCTION=false
```

## Before an internal-testing AAB

1. In AdMob, verify that this Android app and banner belong to the supplied IDs
   and package. Configure and publish applicable Privacy & messaging / UMP
   messages, with the correct privacy policy URL and supported languages.
2. Review Play Console's "Contains ads", Advertising ID, target audience (13+),
   Data safety and privacy policy disclosures. Non-personalized ads do **not**
   mean no data collection: the SDK may collect identifiers, IP address,
   interactions and diagnostics. The current Console disclosures were not
   available in this repository and must be checked by the owner.
3. Connect an Android device or configure an emulator. Exercise initial consent,
   decline/accept, expired/prior consent, offline/form failure, privacy choices,
   rotation, navigation, backgrounding and recitation using test ads only.
   Use Google's documented UMP debug-device / debug-geography procedure on a
   test device to test regulated regions; remove such temporary debug overrides
   before distributing. Do not click live ads or turn on the production flag.
4. Release now uses the local upload signing configuration, never Debug.
   `android/key.properties` supplies credentials and a path relative to the
   Android directory. Both that file and `android/.signing/` are Git-ignored.
   Missing signing files cause Release to fail explicitly; Debug still works.
   Keep an encrypted off-machine backup of the upload keystore and credentials,
   and configure Play App Signing as appropriate. See the local signing details below.
5. Current `versionName` is `1.0.0`, `versionCode` is `1`, both sourced from
   `pubspec.yaml` (`1.0.0+1`). Choose an unused higher build number if 1 is
   already uploaded; do not guess the Play Console's last uploaded version.
6. After signing is ready, build the internal AAB with test ads:

   ```powershell
   flutter build appbundle --release --dart-define=ADMOB_USE_PRODUCTION=false
   ```

   Add `--build-number=<unused-number>` if required.

## Local upload signing

- Keystore: `android/.signing/upload-keystore.p12` (PKCS12, RSA 3072-bit,
  SHA256withRSA, alias `upload`, validity 10,000 days).
- Credentials: `android/key.properties`; passwords are not in Gradle or Git.
- Public upload certificate: `android/.signing/upload-certificate.pem`.
- The one-time generator `tool/create_upload_keystore.ps1` uses a cryptographic
  256-bit random password. It passes it privately to keytool through the child
  process environment, not command arguments or output. Local ACLs restrict
  signing files to the current Windows user and SYSTEM.
- The generator refuses to overwrite existing signing material. Restore the
  existing files from a secure backup on another workstation; do not generate
  another key for updates to the same Play app.
- A local upload key is not enrollment in Play App Signing. If the app already
  has a different registered upload certificate in Play Console, register/reset
  the upload key through Play Console before uploading this bundle.
- Never commit `key.properties`, private keystores, passwords, or secret backups.
  The public certificate alone may be supplied to Play Console when requested.

## Verified internal build — 2026-09-02

- `flutter analyze`: no issues; `flutter test`: all 92 tests passed.
- Missing-credentials guard: `:app:validateUploadSigning` failed as expected
  before credentials were created (no Debug fallback).
- Built with `flutter build appbundle --release --dart-define=ADMOB_USE_PRODUCTION=false`.
- Output: `build/app/outputs/bundle/release/app-release.aab` (approximately 49 MB).
- JAR signature verified; bundle certificate SHA-256 matches the generated
  upload certificate, not Android Debug.
- All three compiled Dart libraries contain the Google test banner ID and
  exclude the production banner ID; no signing secrets are packaged.
- Release manifest: package `com.roqaiaapps.sakinah`, version `1.0.0+1`, not
  debuggable, correct AdMob App ID, and exactly one `AD_ID` permission.
- Old Debug Kotlin and Gradle execution-history caches were removed (regenerable).
  A workspace scan found no old package identifier outside excluded Git history,
  signing secrets and active lock files.
- Initial build retried a transient Flutter artifact DNS/download failure and
  recovered from Kotlin's cross-drive incremental-cache warnings. The final
  bundle build succeeded; no dependency versions or release checks were relaxed.
- Runtime UMP/device tests and Play Console setup remain manual, as described above.

## Later production build (not for internal testing)

Only after secure signing, device validation, UMP and store disclosures are ready:

```powershell
flutter build appbundle --release --dart-define=ADMOB_USE_PRODUCTION=true
```

## Official references

- [Flutter plugin / compatibility](https://pub.dev/packages/google_mobile_ads/changelog)
- [UMP consent and privacy options](https://developers.google.com/admob/flutter/privacy)
- [Non-personalized AdRequest API](https://pub.dev/documentation/google_mobile_ads/latest/google_mobile_ads/AdRequest/AdRequest.html)
- [Anchored adaptive banners](https://developers.google.com/admob/flutter/banner)
- [Request configuration / age treatment](https://developers.google.com/admob/flutter/targeting)
- [SDK data disclosure](https://developers.google.com/admob/android/privacy/play-data-disclosure)
- [Flutter Android upload signing](https://docs.flutter.dev/deployment/android#sign-the-app)
