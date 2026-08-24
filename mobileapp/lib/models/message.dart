class MessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final int? itemId;
  final String message;
  final bool isRead;
  final String? createdAt;
  final String? senderName;
  final String? receiverName;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.itemId,
    required this.message,
    required this.isRead,
    this.createdAt,
    this.senderName,
    this.receiverName,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id:           _parseInt(json['id']),
      senderId:     _parseInt(json['sender_id']),
      receiverId:   _parseInt(json['receiver_id']),
      itemId:       json['item_id'] != null ? _parseInt(json['item_id']) : null,
      message:      json['message']       as String? ?? '',
      isRead:       json['is_read'] == 1 || json['is_read'] == true,
      createdAt:    json['created_at']    as String?,
      senderName:   json['sender_name']   as String?,
      receiverName: json['receiver_name'] as String?,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

class ConversationModel {
  final int otherUserId;
  final String otherUserName;
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;

  const ConversationModel({
    required this.otherUserId,
    required this.otherUserName,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      otherUserId:   _parseInt(json['other_user_id']),
      otherUserName: json['other_user_name']  as String? ?? 'Unknown',
      lastMessage:   json['last_message']     as String?,
      lastMessageAt: json['last_message_at']  as String?,
      unreadCount:   _parseInt(json['unread_count'] ?? 0),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
