import '../config/api_config.dart';
import 'api_service.dart';

class MessageService {
  MessageService._();

  static Future<ApiResponse> sendMessage({
    required int receiverId,
    required String message,
    int? itemId,
  }) async {
    return ApiService.post(
      ApiConfig.messageSend,
      body: {
        'receiver_id': receiverId,
        'message':     message,
        if (itemId != null) 'item_id': itemId,
      },
    );
  }

  static Future<ApiResponse> getConversations({int page = 1}) async {
    return ApiService.get(
      ApiConfig.messageList,
      queryParams: {'page': page.toString()},
    );
  }

  static Future<ApiResponse> getConversation({
    required int withUserId,
    int? itemId,
    int page = 1,
  }) async {
    return ApiService.get(
      ApiConfig.messageList,
      queryParams: {
        'conversation_with': withUserId.toString(),
        'page':              page.toString(),
        if (itemId != null) 'item_id': itemId.toString(),
      },
    );
  }

  static Future<ApiResponse> reportItem({
    required int itemId,
    required String reason,
  }) async {
    return ApiService.post(
      ApiConfig.reportCreate,
      body: {'item_id': itemId, 'reason': reason},
    );
  }

  static Future<ApiResponse> getCategories() async {
    return ApiService.get(ApiConfig.categoryList, requiresAuth: false);
  }
}
