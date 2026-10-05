import 'package:fun_painting/data/services/ad_request_config.dart';
import 'package:fun_painting/data/services/ad_unit_ids.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the single interstitial placement in the app: shown when a
/// child finishes/exits a coloring page.
///
/// Capping rules (kid-safe, tune as needed):
/// - Never shown after the very first completion of a session.
/// - Shown at most once every [_minCompletionsBetweenAds] completions.
/// - Preloads the next ad immediately after one is dismissed.
class InterstitialAdService {
  InterstitialAdService._();
  static final InterstitialAdService instance = InterstitialAdService._();

  static const _minCompletionsBetweenAds = 3;
  static const _completionCountKey = 'coloring_completion_count';

  InterstitialAd? _ad;
  bool _isLoading = false;

  /// Call this early (e.g. app start, or right after the first coloring
  /// screen opens) so an ad is ready by the time it's needed.
  void preload() {
    if (_isLoading || _ad != null) return;
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: AdUnitIds.coloringExitInterstitial,
      request: AdRequestConfig.request(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _ad = null;
        },
      ),
    );
  }

  /// Call this when the user finishes or exits a coloring page.
  /// Handles the completion counter and decides whether to show.
  Future<void> maybeShowOnColoringExit() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_completionCountKey) ?? 0) + 1;
    await prefs.setInt(_completionCountKey, count);

    final shouldShow = count > 1 && count % _minCompletionsBetweenAds == 0;
    if (!shouldShow) return;

    _show();
  }

  void _show() {
    final ad = _ad;
    if (ad == null) {
      // Not ready — silently skip rather than block the user.
      preload();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _ad = null;
        preload();
      },
    );

    ad.show();
    _ad = null;
  }
}
