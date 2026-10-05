// import 'dart:io' show Platform;

/// Central place for every AdMob ad unit ID used in the app.
///
/// One ID per screen/placement, per platform, as recommended so each
/// location can be tracked and tuned independently in the AdMob console.
///
/// IMPORTANT:
/// - These are Google's public TEST ad unit IDs. Safe to ship in debug
///   builds and safe to click during development.
/// - Replace the values inside `_prod` with your real AdMob ad unit IDs
///   before release. Never hardcode real IDs directly into widgets —
///   always go through this file so swapping test/prod is a one-line change.
class AdUnitIds {
  AdUnitIds._();

  /// Flip this to `true` only in your release build (e.g. via --dart-define).
  static const bool useTestAds = bool.fromEnvironment(
    'USE_TEST_ADS',
    defaultValue: true,
  );

  // ---------------------------------------------------------------------
  // Gallery (Home) screen — Banner
  // ---------------------------------------------------------------------
  static String get galleryBanner =>
      useTestAds ? _testBanner : _prodGalleryBannerAndroid;

  // ---------------------------------------------------------------------
  // Select Image screen — Banner
  // ---------------------------------------------------------------------
  static String get selectImageBanner =>
      useTestAds ? _testBanner : _prodSelectImageBannerAndroid;

  // ---------------------------------------------------------------------
  // Coloring screen exit — Interstitial
  // ---------------------------------------------------------------------
  static String get coloringExitInterstitial =>
      useTestAds ? _testInterstitial : _prodColoringExitInterstitialAndroid;

  // ---------------------------------------------------------------------
  // Unlock image — Rewarded
  // ---------------------------------------------------------------------
  static String get unlockImageRewarded =>
      useTestAds ? _testRewarded : _prodUnlockImageRewardedAndroid;

  // --- Google public TEST IDs (do not change) ---------------------------
  static const String _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  // --- Real production IDs — fill these in from your AdMob console ------
  static const String _prodGalleryBannerAndroid =
      'ca-app-pub-6614542230536812/7336958717';

  static const String _prodSelectImageBannerAndroid =
      'ca-app-pub-6614542230536812/3945498298';

  static const String _prodColoringExitInterstitialAndroid =
      'ca-app-pub-6614542230536812/3944508614';

  static const String _prodUnlockImageRewardedAndroid =
      'ca-app-pub-6614542230536812/9384537553';
}
