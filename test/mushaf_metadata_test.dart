import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/features/quran/data/services/asset_mushaf_page_source.dart';
import 'package:sakinah/features/quran/domain/entities/mushaf_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pinned KFQC metadata covers every Ayah and all 604 pages', () async {
    final metadata = await AssetMushafPageSource().loadMetadata();

    expect(metadata.surahs, hasLength(114));
    expect(metadata.ayahs, hasLength(6236));
    expect(
      List<int>.generate(
        MushafMetadata.totalPages,
        (index) => metadata.page(index + 1).pageNumber,
      ),
      hasLength(604),
    );

    expect(metadata.page(1).firstAyah.surahNumber, 1);
    expect(metadata.page(1).firstAyah.ayahNumber, 1);
    expect(metadata.page(2).firstAyah.surahNumber, 2);
    expect(metadata.page(2).firstAyah.ayahNumber, 1);
    expect(metadata.page(604).surahs.map((surah) => surah.number), [
      112,
      113,
      114,
    ]);
    expect(metadata.page(604).ayahs.last.surahNumber, 114);
    expect(metadata.page(604).ayahs.last.ayahNumber, 6);
  });

  test('Madinah page and Juz boundaries remain stable', () async {
    final metadata = await AssetMushafPageSource().loadMetadata();

    expect(metadata.referenceFor(1, 7).pageNumber, 1);
    expect(metadata.referenceFor(2, 1).pageNumber, 2);
    expect(metadata.referenceFor(114, 6).pageNumber, 604);
    expect(metadata.juzForPage(1), 1);
    expect(metadata.juzForPage(21), 1);
    expect(metadata.juzForPage(22), 2);
    expect(metadata.juzForPage(582), 30);
    expect(metadata.juzForPage(604), 30);
  });
}
