# Prayer notification audio files

## Current excerpts

The source recordings were supplied locally in `Adan/` and are attributed by
the source repository at <https://github.com/Kiwifu/adhan-mp3>. The originals
remain unchanged. Each output is a continuous excerpt from time zero through
the first complete “Ash-hadu an la ilaha illa Allah”, ending in the following
quiet interval:

| Choice | Source file | Output | End | Encoding |
| --- | --- | --- | ---: | --- |
| Jerusalem | `Adhan_Al_Aqsa_-_Jerusalem_(أذان_المسجد_الأقصى_-_القدس).mp3` | `android/app/src/main/res/raw/adhan_jerusalem_short.mp3` | 37.0 s | MP3, mono, 16 kHz, 32 kbps |
| Masjid al-Haram | `Adhan_Fajr_Al_Haram_Al_Maki_(أذان_الفجر_الحرم_المكي).mp3` | `android/app/src/main/res/raw/adhan_masjid_al_haram_short.mp3` | 79.5 s | MP3, mono, 16 kHz, 32 kbps |
| Prophet's Mosque | `Adhan_Al_Haram_Al_Madani_-_Al_Madinah_1_(أذان_الحرم_المدني_-_المدينة_المنورة).mp3` | `android/app/src/main/res/raw/adhan_masjid_an_nabawi_short.mp3` | 50.0 s | MP3, mono, 16 kHz, 32 kbps |

The repository README contains a general statement that the collection is
free for Islamic apps, prayer-time software, and personal use. However, the
repository has no `LICENSE` file and no recording-specific redistribution
grant was found. That statement has therefore not been treated as sufficient
license evidence: all three manifest entries deliberately remain
`"verified": false`. This status is independent of the successful technical
checks recorded as `"technicalVerified": true`.

## Availability gate

Debug builds expose a custom sound only when `technicalVerified` is `true` and
the file is packaged at the configured asset/resource path. This permits
on-device preview and notification testing without representing redistribution
permission as verified.

Profile and release builds keep each custom choice unavailable until all of
these conditions are met:

1. The MP3 passes the technical checks and `technicalVerified` is `true`.
2. The matching entry in
   `assets/data/prayer_notification_sounds.json` contains the source URL and
   license and has `verified` set to `true`.
3. The file is packaged at the exact configured path.

The user-facing unavailable message is intentionally generic and does not
display licensing details.

Required Android raw resources:

- `android/app/src/main/res/raw/adhan_jerusalem_short.mp3`
- `android/app/src/main/res/raw/adhan_masjid_al_haram_short.mp3`
- `android/app/src/main/res/raw/adhan_masjid_an_nabawi_short.mp3`

Android raw resource names must remain lowercase ASCII with underscores. Each
sound has its own versioned notification-channel ID. If an audio file is ever
changed after release, increment that sound's channel suffix in
`prayer_alarm_sound_config.dart`; Android keeps a channel's original sound.

Do not reuse `takbeer_notification.mp3` for any of these choices: this
repository has no source or license record that proves its place attribution.
