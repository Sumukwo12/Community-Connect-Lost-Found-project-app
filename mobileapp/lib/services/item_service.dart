import 'dart:io';
import '../config/api_config.dart';
import 'api_service.dart';

class ItemService {
  ItemService._();

  static Future<ApiResponse> listItems({
    String? type,
    int? categoryId,
    String? location,
    String? search,
    String status = 'active',
    bool myItems   = false,
    String? dateFrom,
    String? dateTo,
    int page    = 1,
    int perPage = 15,
  }) async {
    final params = <String, String>{
      'status':   status,
      'page':     page.toString(),
      'per_page': perPage.toString(),
      if (type       != null)  'type':        type,
      if (categoryId != null)  'category_id': categoryId.toString(),
      if (location   != null && location.isNotEmpty) 'location': location,
      if (search     != null && search.isNotEmpty)   'search':   search,
      if (myItems)                                    'my_items': '1',
      if (dateFrom   != null)  'date_from':   dateFrom,
      if (dateTo     != null)  'date_to':     dateTo,
    };
    return ApiService.get(ApiConfig.itemList, queryParams: params, requiresAuth: myItems);
  }

  static Future<ApiResponse> getItem(int id) async {
    return ApiService.get(ApiConfig.itemGet, queryParams: {'id': id.toString()}, requiresAuth: false);
  }

  static Future<ApiResponse> createItem({
    required String type,
    required String title,
    required String description,
    int? categoryId,
    required String location,
    required String dateOccurred,
    String? timeOccurred,
    File? image,
    String? additionalInformation,
  }) async {
    final fields = <String, String>{
      'type':        type,
      'title':       title,
      'description': description,
      'location':    location,
      'date_occurred': dateOccurred,
      if (categoryId != null)           'category_id':             categoryId.toString(),
      if (timeOccurred != null)         'time_occurred':            timeOccurred,
      if (additionalInformation != null) 'additional_information': additionalInformation,
    };
    return ApiService.postMultipart(ApiConfig.itemCreate, fields: fields, imageFile: image);
  }

  static Future<ApiResponse> updateItem({
    required int id,
    String? type,
    String? title,
    String? description,
    int? categoryId,
    String? location,
    String? dateOccurred,
    String? timeOccurred,
    File? image,
    String? additionalInformation,
  }) async {
    final fields = <String, String>{
      'id': id.toString(),
      if (type        != null) 'type':                   type,
      if (title       != null) 'title':                  title,
      if (description != null) 'description':             description,
      if (categoryId  != null) 'category_id':             categoryId.toString(),
      if (location    != null) 'location':               location,
      if (dateOccurred != null) 'date_occurred':          dateOccurred,
      if (timeOccurred != null) 'time_occurred':          timeOccurred,
      if (additionalInformation != null) 'additional_information': additionalInformation,
    };
    return ApiService.postMultipart(ApiConfig.itemUpdate, fields: fields, imageFile: image);
  }

  static Future<ApiResponse> deleteItem(int id) async {
    return ApiService.post(ApiConfig.itemDelete, body: {'id': id});
  }

  static Future<ApiResponse> resolveItem(int id) async {
    return ApiService.post(ApiConfig.itemResolve, body: {'id': id});
  }
}
