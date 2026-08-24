import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/message_service.dart';
import '../services/api_service.dart';

class MessageProvider extends ChangeNotifier {
  List<ConversationModel> _conversations = [];
  List<MessageModel>      _messages      = [];
  bool    _loading    = false;
  bool    _sending    = false;
  String? _error;

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel>      get messages      => _messages;
  bool                    get isLoading     => _loading;
  bool                    get isSending     => _sending;
  String?                 get error         => _error;

  int get totalUnread => _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  Future<void> loadConversations() async {
    _loading = true;
    _error   = null;
    notifyListeners();

    final response = await MessageService.getConversations();
    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final list = data['conversations'] as List? ?? [];
      _conversations = list.map((c) => ConversationModel.fromJson(c as Map<String, dynamic>)).toList();
    } else {
      _error = response.message;
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> loadConversation({required int withUserId, int? itemId}) async {
    _loading  = true;
    _messages = [];
    _error    = null;
    notifyListeners();

    final response = await MessageService.getConversation(withUserId: withUserId, itemId: itemId);
    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final list = data['messages'] as List? ?? [];
      _messages  = list.map((m) => MessageModel.fromJson(m as Map<String, dynamic>)).toList();
    } else {
      _error = response.message;
    }

    _loading = false;
    notifyListeners();
  }

  Future<ApiResponse> sendMessage({
    required int receiverId,
    required String message,
    int? itemId,
  }) async {
    _sending = true;
    _error   = null;
    notifyListeners();

    final response = await MessageService.sendMessage(
      receiverId: receiverId,
      message:    message,
      itemId:     itemId,
    );

    if (response.success && response.data != null) {
      final msg = MessageModel.fromJson(response.data as Map<String, dynamic>);
      _messages = [..._messages, msg];
    } else {
      _error = response.message;
    }

    _sending = false;
    notifyListeners();
    return response;
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

typedef ApiResponse = dynamic;
