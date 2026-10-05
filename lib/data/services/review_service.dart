import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../app/app_pref.dart';

class ReviewService {
  ReviewService._();

  static final ReviewService instance = ReviewService._();

  final InAppReview _inAppReview = InAppReview.instance;

  /// Register one app opening.
  ///
  /// The review request is attempted every 5 opens:
  /// 5, 10, 15, 20, ...
  Future<void> registerAppOpen() async {
    try {
      final appPreferences = AppPreferences();

      int count = appPreferences.getKOpenCount();

      count++;

      await appPreferences.setKOpenCount(count);

      debugPrint('App opened: $count times');

      // Try to request a review every 5 opens.
      if (count > 0 && count % 5 == 0) {
        await requestReview();
      }
    } catch (e, stackTrace) {
      debugPrint('ReviewService.registerAppOpen error: $e');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Request the native in-app review dialog.
  ///
  /// Google Play / App Store decides whether the dialog
  /// will actually be displayed.
  Future<bool> requestReview() async {
    try {
      final available = await _inAppReview.isAvailable();

      if (!available) {
        debugPrint('In-app review is not available.');
        return false;
      }

      await _inAppReview.requestReview();

      debugPrint('In-app review request sent.');

      return true;
    } catch (e, stackTrace) {
      debugPrint('ReviewService.requestReview error: $e');

      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }

  /// Opens the application's store listing.
  ///
  /// Use this from the Info page when the user taps
  /// "Rate Fun Painting".
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing();

      debugPrint('Store listing opened.');
    } catch (e, stackTrace) {
      debugPrint('ReviewService.openStoreListing error: $e');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Returns the current number of app opens.
  int getOpenCount() {
    return AppPreferences().getKOpenCount();
  }
}
