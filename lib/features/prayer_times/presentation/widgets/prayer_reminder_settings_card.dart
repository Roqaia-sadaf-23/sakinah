import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../domain/entities/prayer_reminder_settings.dart';
import '../controllers/prayer_reminder_controller.dart';

class PrayerReminderSettingsCard extends StatelessWidget {
  const PrayerReminderSettingsCard({required this.controller, super.key});

  final PrayerReminderController controller;

  Future<void> _selectReminderTime(BuildContext context) async {
    final minutes = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ReminderTimeSheet(
        currentMinutes: controller.settings.value.minutesBefore,
      ),
    );
    if (minutes != null) {
      await controller.setMinutesBefore(minutes);
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final settings = controller.settings.value;
    final busy = controller.isBusy.value;
    final issue = controller.permissionIssue.value;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'prayer_reminders'.tr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'prayer_reminders_subtitle'.tr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: settings.enabled,
                  onChanged: busy ? null : controller.setEnabled,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: busy ? null : () => _selectReminderTime(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.55,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.schedule_rounded, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('reminder_time'.tr),
                            const SizedBox(height: 2),
                            Text(
                              'minutes_before_prayer'.trParams({
                                'minutes': '${settings.minutesBefore}',
                              }),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'alarm_sound'.tr,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'alarm_sound_description'.tr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            for (final sound in PrayerAlarmSound.values) ...[
              _AlarmSoundOption(
                sound: sound,
                selected: settings.alarmSound == sound,
                enabled: !busy && controller.isSoundAvailable(sound),
                available: controller.isSoundAvailable(sound),
                previewing: controller.previewingSound.value == sound,
                onSelected: () => controller.setAlarmSound(sound),
                onPreview: () async {
                  final previewed = await controller.previewAlarmSound(sound);
                  if (!context.mounted) return;
                  final messageKey = !previewed
                      ? 'alarm_preview_error'
                      : sound == PrayerAlarmSound.silent
                      ? 'alarm_silent_preview'
                      : null;
                  if (messageKey != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(messageKey.tr)));
                  }
                },
              ),
              if (sound != PrayerAlarmSound.values.last)
                const SizedBox(height: 8),
            ],
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      final result = await controller
                          .scheduleNotificationTest();
                      if (!context.mounted) return;
                      final messageKey = switch (result) {
                        PrayerNotificationTestResult.scheduled =>
                          'notification_test_scheduled',
                        PrayerNotificationTestResult.notificationsDenied =>
                          'notification_permission_denied',
                        PrayerNotificationTestResult.exactAlarmDenied =>
                          'exact_alarm_permission_denied',
                        PrayerNotificationTestResult.soundUnavailable =>
                          'alarm_sound_file_missing',
                        PrayerNotificationTestResult.schedulingFailed =>
                          'notification_test_failed',
                      };
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(messageKey.tr)));
                    },
              icon: const Icon(Icons.notifications_active_outlined),
              label: Text('test_selected_sound'.tr),
            ),
            if (issue != null) ...[
              const SizedBox(height: 14),
              _PermissionWarning(
                messageKey: switch (issue) {
                  PrayerReminderPermissionIssue.notifications =>
                    'notification_permission_denied',
                  PrayerReminderPermissionIssue.exactAlarm =>
                    'exact_alarm_permission_denied',
                  PrayerReminderPermissionIssue.soundFileMissing =>
                    'alarm_sound_file_missing',
                  PrayerReminderPermissionIssue.scheduling =>
                    'notification_scheduling_error',
                },
                busy: busy,
                showSettings:
                    issue != PrayerReminderPermissionIssue.soundFileMissing,
                onOpenSettings: controller.openRelevantSettings,
              ),
            ],
          ],
        ),
      ),
    );
  });
}

class _AlarmSoundOption extends StatelessWidget {
  const _AlarmSoundOption({
    required this.sound,
    required this.selected,
    required this.enabled,
    required this.available,
    required this.previewing,
    required this.onSelected,
    required this.onPreview,
  });

  final PrayerAlarmSound sound;
  final bool selected;
  final bool enabled;
  final bool available;
  final bool previewing;
  final VoidCallback onSelected;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = switch (sound) {
      PrayerAlarmSound.jerusalem => 'alarm_sound_jerusalem'.tr,
      PrayerAlarmSound.masjidAlHaram => 'alarm_sound_masjid_al_haram'.tr,
      PrayerAlarmSound.masjidAnNabawi => 'alarm_sound_masjid_an_nabawi'.tr,
      PrayerAlarmSound.systemDefault => 'alarm_sound_default'.tr,
      PrayerAlarmSound.silent => 'alarm_sound_silent'.tr,
    };
    final icon = switch (sound) {
      PrayerAlarmSound.jerusalem => Icons.mosque_outlined,
      PrayerAlarmSound.masjidAlHaram => Icons.mosque_rounded,
      PrayerAlarmSound.masjidAnNabawi => Icons.mosque_rounded,
      PrayerAlarmSound.systemDefault => Icons.notifications_outlined,
      PrayerAlarmSound.silent => Icons.notifications_off_outlined,
    };

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.58)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onSelected : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 6, 8),
            child: Row(
              children: [
                Icon(icon, size: 21, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: available
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (!available)
                        Text(
                          'alarm_sound_unavailable_short'.tr,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.error),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: colorScheme.primary),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'preview_alarm_sound'.trParams({'sound': label}),
                  onPressed: enabled && !previewing ? onPreview : null,
                  icon: previewing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderTimeSheet extends StatefulWidget {
  const _ReminderTimeSheet({required this.currentMinutes});

  final int currentMinutes;

  @override
  State<_ReminderTimeSheet> createState() => _ReminderTimeSheetState();
}

class _ReminderTimeSheetState extends State<_ReminderTimeSheet> {
  late final TextEditingController _customController;
  bool _showCustom = false;
  String? _customError;

  @override
  void initState() {
    super.initState();
    _showCustom = !PrayerReminderSettings.presetMinutes.contains(
      widget.currentMinutes,
    );
    _customController = TextEditingController(
      text: _showCustom ? '${widget.currentMinutes}' : '',
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _submitCustom() {
    final minutes = int.tryParse(_customController.text.trim());
    if (minutes == null || !PrayerReminderSettings.isValidMinutes(minutes)) {
      setState(() => _customError = 'reminder_minutes_range'.tr);
      return;
    }
    Navigator.of(context).pop(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'select_reminder_time'.tr,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final minutes in PrayerReminderSettings.presetMinutes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'reminder_minutes_option'.trParams({'minutes': '$minutes'}),
              ),
              trailing: widget.currentMinutes == minutes
                  ? Icon(
                      Icons.check_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () => Navigator.of(context).pop(minutes),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('custom_reminder_time'.tr),
            trailing: _showCustom
                ? Icon(
                    Icons.check_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () => setState(() {
              _showCustom = true;
              _customError = null;
            }),
          ),
          if (_showCustom) ...[
            const SizedBox(height: 4),
            TextField(
              controller: _customController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'custom_minutes_label'.tr,
                hintText: 'custom_minutes_hint'.tr,
                errorText: _customError,
              ),
              onChanged: (_) {
                if (_customError != null) {
                  setState(() => _customError = null);
                }
              },
              onSubmitted: (_) => _submitCustom(),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submitCustom, child: Text('save'.tr)),
          ],
        ],
      ),
    );
  }
}

class _PermissionWarning extends StatelessWidget {
  const _PermissionWarning({
    required this.messageKey,
    required this.busy,
    required this.showSettings,
    required this.onOpenSettings,
  });

  final String messageKey;
  final bool busy;
  final bool showSettings;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              messageKey.tr,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
          if (showSettings) ...[
            const SizedBox(width: 6),
            TextButton(
              onPressed: busy ? null : onOpenSettings,
              child: Text('open_settings'.tr),
            ),
          ],
        ],
      ),
    );
  }
}
