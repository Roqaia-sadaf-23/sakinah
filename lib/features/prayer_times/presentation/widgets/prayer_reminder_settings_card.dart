import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/prayer_reminder_settings.dart';
import '../controllers/prayer_reminder_controller.dart';

class PrayerReminderSettingsCard extends StatelessWidget {
  const PrayerReminderSettingsCard({required this.controller, super.key});

  final PrayerReminderController controller;

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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.55,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text('reminder_time'.tr)),
                  Text(
                    'minutes_before_prayer'.trParams({
                      'minutes': '${settings.minutesBefore}',
                    }),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'reminder_type'.tr,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.volume_up_outlined, size: 18),
                  label: Text('reminder_takbeer'.tr),
                  selected: settings.type == PrayerReminderType.takbeer,
                  onSelected: busy
                      ? null
                      : (selected) {
                          if (selected) {
                            controller.setReminderType(
                              PrayerReminderType.takbeer,
                            );
                          }
                        },
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.message_outlined, size: 18),
                  label: Text('reminder_text'.tr),
                  selected: settings.type == PrayerReminderType.text,
                  onSelected: busy
                      ? null
                      : (selected) {
                          if (selected) {
                            controller.setReminderType(PrayerReminderType.text);
                          }
                        },
                ),
              ],
            ),
            if (settings.type == PrayerReminderType.takbeer) ...[
              const SizedBox(height: 10),
              Text(
                'takbeer_sound_pending'.tr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (issue != null) ...[
              const SizedBox(height: 14),
              _PermissionWarning(
                messageKey: switch (issue) {
                  PrayerReminderPermissionIssue.notifications =>
                    'notification_permission_denied',
                  PrayerReminderPermissionIssue.exactAlarm =>
                    'exact_alarm_permission_denied',
                  PrayerReminderPermissionIssue.scheduling =>
                    'notification_scheduling_error',
                },
                busy: busy,
                onOpenSettings: controller.openRelevantSettings,
              ),
            ],
          ],
        ),
      ),
    );
  });
}

class _PermissionWarning extends StatelessWidget {
  const _PermissionWarning({
    required this.messageKey,
    required this.busy,
    required this.onOpenSettings,
  });

  final String messageKey;
  final bool busy;
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
          const SizedBox(width: 6),
          TextButton(
            onPressed: busy ? null : onOpenSettings,
            child: Text('open_settings'.tr),
          ),
        ],
      ),
    );
  }
}
