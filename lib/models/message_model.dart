class MessageModel {
  final String id;
  final String requestId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json,
      {String currentUserId = ''}) {
    final sender = json['sender'] as Map<String, dynamic>?;
    return MessageModel(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_id'] == currentUserId
          ? 'You'
          : (sender?['name'] as String? ?? 'Unknown'),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
