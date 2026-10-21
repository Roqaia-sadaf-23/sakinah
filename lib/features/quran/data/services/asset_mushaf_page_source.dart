import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/mushaf_page.dart';
import '../../domain/repositories/mushaf_page_source.dart';

class AssetMushafPageSource implements MushafPageSource {
  AssetMushafPageSource({AssetBundle? assetBundle})
    : _assetBundle = assetBundle ?? rootBundle;

  static const sourceCommit = '9fc0c87aebd7e528ceb90706707d6e5e9d2d698b';
  static const pageAssetPrefix = 'assets/quran/mushaf/hafs_kfqc/pages_bz2';
  static const _surahAsset = 'assets/data/quran/mushaf_hafs_kfqc_surahs.json';
  static const _markerAsset = 'assets/data/quran/mushaf_hafs_kfqc_markers.json';

  final AssetBundle _assetBundle;
  final Map<int, String> _svgCache = <int, String>{};
  final Map<int, Future<String>> _pendingPages = <int, Future<String>>{};
  Future<MushafMetadata>? _metadata;

  static String assetPathForPage(int pageNumber) {
    _validatePageNumber(pageNumber);
    final fileName = pageNumber.toString().padLeft(3, '0');
    return '$pageAssetPrefix/$fileName.svg.bz2';
  }

  @override
  Future<MushafMetadata> loadMetadata() {
    final request = _metadata ??= _loadAndValidateMetadata();
    return request.catchError((Object error) {
      _metadata = null;
      throw error;
    });
  }

  @override
  Future<String> loadPageSvg(int pageNumber) {
    _validatePageNumber(pageNumber);
    final cached = _svgCache[pageNumber];
    if (cached != null) return Future<String>.value(cached);
    return _pendingPages[pageNumber] ??= _loadBundledPage(pageNumber);
  }

  @override
  void prefetchPage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > MushafMetadata.totalPages) return;
    unawaited(loadPageSvg(pageNumber).catchError((_) => ''));
  }

  Future<String> _loadBundledPage(int pageNumber) async {
    try {
      final compressed = await _assetBundle.load(assetPathForPage(pageNumber));
      final bytes = compressed.buffer.asUint8List(
        compressed.offsetInBytes,
        compressed.lengthInBytes,
      );
      final svg = await compute(
        _decodeMushafPage,
        bytes,
        debugLabel: 'Decode Mushaf page $pageNumber',
      );
      if (!svg.contains('<svg') ||
          !svg.contains('viewBox=') ||
          !svg.contains('ayahPolygon')) {
        throw FormatException('Invalid bundled Mushaf page $pageNumber');
      }
      _svgCache[pageNumber] = svg;
      while (_svgCache.length > 5) {
        _svgCache.remove(_svgCache.keys.first);
      }
      return svg;
    } finally {
      _pendingPages.remove(pageNumber);
    }
  }

  Future<MushafMetadata> _loadAndValidateMetadata() async {
    final values = await Future.wait<String>([
      _assetBundle.loadString(_surahAsset),
      _assetBundle.loadString(_markerAsset),
    ]);
    final rawSurahs = jsonDecode(values[0]);
    final rawMarkers = jsonDecode(values[1]);
    if (rawSurahs is! List || rawMarkers is! List) {
      throw const FormatException('Invalid Mushaf metadata');
    }

    final surahs = rawSurahs
        .map((raw) {
          if (raw is! Map<String, dynamic>) {
            throw const FormatException('Invalid Surah metadata');
          }
          return MushafSurahMetadata(
            number: raw['number'] as int,
            ayahCount: raw['ayahCount'] as int,
            pageNumber: raw['pageNumber'] as int,
            juzNumber: raw['juzNumber'] as int,
            arabicName: raw['nameArabic'] as String,
            englishName: raw['nameEnglish'] as String,
          );
        })
        .toList(growable: false);

    var surahIndex = 0;
    var firstGlobalAyah = 1;
    final ayahs = rawMarkers
        .map((raw) {
          if (raw is! Map<String, dynamic>) {
            throw const FormatException('Invalid Ayah marker metadata');
          }
          final globalAyah = raw['ayah'] as int;
          while (surahIndex < surahs.length - 1 &&
              globalAyah >= firstGlobalAyah + surahs[surahIndex].ayahCount) {
            firstGlobalAyah += surahs[surahIndex].ayahCount;
            surahIndex++;
          }
          final markerX = raw['x'];
          final markerY = raw['y'];
          if (markerX is! num || markerY is! num) {
            throw const FormatException('Invalid Ayah marker coordinates');
          }
          return MushafAyahReference(
            globalAyahNumber: globalAyah,
            surahNumber: surahIndex + 1,
            ayahNumber: globalAyah - firstGlobalAyah + 1,
            pageNumber: raw['page'] as int,
            markerX: markerX.toDouble(),
            markerY: markerY.toDouble(),
          );
        })
        .toList(growable: false);

    return MushafMetadata(surahs: surahs, ayahs: ayahs);
  }

  static void _validatePageNumber(int pageNumber) {
    if (pageNumber < 1 || pageNumber > MushafMetadata.totalPages) {
      throw RangeError.range(
        pageNumber,
        1,
        MushafMetadata.totalPages,
        'pageNumber',
      );
    }
  }
}

String _decodeMushafPage(Uint8List compressed) {
  final original = BZip2Decoder().decodeBytes(compressed, verify: true);
  return utf8.decode(original);
}
