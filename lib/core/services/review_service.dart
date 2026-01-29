import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/invoices/providers/invoices_provider.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService(ref);
});

class ReviewService {
  final Ref _ref;
  final InAppReview _inAppReview = InAppReview.instance;
  static const _reviewKey = 'has_requested_review';
  static const _threshold = 3;

  ReviewService(this._ref);

  /// Monitors milestones to trigger review requests
  void monitorMilestones() {
    _ref.listen(invoicesProvider, (previous, next) async {
      if (next.hasValue) {
        final count = next.value!.length;
        if (count >= _threshold) {
          await _tryRequestReview();
        }
      }
    });
  }

  Future<void> _tryRequestReview() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyRequested = prefs.getBool(_reviewKey) ?? false;

    if (!alreadyRequested) {
      if (await _inAppReview.isAvailable()) {
        // We don't await this as it might take time/be canceled by OS
        _inAppReview.requestReview();
        await prefs.setBool(_reviewKey, true);
      }
    }
  }
}
