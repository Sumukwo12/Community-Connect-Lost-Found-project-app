import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../models/category.dart';
import '../services/item_service.dart';
import '../services/message_service.dart';

class ItemProvider extends ChangeNotifier {
  // ─── State ────────────────────────────────────────────────────────────────────
  List<ItemModel>    _items          = [];
  List<ItemModel>    _myLostItems    = [];
  List<ItemModel>    _myFoundItems   = [];
  List<ItemModel>    _resolvedItems  = [];
  List<CategoryModel> _categories    = [];
  PaginationModel?   _pagination;

  bool    _loading          = false;
  bool    _loadingMore      = false;
  bool    _submitting       = false;
  String? _error;

  // Home screen data
  List<ItemModel> _recentLost  = [];
  List<ItemModel> _recentFound = [];

  // Getters
  List<ItemModel>     get items          => _items;
  List<ItemModel>     get myLostItems    => _myLostItems;
  List<ItemModel>     get myFoundItems   => _myFoundItems;
  List<ItemModel>     get resolvedItems  => _resolvedItems;
  List<CategoryModel> get categories     => _categories;
  PaginationModel?    get pagination     => _pagination;
  bool                get isLoading      => _loading;
  bool                get isLoadingMore  => _loadingMore;
  bool                get isSubmitting   => _submitting;
  String?             get error          => _error;
  List<ItemModel>     get recentLost     => _recentLost;
  List<ItemModel>     get recentFound    => _recentFound;
  bool                get hasMorePages   => _pagination?.hasNextPage ?? false;

  // ─── Categories ───────────────────────────────────────────────────────────────
  Future<void> loadCategories() async {
    if (_categories.isNotEmpty) return;
    final response = await MessageService.getCategories();
    if (response.success && response.data != null) {
      _categories = (response.data as List)
          .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
          .toList();
      notifyListeners();
    }
  }

  // ─── Home Feed ────────────────────────────────────────────────────────────────
  Future<void> loadHomeFeed() async {
    _loading = true;
    _error   = null;
    notifyListeners();

    final lostFuture  = ItemService.listItems(type: 'lost',  perPage: 5);
    final foundFuture = ItemService.listItems(type: 'found', perPage: 5);

    final results = await Future.wait([lostFuture, foundFuture]);

    if (results[0].success && results[0].data != null) {
      final d       = results[0].data as Map<String, dynamic>;
      _recentLost   = _parseItems(d['items']);
    }
    if (results[1].success && results[1].data != null) {
      final d       = results[1].data as Map<String, dynamic>;
      _recentFound  = _parseItems(d['items']);
    }

    _loading = false;
    notifyListeners();
  }

  // ─── Browse Items ─────────────────────────────────────────────────────────────
  Future<void> loadItems({
    String? type,
    int? categoryId,
    String? search,
    String? location,
    String status = 'active',
    int page    = 1,
    int perPage = 15,
    bool refresh = false,
  }) async {
    if (page == 1) {
      _loading = true;
      if (refresh) _items = [];
    } else {
      _loadingMore = true;
    }
    _error = null;
    notifyListeners();

    final response = await ItemService.listItems(
      type:       type,
      categoryId: categoryId,
      search:     search,
      location:   location,
      status:     status,
      page:       page,
      perPage:    perPage,
    );

    if (response.success && response.data != null) {
      final d    = response.data as Map<String, dynamic>;
      final list = _parseItems(d['items']);
      if (page == 1) {
        _items = list;
      } else {
        _items = [..._items, ...list];
      }
      if (d['pagination'] != null) {
        _pagination = PaginationModel.fromJson(d['pagination'] as Map<String, dynamic>);
      }
    } else {
      _error = response.message;
    }

    _loading     = false;
    _loadingMore = false;
    notifyListeners();
  }

  // ─── My Items ─────────────────────────────────────────────────────────────────
  Future<void> loadMyItems() async {
    _loading = true;
    _error   = null;
    notifyListeners();

    final futures = await Future.wait([
      ItemService.listItems(type: 'lost',  myItems: true, perPage: 50),
      ItemService.listItems(type: 'found', myItems: true, perPage: 50),
      ItemService.listItems(status: 'resolved', myItems: true, perPage: 50),
    ]);

    if (futures[0].success && futures[0].data != null) {
      _myLostItems  = _parseItems((futures[0].data as Map)['items']);
    }
    if (futures[1].success && futures[1].data != null) {
      _myFoundItems = _parseItems((futures[1].data as Map)['items']);
    }
    if (futures[2].success && futures[2].data != null) {
      _resolvedItems = _parseItems((futures[2].data as Map)['items']);
    }

    _loading = false;
    notifyListeners();
  }

  // ─── Create Item ──────────────────────────────────────────────────────────────
  Future<ApiResponse> createItem({
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
    _submitting = true;
    _error      = null;
    notifyListeners();

    final response = await ItemService.createItem(
      type:                  type,
      title:                 title,
      description:           description,
      categoryId:            categoryId,
      location:              location,
      dateOccurred:          dateOccurred,
      timeOccurred:          timeOccurred,
      image:                 image,
      additionalInformation: additionalInformation,
    );

    _submitting = false;
    notifyListeners();
    return response;
  }

  // ─── Delete Item ──────────────────────────────────────────────────────────────
  Future<ApiResponse> deleteItem(int id) async {
    final response = await ItemService.deleteItem(id);
    if (response.success) {
      _myLostItems  = _myLostItems.where((i) => i.id != id).toList();
      _myFoundItems = _myFoundItems.where((i) => i.id != id).toList();
      _items        = _items.where((i) => i.id != id).toList();
      notifyListeners();
    }
    return response;
  }

  // ─── Resolve Item ─────────────────────────────────────────────────────────────
  Future<ApiResponse> resolveItem(int id) async {
    final response = await ItemService.resolveItem(id);
    if (response.success) {
      _myLostItems  = _myLostItems.where((i) => i.id != id).toList();
      _myFoundItems = _myFoundItems.where((i) => i.id != id).toList();
      _items        = _items.where((i) => i.id != id).toList();
      notifyListeners();
    }
    return response;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────
  List<ItemModel> _parseItems(dynamic rawList) {
    if (rawList is! List) return [];
    return rawList.map((e) => ItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  CategoryModel? getCategoryById(int? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

typedef ApiResponse = dynamic;
