import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RatingService {
  static const _keyActionCount = 'rating_action_count';
  static const _keyCustomPromptShown = 'rating_custom_shown';
  static const _keyRatingCardDismissed = 'rating_card_dismissed';
  static const _keyLastReviewRequestedMs = 'rating_last_requested_ms';
  static const _keyReviewRequestCount = 'rating_request_count';
  static const _appStoreId = '6764657945';

  // Cap native review prompts: max 2 total, at least 60 days apart.
  static const _maxNativeRequests = 2;
  static const _minDaysBetweenRequests = 60;

  // Only trigger the native prompt at these milestone learned-counts.
  static const _milestones = {5, 15, 40};

  /// Called when a phonogram is marked as Learned.
  /// Shows custom love prompt exactly once (first action), then fires
  /// requestReview only at milestone counts (5, 15, 40).
  static Future<void> onPrimaryActionCompleted(BuildContext? context) async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keyActionCount) ?? 0) + 1;
    await prefs.setInt(_keyActionCount, count);

    if (count == 1 && context != null && context.mounted) {
      final shown = prefs.getBool(_keyCustomPromptShown) ?? false;
      if (!shown) {
        await prefs.setBool(_keyCustomPromptShown, true);
        await Future.delayed(const Duration(milliseconds: 800));
        if (context.mounted) {
          await _showCustomRatingPrompt(context);
        }
        return;
      }
    }

    if (_milestones.contains(count)) {
      await _fireRequestReview();
    }
  }

  static Future<void> onQuizCompleted() async => _fireRequestReview();
  static Future<void> onDrillCompleted() async => _fireRequestReview();
  static Future<void> onFlashcardDeckCompleted() async => _fireRequestReview();

  /// Returns true when the rating card should show in the phonograms list.
  static Future<bool> shouldShowRatingCard() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyActionCount) ?? 0;
    final dismissed = prefs.getBool(_keyRatingCardDismissed) ?? false;
    return count >= 2 && !dismissed;
  }

  /// Permanently hides the rating card.
  static Future<void> dismissRatingCard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRatingCardDismissed, true);
  }

  /// Opens the App Store listing directly — not throttled by Apple.
  static Future<void> openAppStoreListing() async {
    final inAppReview = InAppReview.instance;
    await inAppReview.openStoreListing(appStoreId: _appStoreId);
  }

  static Future<void> _fireRequestReview() async {
    final prefs = await SharedPreferences.getInstance();

    final requestCount = prefs.getInt(_keyReviewRequestCount) ?? 0;
    if (requestCount >= _maxNativeRequests) return;

    final lastMs = prefs.getInt(_keyLastReviewRequestedMs) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (lastMs > 0) {
      final daysSinceLast = (now - lastMs) / (1000 * 60 * 60 * 24);
      if (daysSinceLast < _minDaysBetweenRequests) return;
    }

    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
      await prefs.setInt(_keyLastReviewRequestedMs, now);
      await prefs.setInt(_keyReviewRequestCount, requestCount + 1);
    }
  }

  static Future<void> _showCustomRatingPrompt(BuildContext context) async {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;
    final hPad = isWide ? 40.0 : 24.0;
    final iconSize = isWide ? 80.0 : 64.0;
    final iconInner = isWide ? 40.0 : 32.0;
    final titleSize = isWide ? 24.0 : 20.0;
    final bodySize = isWide ? 16.0 : 14.0;
    final starSize = isWide ? 40.0 : 32.0;
    final btnHeight = isWide ? 56.0 : 52.0;
    final btnFontSize = isWide ? 18.0 : 16.0;

    await showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxWidth: isWide ? 520 : double.infinity),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite,
                color: theme.colorScheme.primary,
                size: iconInner,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You learned your first phonogram!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'If Phonograms is helping you teach, a quick rating helps other educators find us too.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: bodySize,
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            // Decorative stars — NOT interactive (Apple compliance)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (_) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(Icons.star_rounded,
                      color: Colors.amber, size: starSize),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: btnHeight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  openAppStoreListing();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Rate Us',
                  style: TextStyle(
                      fontSize: btnFontSize, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Not Now',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: bodySize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
