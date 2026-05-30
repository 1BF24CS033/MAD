class ReminderModel {
  final String id;
  final String userId;
  final String? requestId;
  final String title;
  final String body;
  final DateTime remindAt;
  final bool isSent;
  final DateTime createdAt;

  ReminderModel({
    required this.id,
    required this.userId,
    this.requestId,
    required this.title,
    this.body = '',
    required this.remindAt,
    this.isSent = false,
    required this.createdAt,
  });

  bool get isDue => !isSent && remindAt.isBefore(DateTime.now());
  bool get isUpcoming =>
      !isSent && remindAt.isAfter(DateTime.now());

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      requestId: json['request_id'] as String?,
      title: json['title'] as String,
      body: json['body'] as String? ?? '',
      remindAt: DateTime.parse(json['remind_at'] as String).toLocal(),
      isSent: json['is_sent'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        if (requestId != null) 'request_id': requestId,
        'title': title,
        'body': body,
        'remind_at': remindAt.toUtc().toIso8601String(),
        'is_sent': isSent,
      };
}
