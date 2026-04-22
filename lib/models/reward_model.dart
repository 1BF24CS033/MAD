class RewardModel {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String iconName;
  final bool isRedeemed;

  RewardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    this.iconName = 'card_giftcard',
    this.isRedeemed = false,
  });
}
