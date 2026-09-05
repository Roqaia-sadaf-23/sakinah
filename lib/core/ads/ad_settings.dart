import 'package:google_mobile_ads/google_mobile_ads.dart';

abstract final class AdSettings {
  // Deliberately independent of kReleaseMode: internal releases use test ads.
  static const useProduction = bool.fromEnvironment(
    'ADMOB_USE_PRODUCTION',
    defaultValue: false,
  );

  static const bannerId = useProduction
      ? 'ca-app-pub-1088724215879441/1634011792'
      : 'ca-app-pub-3940256099942544/6300978111';

  static const request = AdRequest(nonPersonalizedAds: true);

  static final configuration = RequestConfiguration(
    maxAdContentRating: MaxAdContentRating.g,
    // Not child-directed. No age is inferred for an individual user.
    // In SDK 9.1 this replaces the deprecated TFCD/TFUA flags.
    ageRestrictedTreatment: AgeRestrictedTreatment.unspecified,
  );
}
