import 'package:fun_painting/data/services/ad_request_config.dart';
import 'package:fun_painting/data/services/ad_unit_ids.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'unlocked_images_store.dart';

/// Manages the single rewarded placement in the app: "watch an ad to
/// unlock this image". The image is only unlocked inside
/// `onUserEarnedReward` — never before the ad actually completes.
class RewardedAdService {
  RewardedAdService._();
  static final RewardedAdService instance = RewardedAdService._();

  RewardedAd? _ad;
  bool _isLoading = false;

  void preload() {
    if (_isLoading || _ad != null) return;
    _isLoading = true;
    RewardedAd.load(
      adUnitId: AdUnitIds.unlockImageRewarded,
      request: AdRequestConfig.request(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
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

  /// Returns true if the ad was shown and the image unlocked, false if
  /// no ad was ready (caller should show a "try again" state).
  Future<bool> showToUnlock({
    required String imageId,
    VoidCallback? onUnlocked,
  }) async {
    final ad = _ad;
    if (ad == null) {
      preload();
      return false;
    }

    var earnedReward = false;

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

    await ad.show(
      onUserEarnedReward: (ad, reward) async {
        earnedReward = true;
        await UnlockedImagesStore.instance.unlock(imageId);
        onUnlocked?.call();
      },
    );

    _ad = null;
    return earnedReward;
  }
}

typedef VoidCallback = void Function();
