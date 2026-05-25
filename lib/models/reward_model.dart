class RewardModel {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String iconName;
  final bool isRedeemed; // true when the current user has redeemed this reward

  RewardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    this.iconName = 'card_giftcard',
    this.isRedeemed = false,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json,
      {bool isRedeemed = false}) {
    return RewardModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      pointsCost: json['points_cost'] as int,
      iconName: json['icon_name'] as String? ?? 'card_giftcard',
      isRedeemed: isRedeemed,
    );
  }

  RewardModel copyWith({bool? isRedeemed}) => RewardModel(
        id: id,
        title: title,
        description: description,
        pointsCost: pointsCost,
        iconName: iconName,
        isRedeemed: isRedeemed ?? this.isRedeemed,
      );
}
