enum PrayerReminderType { takbeer, text }

enum PrayerAlarmSound {
  jerusalem,
  masjidAlHaram,
  masjidAnNabawi,
  systemDefault,
  silent,
}

class PrayerReminderSettings {
  const PrayerReminderSettings({
    this.enabled = false,
    this.minutesBefore = 5,
    PrayerAlarmSound? alarmSound,
    PrayerReminderType type = PrayerReminderType.text,
    this.notificationPermissionRequested = false,
    this.exactAlarmPermissionRequested = false,
  }) : alarmSound = alarmSound ?? PrayerAlarmSound.systemDefault;

  static const defaults = PrayerReminderSettings();
  static const minMinutesBefore = 1;
  static const maxMinutesBefore = 120;
  static const presetMinutes = <int>[5, 10, 15, 20, 30];

  final bool enabled;
  final int minutesBefore;
  final PrayerAlarmSound alarmSound;
  final bool notificationPermissionRequested;
  final bool exactAlarmPermissionRequested;

  /// Kept for stored-setting and API compatibility with older app versions.
  PrayerReminderType get type =>
      {
        PrayerAlarmSound.jerusalem,
        PrayerAlarmSound.masjidAlHaram,
        PrayerAlarmSound.masjidAnNabawi,
      }.contains(alarmSound)
      ? PrayerReminderType.takbeer
      : PrayerReminderType.text;

  static bool isValidMinutes(int minutes) =>
      minutes >= minMinutesBefore && minutes <= maxMinutesBefore;

  PrayerReminderSettings copyWith({
    bool? enabled,
    int? minutesBefore,
    PrayerAlarmSound? alarmSound,
    PrayerReminderType? type,
    bool? notificationPermissionRequested,
    bool? exactAlarmPermissionRequested,
  }) => PrayerReminderSettings(
    enabled: enabled ?? this.enabled,
    minutesBefore: minutesBefore ?? this.minutesBefore,
    alarmSound:
        alarmSound ??
        (type == null ? this.alarmSound : PrayerAlarmSound.systemDefault),
    notificationPermissionRequested:
        notificationPermissionRequested ?? this.notificationPermissionRequested,
    exactAlarmPermissionRequested:
        exactAlarmPermissionRequested ?? this.exactAlarmPermissionRequested,
  );

  factory PrayerReminderSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return defaults;
    final storedMinutes = json['minutesBefore'];
    final minutes = storedMinutes is num ? storedMinutes.toInt() : 5;
    final migratedSound = switch (json['alarmSound']) {
      'systemDefault' => PrayerAlarmSound.systemDefault,
      'jerusalem' => PrayerAlarmSound.jerusalem,
      'masjidAlHaram' => PrayerAlarmSound.masjidAlHaram,
      'masjidAnNabawi' => PrayerAlarmSound.masjidAnNabawi,
      'silent' => PrayerAlarmSound.silent,
      // The legacy Takbeer file has no provenance in this repository, so an
      // old value must not be attributed to one of the three named places.
      'takbeer' => PrayerAlarmSound.systemDefault,
      _ => PrayerAlarmSound.systemDefault,
    };
    return PrayerReminderSettings(
      enabled: json['enabled'] == true,
      minutesBefore: isValidMinutes(minutes) ? minutes : 5,
      alarmSound: migratedSound,
      notificationPermissionRequested:
          json['notificationPermissionRequested'] == true,
      exactAlarmPermissionRequested:
          json['exactAlarmPermissionRequested'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'minutesBefore': minutesBefore,
    'alarmSound': alarmSound.name,
    // Continue writing the legacy field so a downgraded build still works.
    'type': type.name,
    'notificationPermissionRequested': notificationPermissionRequested,
    'exactAlarmPermissionRequested': exactAlarmPermissionRequested,
  };
}
