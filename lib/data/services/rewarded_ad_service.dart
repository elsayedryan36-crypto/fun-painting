import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fun_painting/data/services/ad_request_config.dart';
import 'package:fun_painting/data/services/ad_unit_ids.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'unlocked_images_store.dart';

/// What happened when a child tapped a locked picture.
enum UnlockResult {
  /// The child watched the whole ad and the picture is unlocked.
  unlocked,

  /// No ad was ready yet. The request is kept, and the ad opens by itself
  /// as soon as it loads (for up to [RewardedAdService.queueLife]).
  queued,

  /// The ad was closed before the reward, or could not be shown.
  notFinished,
}

/// Manages the single rewarded placement in the app: "watch an ad to
/// unlock this image". The image is only unlocked inside
/// `onUserEarnedReward` — never before the ad actually completes.
///
/// Why the old version failed: a tap on a locked card returned at once when
/// no ad was loaded yet, and `RewardedAd.show` returns before the reward is
/// earned, so the card reported a failure even after a full ad.
class RewardedAdService {
  RewardedAdService._();
  static final RewardedAdService instance = RewardedAdService._();

  /// How long a tap waits for the ad to load before it is queued.
  static const Duration waitForAd = Duration(seconds: 10);

  /// How long a queued request stays alive.
  static const Duration queueLife = Duration(seconds: 90);

  /// Pause before trying to load again after a failed load.
  static const Duration retryDelay = Duration(seconds: 5);

  RewardedAd? _ad;
  bool _isLoading = false;
  _QueuedUnlock? _queued;

  void preload() {
    if (_isLoading || _ad != null) return;
    _isLoading = true;
    final started = DateTime.now();
    RewardedAd.load(
      adUnitId: AdUnitIds.unlockImageRewarded,
      request: AdRequestConfig.request(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
          debugPrint(
            'rewarded ad loaded in '
            '${DateTime.now().difference(started).inMilliseconds} ms',
          );
          _showQueuedIfAny();
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _ad = null;
          debugPrint(
            'rewarded ad failed to load: ${error.code} ${error.message}',
          );
          final queued = _queued;
          if (queued != null && !queued.expired) {
            Future<void>.delayed(retryDelay, preload);
          }
        },
      ),
    );
  }

  /// Called when a child taps a locked picture.
  Future<UnlockResult> showToUnlock({
    required String imageId,
    VoidCallback? onUnlocked,
  }) async {
    if (_ad == null) {
      // Keep the request, then wait a little for the ad to arrive.
      final queued = _QueuedUnlock(imageId, onUnlocked);
      _queued = queued;
      queued.waiting = true;
      preload();
      final ready = await _waitForAd(waitForAd);
      queued.waiting = false;
      if (!ready) {
        // Still queued: the ad opens by itself when it is ready.
        return UnlockResult.queued;
      }
      _queued = null;
    }
    _queued = null;
    return _show(imageId: imageId, onUnlocked: onUnlocked);
  }

  Future<bool> _waitForAd(Duration limit) async {
    final deadline = DateTime.now().add(limit);
    while (_ad == null && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return _ad != null;
  }

  void _showQueuedIfAny() {
    final queued = _queued;
    // A tap that is still waiting handles its own ad.
    if (queued == null || queued.waiting) return;
    _queued = null;
    if (queued.expired) return;
    _show(imageId: queued.imageId, onUnlocked: queued.onUnlocked);
  }

  Future<UnlockResult> _show({
    required String imageId,
    VoidCallback? onUnlocked,
  }) {
    final ad = _ad;
    if (ad == null) return Future.value(UnlockResult.notFinished);

    final done = Completer<UnlockResult>();
    var earnedReward = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        if (!done.isCompleted) {
          done.complete(
            earnedReward ? UnlockResult.unlocked : UnlockResult.notFinished,
          );
        }
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _ad = null;
        debugPrint(
          'rewarded ad failed to show: ${error.code} ${error.message}',
        );
        if (!done.isCompleted) done.complete(UnlockResult.notFinished);
        preload();
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) async {
        earnedReward = true;
        await UnlockedImagesStore.instance.unlock(imageId);
        onUnlocked?.call();
      },
    );

    return done.future;
  }
}

class _QueuedUnlock {
  final String imageId;
  final VoidCallback? onUnlocked;
  final DateTime since = DateTime.now();
  bool waiting = false;

  _QueuedUnlock(this.imageId, this.onUnlocked);

  bool get expired =>
      DateTime.now().difference(since) > RewardedAdService.queueLife;
}
