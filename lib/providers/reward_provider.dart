import 'package:flutter/material.dart';
import '../models/reward_model.dart';
import '../services/reward_service.dart';
import '../services/supabase_service.dart';

class RewardProvider extends ChangeNotifier {
  List<RewardModel> _rewards = [];
  bool _loading = false;
  String? _error;

  List<RewardModel> get rewards => _rewards;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadData() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _rewards = await RewardService.fetchRewards(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Redeem a reward. Returns true on success, false if insufficient points.
  Future<bool> redeemReward(RewardModel reward) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return false;

    try {
      await RewardService.redeemReward(userId, reward);

      // Mark as redeemed in local state
      final index = _rewards.indexWhere((r) => r.id == reward.id);
      if (index != -1) {
        _rewards[index] = _rewards[index].copyWith(isRedeemed: true);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
