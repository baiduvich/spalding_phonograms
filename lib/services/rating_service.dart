import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RatingService {
  static const _keyActionCount = 'rating_action_count';
  static const _keyCustomPromptShown = 'rating_custom_shown';
  static const _keyRatingCardDismissed = 'rating_card_dismissed';
  static const _appStoreId = '6764657945';

  /// Called when a phonogram is marked as Learned.
  /// Shows custom love prompt on first action, fires requestReview on subsequent.
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

    await _fireRequestReview();
  }

  /// Called on HomeScreen init. Fires requestReview if user has completed at least one action.
  static Future<void> onAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyActionCount) ?? 0;
    if (count >= 1) {
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
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
  }

  static Future<void> _showCustomRatingPrompt(BuildContext context) async {
    final theme = Theme.of(context);

    await showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite,
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You learned your first phonogram!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'If Phonograms is helping you teach, a quick rating helps other educators find us too.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
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
                (_) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(Icons.star_rounded, color: Colors.amber, size: 32),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
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
                child: const Text(
                  'Rate Us',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
