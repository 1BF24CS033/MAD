import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reward_model.dart';
import 'supabase_service.dart';

class RewardService {
  static SupabaseClient get _db => SupabaseService.client;

  /// Fetch all active rewards and mark which ones the current user has redeemed.
  static Future<List<RewardModel>> fetchRewards(String userId) async {
    // Fetch all active rewards
    final rewardRows = await _db
        .from('rewards')
        .select()
        .eq('is_active', true)
        .order('points_cost');

    // Fetch this user's redemptions
    final redemptionRows = await _db
        .from('reward_redemptions')
        .select('reward_id')
        .eq('user_id', userId);

    final redeemedIds = redemptionRows
        .cast<Map<String, dynamic>>()
        .map((r) => r['reward_id'] as String)
        .toSet();

    return rewardRows
        .cast<Map<String, dynamic>>()
        .map((r) => RewardModel.fromJson(
              r,
              isRedeemed: redeemedIds.contains(r['id'] as String),
            ))
        .toList();
  }

  /// Redeem a reward for [userId].
  /// Deducts points from the profile and records the redemption.
  /// Throws if the user cannot afford the reward.
  static Future<void> redeemReward(
      String userId, RewardModel reward) async {
    await _db.rpc('redeem_reward', params: {
      'p_user_id': userId,
      'p_reward_id': reward.id,
      'p_points_cost': reward.pointsCost,
    });
  }
}
