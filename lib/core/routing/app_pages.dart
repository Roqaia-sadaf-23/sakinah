import 'package:get/get.dart';

import '../../features/home/presentation/bindings/home_binding.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/qibla/presentation/bindings/qibla_binding.dart';
import '../../features/qibla/presentation/pages/qibla_page.dart';
import '../../features/quran/presentation/bindings/quran_binding.dart';
import '../../features/quran/presentation/pages/quran_page.dart';
import '../../features/quran/presentation/pages/surah_page.dart';
import '../widgets/coming_soon_page.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(name: AppRoutes.home, page: HomePage.new, binding: HomeBinding()),
    GetPage(
      name: AppRoutes.qibla,
      page: QiblaPage.new,
      binding: QiblaBinding(),
    ),
    GetPage(
      name: AppRoutes.quran,
      page: QuranPage.new,
      binding: QuranBinding(),
    ),
    GetPage(
      name: AppRoutes.quranSurah,
      page: SurahPage.new,
      binding: QuranBinding(),
    ),
    ...{AppRoutes.azkar: 'azkar', AppRoutes.tasbih: 'tasbih'}.entries.map(
      (entry) => GetPage(
        name: entry.key,
        page: () => ComingSoonPage(featureKey: entry.value),
      ),
    ),
  ];
}
