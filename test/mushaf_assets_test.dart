import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/features/quran/data/services/asset_mushaf_page_source.dart';
import 'package:sakinah/features/quran/domain/entities/mushaf_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all 604 bundled KFQC pages pass integrity, mapping, and SVG parsing',
    () async {
      final source = AssetMushafPageSource();
      final metadata = await source.loadMetadata();
      final expectedHashes = await _loadExpectedHashes();
      final originalCacheSize = svg.cache.maximumSize;
      svg.cache.maximumSize = 1;
      addTearDown(() {
        svg.cache.clear();
        svg.cache.maximumSize = originalCacheSize;
      });

      expect(expectedHashes, hasLength(MushafMetadata.totalPages));

      for (
        var pageNumber = 1;
        pageNumber <= MushafMetadata.totalPages;
        pageNumber++
      ) {
        final fileName = '${pageNumber.toString().padLeft(3, '0')}.svg';
        final assetPath = AssetMushafPageSource.assetPathForPage(pageNumber);
        final data = await rootBundle.load(assetPath);
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        final pageSvg = utf8.decode(bytes);

        expect(
          sha256.convert(bytes).toString(),
          expectedHashes[fileName],
          reason: 'Page $pageNumber differs from its pinned-commit manifest',
        );
        expect(pageSvg, contains('<svg'));
        expect(pageSvg, contains('viewBox='));

        final actualAyahs = RegExp(
          r'id="verse-(\d+)"',
        ).allMatches(pageSvg).map((match) => int.parse(match.group(1)!));
        final expectedAyahs = metadata
            .page(pageNumber)
            .ayahs
            .map((ayah) => ayah.globalAyahNumber);
        expect(
          actualAyahs,
          orderedEquals(expectedAyahs),
          reason: 'Page $pageNumber does not match its verified ayah metadata',
        );

        final compiledSvg = await SvgStringLoader(pageSvg).loadBytes(null);
        expect(
          compiledSvg.lengthInBytes,
          greaterThan(0),
          reason: 'Page $pageNumber did not compile with flutter_svg',
        );
        svg.cache.clear();
        // flutter_svg intentionally compiles synchronously under the test
        // binding. Yield so 604 sequential SynchronousFuture callbacks do not
        // accumulate on the same stack.
        await Future<void>.delayed(Duration.zero);
      }
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

Future<Map<String, String>> _loadExpectedHashes() async {
  const manifestAsset = 'assets/data/quran/mushaf_hafs_kfqc_pages.sha256';
  final manifest = await rootBundle.loadString(manifestAsset);
  final entryPattern = RegExp(r'^([0-9a-f]{64})  (\d{3}\.svg)$');
  final hashes = <String, String>{};

  for (final line in const LineSplitter().convert(manifest)) {
    if (line.isEmpty || line.startsWith('#')) continue;
    final match = entryPattern.firstMatch(line);
    if (match == null) {
      throw FormatException('Invalid Mushaf checksum entry: $line');
    }
    hashes[match.group(2)!] = match.group(1)!;
  }

  return hashes;
}
