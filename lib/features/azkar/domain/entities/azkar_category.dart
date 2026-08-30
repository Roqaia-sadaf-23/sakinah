import 'dhikr.dart';

class AzkarCategory {
  const AzkarCategory({
    required this.id,
    required this.titleKey,
    required this.isDaily,
    required this.items,
  });

  final String id;
  final String titleKey;
  final bool isDaily;
  final List<Dhikr> items;
}
