# Islamic Companion

Phase-one Flutter MVP foundation for a calm, location-aware Islamic daily
companion.

## Included in this phase

- Feature-first Clean Architecture with GetX bindings, navigation, and state
- English and Arabic localization with automatic RTL support
- Persisted light/dark theme and language selection
- Permission-aware device location and reverse-geocoded city
- AlAdhan prayer times for today and tomorrow
- Location/date-keyed prayer-time cache and friendly offline/error states
- Live next-prayer selection and one-second countdown, including post-Isha rollover
- Responsive home screen, quick-action placeholders, and a local daily prayer tracker
- Great-circle Qibla bearing with a smoothly animated device compass
- Qibla alignment guidance and graceful no-sensor/location error states

Quran, Azkar, Tasbih, notifications, and full tracker history UI are
intentionally reserved for later phases.

## Run

```shell
flutter pub get
flutter run
```

Use a physical device for real GPS results. On an emulator, set a simulated
location before granting the app's location permission.

## Verify

```shell
flutter analyze
flutter test
```

The default prayer calculation method is Umm Al-Qura (AlAdhan method `4`). A
user-selectable calculation method is a recommended settings enhancement.
