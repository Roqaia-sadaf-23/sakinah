enum PrayerReminderType { takbeer, text }

class PrayerReminderSettings {
  const PrayerReminderSettings({
    this.enabled = false,
    this.minutesBefore = 5,
    this.type = PrayerReminderType.text,
    this.notificationPermissionRequested = false,
    this.exactAlarmPermissionRequested = false,
  });

  static const defaults = PrayerReminderSettings();

  final bool enabled;
  final int minutesBefore;
  final PrayerReminderType type;
  final bool notificationPermissionRequested;
  final bool exactAlarmPermissionRequested;

  PrayerReminderSettings copyWith({
    bool? enabled,
    int? minutesBefore,
    PrayerReminderType? type,
    bool? notificationPermissionRequested,
    bool? exactAlarmPermissionRequested,
  }) => PrayerReminderSettings(
    enabled: enabled ?? this.enabled,
    minutesBefore: minutesBefore ?? this.minutesBefore,
    type: type ?? this.type,
    notificationPermissionRequested:
        notificationPermissionRequested ?? this.notificationPermissionRequested,
    exactAlarmPermissionRequested:
        exactAlarmPermissionRequested ?? this.exactAlarmPermissionRequested,
  );

  factory PrayerReminderSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return defaults;
    final storedMinutes = json['minutesBefore'];
    final minutes = storedMinutes is num ? storedMinutes.toInt() : 5;
    return PrayerReminderSettings(
      enabled: json['enabled'] == true,
      minutesBefore: minutes > 0 && minutes <= 60 ? minutes : 5,
      type: json['type'] == PrayerReminderType.takbeer.name
          ? PrayerReminderType.takbeer
          : PrayerReminderType.text,
      notificationPermissionRequested:
          json['notificationPermissionRequested'] == true,
      exactAlarmPermissionRequested:
          json['exactAlarmPermissionRequested'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'minutesBefore': minutesBefore,
    'type': type.name,
    'notificationPermissionRequested': notificationPermissionRequested,
    'exactAlarmPermissionRequested': exactAlarmPermissionRequested,
  };
}
