import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {'en': _english, 'ar': _arabic};

  static const _english = <String, String>{
    'app_name': 'Islamic Companion',
    'assalamu_alaikum': 'Assalamu Alaikum',
    'location_unknown': 'Your location',
    'today': 'Today',
    'next_prayer': 'Next prayer',
    'next_prayer_in': 'Next prayer in',
    'prayer_times': 'Prayer times',
    'quick_actions': 'Explore',
    'quran': 'Quran',
    'quran_surah': 'Surah',
    'quran_search_hint': 'Search by Surah name or number',
    'quran_no_search_results': 'No Surahs match your search.',
    'quran_read_reflect': 'Read. Listen. Reflect.',
    'quran_read_reflect_message':
        'Explore all 114 Surahs and continue from where you left off.',
    'quran_continue_reading': 'Continue reading',
    'quran_select_reciter': 'Select reciter',
    'quran_ayah_count': '@count Ayahs',
    'quran_ayah_number': 'Ayah @number',
    'quran_last_read_ayah': 'Last read: Ayah @number',
    'quran_play_ayah': 'Play Ayah @number',
    'quran_previous_ayah': 'Previous Ayah',
    'quran_next_ayah': 'Next Ayah',
    'quran_play': 'Play',
    'quran_pause': 'Pause',
    'quran_stop': 'Stop',
    'meccan': 'Meccan',
    'medinan': 'Medinan',
    'quran_no_internet':
        'Quran text is not available offline yet. Connect and try again.',
    'quran_timeout': 'The Quran service took too long to respond.',
    'quran_data_error':
        'Quran text is unavailable right now. Please try again shortly.',
    'quran_audio_no_internet': 'Connect to the internet to play this Ayah.',
    'quran_audio_timeout': 'The recitation took too long to load.',
    'quran_audio_unavailable':
        'This recitation is unavailable right now. Please try again.',
    'quran_settings_error':
        'The reciter was changed, but the preference could not be saved.',
    'qibla': 'Qibla',
    'qibla_direction': 'Qibla direction',
    'loading_qibla_screen': 'Preparing the Qibla compass...',
    'current_heading': 'Current heading',
    'qibla_bearing': 'Qibla bearing',
    'turn_slightly_right': 'Turn slightly right',
    'turn_slightly_left': 'Turn slightly left',
    'facing_qibla': 'You are facing the Qibla',
    'compass_guidance':
        'Hold your phone flat and keep it away from metal objects.',
    'loading_qibla': 'Preparing the Qibla compass...',
    'compass_unavailable':
        'A compass sensor is not available on this device. You can still use the Qibla bearing shown for your location.',
    'compass_error':
        'The compass could not be read. Move away from magnetic objects and try again.',
    'qibla_location_services_disabled':
        'Turn on location services to calculate the Qibla from your position.',
    'qibla_location_permission_denied':
        'Location access is needed to calculate the Qibla direction.',
    'qibla_location_permission_permanently_denied':
        'Location access is disabled. Enable it in device settings to use the Qibla compass.',
    'qibla_location_unavailable':
        'We could not determine your location for the Qibla calculation.',
    'north_short': 'N',
    'east_short': 'E',
    'south_short': 'S',
    'west_short': 'W',
    'azkar': 'Azkar',
    'tasbih': 'Tasbih',
    'prayer_tracker': 'Prayer tracker',
    'today_prayers': "Today's prayers",
    'completed_count': '@done / @total completed',
    'fajr': 'Fajr',
    'sunrise': 'Sunrise',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
    'loading_prayer_times': 'Finding your local prayer times…',
    'retry': 'Try again',
    'open_settings': 'Open settings',
    'location_services_disabled':
        'Turn on location services to calculate prayer times for your area.',
    'location_permission_denied':
        'Location access is needed for accurate prayer times.',
    'location_permission_permanently_denied':
        'Location access is disabled. Enable it from your device settings.',
    'location_unavailable':
        'We could not determine your location. Please try again.',
    'network_error':
        'You appear to be offline. Connect to the internet and try again.',
    'timeout_error': 'The prayer-times service took too long to respond.',
    'prayer_times_error':
        'Prayer times are unavailable right now. Please try again shortly.',
    'cached_data': 'Showing saved prayer times',
    'coming_soon': 'Coming soon',
    'coming_soon_message':
        'This space is prepared for the next development phase.',
    'back_home': 'Back to home',
    'theme': 'Theme',
    'language': 'Language',
  };

  static const _arabic = <String, String>{
    'qibla_direction': 'اتجاه القبلة',
    'loading_qibla_screen': 'جارٍ تجهيز بوصلة القبلة…',
    'current_heading': 'اتجاه الجهاز',
    'qibla_bearing': 'زاوية القبلة',
    'turn_slightly_right': 'استدر قليلاً إلى اليمين',
    'turn_slightly_left': 'استدر قليلاً إلى اليسار',
    'facing_qibla': 'أنت الآن باتجاه القبلة',
    'compass_guidance': 'أمسك الهاتف بشكل مستوٍ وأبعده عن الأجسام المعدنية.',
    'loading_qibla': 'جارٍ تجهيز بوصلة القبلة…',
    'compass_unavailable':
        'لا يتوفر مستشعر بوصلة على هذا الجهاز. لا يزال بإمكانك استخدام زاوية القبلة المعروضة لموقعك.',
    'compass_error':
        'تعذرت قراءة البوصلة. ابتعد عن الأجسام المغناطيسية وحاول مرة أخرى.',
    'qibla_location_services_disabled':
        'فعّل خدمات الموقع لحساب اتجاه القبلة من موقعك.',
    'qibla_location_permission_denied':
        'يلزم السماح بالموقع لحساب اتجاه القبلة.',
    'qibla_location_permission_permanently_denied':
        'الوصول إلى الموقع معطّل. فعّله من إعدادات الجهاز لاستخدام بوصلة القبلة.',
    'qibla_location_unavailable': 'تعذر تحديد موقعك لحساب اتجاه القبلة.',
    'north_short': 'ش',
    'east_short': 'ق',
    'south_short': 'ج',
    'west_short': 'غ',
    'app_name': 'رفيق المسلم',
    'assalamu_alaikum': 'السلام عليكم',
    'location_unknown': 'موقعك الحالي',
    'today': 'اليوم',
    'next_prayer': 'الصلاة القادمة',
    'next_prayer_in': 'متبقي على الصلاة',
    'prayer_times': 'مواقيت الصلاة',
    'quick_actions': 'استكشف',
    'quran': 'القرآن',
    'quran_surah': 'السورة',
    'quran_search_hint': 'ابحث باسم السورة أو رقمها',
    'quran_no_search_results': 'لا توجد سور مطابقة لبحثك.',
    'quran_read_reflect': 'اقرأ واستمع وتدبّر',
    'quran_read_reflect_message':
        'تصفّح سور القرآن الـ ١١٤ وتابع القراءة من حيث توقفت.',
    'quran_continue_reading': 'متابعة القراءة',
    'quran_select_reciter': 'اختيار القارئ',
    'quran_ayah_count': '@count آية',
    'quran_ayah_number': 'الآية @number',
    'quran_last_read_ayah': 'آخر قراءة: الآية @number',
    'quran_play_ayah': 'تشغيل الآية @number',
    'quran_previous_ayah': 'الآية السابقة',
    'quran_next_ayah': 'الآية التالية',
    'quran_play': 'تشغيل',
    'quran_pause': 'إيقاف مؤقت',
    'quran_stop': 'إيقاف',
    'meccan': 'مكية',
    'medinan': 'مدنية',
    'quran_no_internet':
        'نص القرآن غير متاح دون اتصال بعد. اتصل بالإنترنت وحاول مجددًا.',
    'quran_timeout': 'استغرقت خدمة القرآن وقتًا أطول من المتوقع.',
    'quran_data_error': 'نص القرآن غير متاح حاليًا. حاول بعد قليل.',
    'quran_audio_no_internet': 'اتصل بالإنترنت لتشغيل هذه الآية.',
    'quran_audio_timeout': 'استغرق تحميل التلاوة وقتًا أطول من المتوقع.',
    'quran_audio_unavailable': 'هذه التلاوة غير متاحة حاليًا. حاول مجددًا.',
    'quran_settings_error': 'تم تغيير القارئ، لكن تعذر حفظ الاختيار.',
    'qibla': 'القبلة',
    'azkar': 'الأذكار',
    'tasbih': 'التسبيح',
    'prayer_tracker': 'متابعة الصلاة',
    'today_prayers': 'صلوات اليوم',
    'completed_count': 'اكتملت @done من @total',
    'fajr': 'الفجر',
    'sunrise': 'الشروق',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
    'loading_prayer_times': 'جارٍ تحديد مواقيت الصلاة في موقعك…',
    'retry': 'حاول مرة أخرى',
    'open_settings': 'فتح الإعدادات',
    'location_services_disabled':
        'فعّل خدمات الموقع لحساب مواقيت الصلاة في منطقتك.',
    'location_permission_denied':
        'يلزم السماح بالموقع للحصول على مواقيت دقيقة.',
    'location_permission_permanently_denied':
        'الوصول إلى الموقع معطّل. فعّله من إعدادات الجهاز.',
    'location_unavailable': 'تعذر تحديد موقعك. حاول مرة أخرى.',
    'network_error':
        'يبدو أنك غير متصل بالإنترنت. تحقق من الاتصال وحاول مجددًا.',
    'timeout_error': 'استغرقت خدمة مواقيت الصلاة وقتًا أطول من المتوقع.',
    'prayer_times_error': 'مواقيت الصلاة غير متاحة حاليًا. حاول بعد قليل.',
    'cached_data': 'يتم عرض المواقيت المحفوظة',
    'coming_soon': 'قريبًا',
    'coming_soon_message': 'تم تجهيز هذا القسم للمرحلة القادمة من التطوير.',
    'back_home': 'العودة للرئيسية',
    'theme': 'المظهر',
    'language': 'اللغة',
  };
}
