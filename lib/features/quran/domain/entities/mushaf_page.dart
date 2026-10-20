class MushafAyahReference {
  const MushafAyahReference({
    required this.globalAyahNumber,
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageNumber,
    required this.markerX,
    required this.markerY,
  });

  final int globalAyahNumber;
  final int surahNumber;
  final int ayahNumber;
  final int pageNumber;
  final double markerX;
  final double markerY;
}

class MushafSurahMetadata {
  const MushafSurahMetadata({
    required this.number,
    required this.ayahCount,
    required this.pageNumber,
    required this.juzNumber,
    required this.arabicName,
    required this.englishName,
  });

  final int number;
  final int ayahCount;
  final int pageNumber;
  final int juzNumber;
  final String arabicName;
  final String englishName;
}

class MushafPageMetadata {
  const MushafPageMetadata({
    required this.pageNumber,
    required this.juzNumber,
    required this.surahs,
    required this.ayahs,
  });

  final int pageNumber;
  final int juzNumber;
  final List<MushafSurahMetadata> surahs;
  final List<MushafAyahReference> ayahs;

  MushafAyahReference get firstAyah => ayahs.first;
}

class MushafMetadata {
  MushafMetadata({
    required List<MushafSurahMetadata> surahs,
    required List<MushafAyahReference> ayahs,
  }) : surahs = List<MushafSurahMetadata>.unmodifiable(surahs),
       ayahs = List<MushafAyahReference>.unmodifiable(ayahs) {
    if (surahs.length != 114 || ayahs.length != 6236) {
      throw const FormatException('Incomplete Madinah Mushaf metadata');
    }
    for (var index = 0; index < surahs.length; index++) {
      if (surahs[index].number != index + 1) {
        throw const FormatException('Non-sequential Surah metadata');
      }
    }
    for (var index = 0; index < ayahs.length; index++) {
      final ayah = ayahs[index];
      if (ayah.globalAyahNumber != index + 1 ||
          ayah.pageNumber < 1 ||
          ayah.pageNumber > totalPages) {
        throw const FormatException('Invalid Mushaf Ayah metadata');
      }
      _ayahByKey['${ayah.surahNumber}:${ayah.ayahNumber}'] = ayah;
      (_ayahsByPage[ayah.pageNumber] ??= <MushafAyahReference>[]).add(ayah);
    }
    if (_ayahsByPage.length != totalPages) {
      throw const FormatException('Mushaf metadata must cover all 604 pages');
    }
  }

  static const totalPages = 604;

  // Standard 604-page Madinah Mushaf juz boundaries. Page 1 contains
  // Al-Fatiha and page 2 begins Al-Baqarah; subsequent values are the first
  // page of each Juz in this same layout.
  static const _juzStartPages = <int>[
    1,
    22,
    42,
    62,
    82,
    102,
    121,
    142,
    162,
    182,
    201,
    222,
    242,
    262,
    282,
    302,
    322,
    342,
    362,
    382,
    402,
    422,
    442,
    462,
    482,
    502,
    522,
    542,
    562,
    582,
  ];

  final List<MushafSurahMetadata> surahs;
  final List<MushafAyahReference> ayahs;
  final Map<String, MushafAyahReference> _ayahByKey = {};
  final Map<int, List<MushafAyahReference>> _ayahsByPage = {};

  MushafAyahReference referenceFor(int surahNumber, int ayahNumber) {
    final reference = _ayahByKey['$surahNumber:$ayahNumber'];
    if (reference == null) {
      throw RangeError('Unknown Ayah $surahNumber:$ayahNumber');
    }
    return reference;
  }

  MushafPageMetadata page(int pageNumber) {
    if (pageNumber < 1 || pageNumber > totalPages) {
      throw RangeError.range(pageNumber, 1, totalPages, 'pageNumber');
    }
    final pageAyahs = _ayahsByPage[pageNumber]!;
    final surahNumbers = pageAyahs.map((ayah) => ayah.surahNumber).toSet();
    return MushafPageMetadata(
      pageNumber: pageNumber,
      juzNumber: juzForPage(pageNumber),
      surahs: surahNumbers
          .map((number) => surahs[number - 1])
          .toList(growable: false),
      ayahs: List<MushafAyahReference>.unmodifiable(pageAyahs),
    );
  }

  int juzForPage(int pageNumber) {
    var juz = 1;
    for (var index = 1; index < _juzStartPages.length; index++) {
      if (pageNumber < _juzStartPages[index]) break;
      juz = index + 1;
    }
    return juz;
  }
}
