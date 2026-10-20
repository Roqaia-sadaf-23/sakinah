import '../entities/mushaf_page.dart';

abstract interface class MushafPageSource {
  Future<MushafMetadata> loadMetadata();

  Future<String> loadPageSvg(int pageNumber);

  void prefetchPage(int pageNumber);
}
